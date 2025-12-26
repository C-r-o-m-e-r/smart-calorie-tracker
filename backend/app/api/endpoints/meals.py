# backend/app/api/endpoints/meals.py
# FINAL VERSION: Uploads, CRUD, Analytics, AI Checks, and Rate Limiting

import shutil
import os
import uuid
from datetime import date, datetime, timedelta
from typing import List, Any, Optional

from fastapi import APIRouter, Depends, HTTPException, Body, UploadFile, File, status, Query, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func

# --- Rate Limiting Imports ---
from slowapi import Limiter
from slowapi.util import get_remote_address

from app.api import deps
from app.models.meal import Meal
from app.models.user import User
from app.schemas.meal import MealCreate, Meal as MealSchema, MealUpdate
from app.services.openai_service import analyze_food_image

router = APIRouter()

# Setup Limiter (Local instance for this router)
limiter = Limiter(key_func=get_remote_address)

UPLOAD_DIR = "app/static/uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# --- Feature #14: Daily Summary ---
@router.get("/summary")
async def get_daily_summary(
    date_query: date = Query(default_factory=date.today),
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user)
):
    """Returns calculated totals for a specific date (Progress Ring)."""
    result = await db.execute(
        select(Meal)
        .where(
            Meal.user_id == current_user.id,
            func.date(Meal.created_at) == date_query
        )
    )
    meals = result.scalars().all()

    total_calories = sum(m.calories for m in meals)
    total_protein = sum(m.protein for m in meals)
    total_fats = sum(m.fats for m in meals)
    total_carbs = sum(m.carbs for m in meals)

    goal = current_user.calories_goal or 2000
    remaining = goal - total_calories

    return {
        "date": date_query,
        "total_calories": total_calories,
        "goal_calories": goal,
        "remaining_calories": remaining,
        "total_protein": round(total_protein, 1),
        "total_fats": round(total_fats, 1),
        "total_carbs": round(total_carbs, 1),
        "meal_count": len(meals)
    }

# --- Feature #15: Weekly Statistics (Graph) ---
@router.get("/weekly-stats")
async def get_weekly_stats(
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user)
):
    """
    Returns calories for the last 7 days.
    """
    today = date.today()
    start_date = today - timedelta(days=6) # 7 days window

    # Get all meals in range
    result = await db.execute(
        select(Meal)
        .where(
            Meal.user_id == current_user.id,
            func.date(Meal.created_at) >= start_date
        )
    )
    meals = result.scalars().all()

    # Aggregate by date
    stats = { (start_date + timedelta(days=i)): 0 for i in range(7) }

    for meal in meals:
        meal_date = meal.created_at.date()
        if meal_date in stats:
            stats[meal_date] += meal.calories

    # Convert to list
    response_data = [
        {"date": day, "total_calories": cal} 
        for day, cal in stats.items()
    ]
    response_data.sort(key=lambda x: x["date"])
    
    return response_data

# --- Feature #17: AI Analysis with Rate Limiting ---
@router.post("/analyze")
@limiter.limit("5/minute") # <--- LIMIT: Max 5 photos per minute per IP
async def analyze_meal(
    request: Request, # <--- Required for Limiter
    file: UploadFile = File(...),
    current_user: User = Depends(deps.get_current_user)
):
    """
    Analyze image using OpenAI.
    Protected by Rate Limiter to save money.
    """
    file_extension = file.filename.split(".")[-1]
    filename = f"{uuid.uuid4()}.{file_extension}"
    file_path = os.path.join(UPLOAD_DIR, filename)
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    relative_url = f"/static/uploads/{filename}"

    try:
        analysis_result = await analyze_food_image(file_path)
    except Exception as e:
        if os.path.exists(file_path):
            os.remove(file_path)
        print(f"AI Error: {e}")
        raise HTTPException(status_code=500, detail="AI analysis failed")

    if not analysis_result:
        if os.path.exists(file_path):
            os.remove(file_path)
        raise HTTPException(status_code=500, detail="AI returned empty result")

    # --- Feature #16: Check if it is food ---
    is_food = analysis_result.get("is_food", True)
    if is_food is False:
        if os.path.exists(file_path):
            os.remove(file_path)
        raise HTTPException(
            status_code=400, 
            detail="AI did not detect food in this image. Please try again."
        )
    # ----------------------------------------

    analysis_result["image_url"] = relative_url
    return analysis_result


@router.post("/", response_model=MealSchema)
async def create_meal(
    meal: MealCreate, 
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user)
):
    db_meal = Meal(**meal.model_dump(), user_id=current_user.id)
    db.add(db_meal)
    await db.commit()
    await db.refresh(db_meal)
    return db_meal

@router.get("/", response_model=List[MealSchema])
async def read_meals(
    skip: int = 0, 
    limit: int = 100,
    filter_date: Optional[date] = None, 
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user)
):
    """Get history with optional date filter."""
    query = select(Meal).where(Meal.user_id == current_user.id)
    
    if filter_date:
        query = query.where(func.date(Meal.created_at) == filter_date)
        
    query = query.order_by(Meal.created_at.desc()).offset(skip).limit(limit)
    
    result = await db.execute(query)
    return result.scalars().all()

@router.put("/{meal_id}", response_model=MealSchema)
async def update_meal(
    meal_id: int,
    meal_in: MealUpdate,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user)
):
    result = await db.execute(select(Meal).where(Meal.id == meal_id, Meal.user_id == current_user.id))
    meal = result.scalars().first()
    
    if not meal:
        raise HTTPException(status_code=404, detail="Meal not found")
        
    update_data = meal_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(meal, field, value)
        
    db.add(meal)
    await db.commit()
    await db.refresh(meal)
    return meal

@router.delete("/{meal_id}")
async def delete_meal(
    meal_id: int,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user)
):
    result = await db.execute(select(Meal).where(Meal.id == meal_id, Meal.user_id == current_user.id))
    meal = result.scalars().first()
    
    if not meal:
        raise HTTPException(status_code=404, detail="Meal not found")
        
    await db.delete(meal)
    await db.commit()
    return {"ok": True}