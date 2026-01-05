# backend/app/schemas/user.py
# FINAL VERSION: Added NewPassword schema for reset flow

from typing import Optional
from pydantic import BaseModel, EmailStr, ConfigDict

# Shared properties
class UserBase(BaseModel):
    email: Optional[EmailStr] = None
    full_name: Optional[str] = None
    age: Optional[int] = None
    weight: Optional[float] = None
    height: Optional[float] = None
    gender: Optional[str] = None        # 'male', 'female'
    activity_level: Optional[str] = None # 'sedentary', 'light', 'active'

# Properties to receive via API on creation
class UserCreate(UserBase):
    email: EmailStr
    password: str

# Properties to receive via API on update
class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    email: Optional[EmailStr] = None
    age: Optional[int] = None
    weight: Optional[float] = None
    height: Optional[float] = None
    gender: Optional[str] = None
    activity_level: Optional[str] = None
    calories_goal: Optional[int] = None # Allow manual override if needed

class UserUpdatePassword(BaseModel):
    current_password: str
    new_password: str

# --- NEW SCHEMA (Added to fix ImportError) ---
class NewPassword(BaseModel):
    token: str
    new_password: str
# ---------------------------------------------

# Properties to return to client
class User(UserBase):
    id: int
    calories_goal: Optional[int] = 2000
    
    model_config = ConfigDict(from_attributes=True)