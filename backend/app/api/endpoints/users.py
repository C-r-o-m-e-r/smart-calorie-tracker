# backend/app/api/endpoints/users.py
# handling registration, profile, deletion, password AND auto-calculation of calories

from typing import Any
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.api import deps
from app.core import security
from app.models.user import User
# Додали UserUpdate в імпорт (його ми створимо на наступному кроці)
from app.schemas.user import UserCreate, User as UserSchema, UserUpdatePassword, UserUpdate
from app.schemas.msg import Msg

router = APIRouter()

# --- HELPER: Auto-calculate calories ---
def calculate_target_calories(user: User) -> int:
    """
    Calculates BMR using Mifflin-St Jeor Equation and multiplies by activity level.
    """
    if not user.weight or not user.height or not user.age or not user.gender:
        return 2000 # Default if data is missing

    # 1. Calculate BMR (Basal Metabolic Rate)
    # Formula: (10 × weight in kg) + (6.25 × height in cm) - (5 × age in years) + s
    # s is +5 for males and -161 for females
    bmr = (10 * user.weight) + (6.25 * user.height) - (5 * user.age)
    
    if user.gender.lower() == "male":
        bmr += 5
    else:
        bmr -= 161

    # 2. Activity Multiplier
    multipliers = {
        "sedentary": 1.2,      # Little or no exercise
        "light": 1.375,        # Light exercise 1-3 days/week
        "moderate": 1.55,      # Moderate exercise 3-5 days/week
        "active": 1.725,       # Hard exercise 6-7 days/week
        "very_active": 1.9     # Very hard exercise & physical job
    }
    
    # Default to sedentary if not specified or typo
    activity = user.activity_level.lower() if user.activity_level else "sedentary"
    multiplier = multipliers.get(activity, 1.2)

    tdee = bmr * multiplier
    
    # Returns TDEE. Alternatively, create a deficit for weight loss here (e.g., -500)
    # For now, we return maintenance calories.
    return int(tdee)


# --- ENDPOINTS ---

@router.post("/", response_model=UserSchema)
async def create_user(
    user_in: UserCreate,
    db: AsyncSession = Depends(deps.get_db)
) -> Any:
    """Create new user (Register)."""
    result = await db.execute(select(User).where(User.email == user_in.email))
    if result.scalars().first():
        raise HTTPException(status_code=400, detail="Email already registered")

    hashed_password = security.get_password_hash(user_in.password)

    new_user = User(
        email=user_in.email, 
        hashed_password=hashed_password
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    return new_user

@router.get("/me", response_model=UserSchema)
async def read_user_me(
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """Get current user profile."""
    return current_user

# --- NEW: Update Profile (Patch) ---
@router.patch("/me", response_model=UserSchema)
async def update_user_me(
    user_in: UserUpdate,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Update profile fields (weight, height, age, etc).
    Automatically recalculates daily calorie goal.
    """
    update_data = user_in.model_dump(exclude_unset=True)

    # 1. Update fields
    for field, value in update_data.items():
        setattr(current_user, field, value)

    # 2. Auto-calculate calories if physiology data changed
    if any(k in update_data for k in ["weight", "height", "age", "gender", "activity_level"]):
        new_goal = calculate_target_calories(current_user)
        current_user.calories_goal = new_goal

    db.add(current_user)
    await db.commit()
    await db.refresh(current_user)
    return current_user

@router.delete("/me", response_model=UserSchema)
async def delete_user_me(
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """Delete own account."""
    await db.delete(current_user)
    await db.commit()
    return current_user

@router.post("/me/password", response_model=Msg)
async def update_password_me(
    body: UserUpdatePassword,
    db: AsyncSession = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """Update own password."""
    if not security.verify_password(body.current_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Incorrect password")

    current_user.hashed_password = security.get_password_hash(body.new_password)
    db.add(current_user)
    await db.commit()
    return {"msg": "Password updated successfully"}