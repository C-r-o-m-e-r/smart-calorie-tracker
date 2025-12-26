# backend/app/schemas/meal.py

from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class MealBase(BaseModel):
    name: str
    calories: int
    protein: float = 0
    fats: float = 0
    carbs: float = 0
    weight_grams: float = 0
    image_url: Optional[str] = None

class MealCreate(MealBase):
    pass

# ОНОВЛЕНО: Всі поля опціональні, щоб можна було змінити, наприклад, тільки вагу
class MealUpdate(BaseModel):
    name: Optional[str] = None
    calories: Optional[int] = None
    protein: Optional[float] = None
    fats: Optional[float] = None
    carbs: Optional[float] = None
    weight_grams: Optional[float] = None
    image_url: Optional[str] = None

class Meal(MealBase):
    id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True