# backend/app/schemas/meal.py
from pydantic import BaseModel, ConfigDict
from typing import Optional, List
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

    model_config = ConfigDict(from_attributes=True)

# --- NEW: Pagination Wrapper ---
class MealPagination(BaseModel):
    items: List[Meal]
    total: int
    page: int
    size: int
    pages: int

# --- NEW: AI Analysis Response ---
class FoodAnalysisResponse(BaseModel):
    name: str
    calories: int
    protein: float
    fats: float
    carbs: float
    weight_grams: int
    is_food: bool
    image_url: str
    confidence: Optional[float] = None