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

class MealUpdate(MealBase):
    pass
    # just inheriting base since all fields can be updated i guess

class Meal(MealBase):
    id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True
        # used to be orm_mode helps converting sqlalchemy objects to json