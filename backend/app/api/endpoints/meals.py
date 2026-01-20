# backend/app/api/endpoints/meals.py
import shutil
import os
import uuid
import math
from datetime import date, datetime, timedelta
from typing import List, Any, Optional

from fastapi import APIRouter, Depends, HTTPException, Body, UploadFile, File, status, Query, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func

# rate limiting imports
from slowapi import Limiter
from slowapi.util import get_remote_address

from app.api import deps
from app.models.meal import Meal
from app.models.user import User
from app.schemas.meal import (
    MealCreate, 
    Meal as MealSchema, 
    MealUpdate, 
    MealPagination, 
    FoodAnalysisResponse
)
from app.services.openai_service import analyze_food_image

router = APIRouter()

# setup limiter
limiter = Limiter(key_func=get_remote_address)

UPLOAD_DIR = "app/static/uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# helper to build absolute url
def get_absolute_url(request: Request, relative_path: str) -> str:
    if not relative_path:
        return None
    base_url = str(request.base_url).rstrip("/")
    if relative_path.startswith("/"):
        return f"{base_url}{relative_path}"
    return f"{base_url}/{relative_path}"

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
    today = date.today()
    start_date = today - timedelta(days=6)

    result = await db.execute(
        select(Meal)
        .where(
            Meal.user_id == current_user.id,
            func.date(Meal.created_at) >= start_date
        )
    )
    meals = result.scalars().all()

    stats = { (start_date + timedelta(days=i)): 0 for i in range(7) }

    for meal in meals:
        meal_date = meal.created_at.date()
        if meal_date in stats:
            stats[meal_date] += meal.calories

    response_data = [
        {"date": day, "total_calories": cal} 
        for day, cal in stats.items()
    ]
    response_data.sort(key=lambda x: x["date"])
    
    return response_data

# --- Feature #17: AI Analysis with Rate Limiting ---
@router.post("/analyze", response_model=FoodAnalysisResponse)
@limiter.limit("5/minute")
async def analyze_meal(
    request: Request,
    file: UploadFile = File(...),
    current_user: User = Depends(deps.get_current_user)
):
    file_extension = file.filename.split(".")[-1]
    filename = f"{uuid.uuid4()}.{file_extension}"
    file_path = os.path.join(UPLOAD_DIR, filename)
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    relative_path = f"/static/uploads/{filename}"
    absolute_url = get_absolute_url(request, relative_path)

    try:
        # calling ai service
        # if this fails, we catch it below
        analysis_result = await analyze_food_image(file_path)
        
        if not analysis_result:
             raise ValueError("ai returned empty result")

        # check food flag
        is_food = analysis_result.get("is_food", True)
        if is_food is False:
            if os.path.exists(file_path):
                os.remove(file_path)
            raise HTTPException(
                status_code=400, 
                detail="ai did not detect food"
            )

        return {
            "name": analysis_result.get("name", "Unknown Food"),
            "calories": analysis_result.get("calories", 0),
            "protein": analysis_result.get("protein", 0),
            "fats": analysis_result.get("fats", 0),
            "carbs": analysis_result.get("carbs", 0),
            "weight_grams": analysis_result.get("weight_grams", 0),
            "is_food": True,
            "image_url": absolute_url,
            "confidence": 1.0
        }

    except Exception as e:
        # here we return the REAL error from openai
        if os.path.exists(file_path):
            os.remove(file_path)
        print(f"ai error: {e}")
        raise HTTPException(status_code=500, detail=f"ai analysis failed: {str(e)}")


@router.post("/", response_model=MealSchema)
async def create_meal(
    request: Request,
    meal: MealCreate, 
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user)
):
    db_meal = Meal(**meal.model_dump(), user_id=current_user.id)
    db.add(db_meal)
    await db.commit()
    await db.refresh(db_meal)
    
    if db_meal.image_url:
        db_meal.image_url = get_absolute_url(request, db_meal.image_url)
        
    return db_meal

# --- UPDATED: Pagination Support ---
@router.get("/", response_model=MealPagination)
async def read_meals(
    request: Request,
    page: int = 1,
    size: int = 20,
    filter_date: Optional[date] = None, 
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user)
):
    skip = (page - 1) * size
    
    query = select(Meal).where(Meal.user_id == current_user.id)
    if filter_date:
        query = query.where(func.date(Meal.created_at) == filter_date)
    
    count_query = select(func.count()).select_from(query.subquery())
    total_result = await db.execute(count_query)
    total_items = total_result.scalar_one()

    query = query.order_by(Meal.created_at.desc()).offset(skip).limit(size)
    result = await db.execute(query)
    meals = result.scalars().all()
    
    for m in meals:
        if m.image_url:
            m.image_url = get_absolute_url(request, m.image_url)

    total_pages = math.ceil(total_items / size) if size > 0 else 0

    return {
        "items": meals,
        "total": total_items,
        "page": page,
        "size": size,
        "pages": total_pages
    }

@router.put("/{meal_id}", response_model=MealSchema)
async def update_meal(
    request: Request,
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
    
    if meal.image_url:
        meal.image_url = get_absolute_url(request, meal.image_url)
        
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