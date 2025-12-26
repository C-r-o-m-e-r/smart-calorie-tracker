# backend/app/schemas/meal.py
# matching the new db structure with floats and singular protein

from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class MealBase(BaseModel):
    name: str
    calories: int
    protein: float  # <-- Changed from proteins: int
    fats: float     # <-- Changed to float
    carbs: float    # <-- Changed to float
    weight_grams: Optional[float] = None  # <-- Added new field
    image_url: Optional[str] = None

class MealCreate(MealBase):
    pass

class Meal(MealBase):
    id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True