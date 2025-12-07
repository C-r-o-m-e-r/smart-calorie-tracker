# backend/app/api/endpoints/meals.py
# adding ai endpoint so users can lazy scan their food

from typing import List
from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.db.session import SessionLocal
from app.models.meal import Meal
from app.schemas.meal import MealCreate, Meal as MealSchema
from app.services.openai_service import analyze_food_image

router = APIRouter()

async def get_db():
    async with SessionLocal() as session:
        yield session

@router.post("/analyze")
async def analyze_meal(image_url: str = Body(..., embed=True)):
    # calling the ai service defined earlier
    result = await analyze_food_image(image_url)
    if not result:
        raise HTTPException(status_code=500, detail="AI analysis failed")
    return result

@router.post("/", response_model=MealSchema)
async def create_meal(meal: MealCreate, db: AsyncSession = Depends(get_db)):
    # hardcoding user_id to 1 until we implement jwt auth module
    db_meal = Meal(**meal.model_dump(), user_id=1)
    db.add(db_meal)
    await db.commit()
    await db.refresh(db_meal)
    return db_meal

@router.get("/", response_model=List[MealSchema])
async def read_meals(skip: int = 0, limit: int = 100, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Meal).offset(skip).limit(limit))
    return result.scalars().all()