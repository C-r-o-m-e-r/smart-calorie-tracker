# backend/app/schemas/user.py
# Updated with profile fields and UserUpdate schema

from pydantic import BaseModel, EmailStr, field_validator
from datetime import datetime
from typing import Optional

class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str
    full_name: Optional[str] = None
    
    @field_validator('email')
    @classmethod
    def email_must_be_lowercase(cls, v: str) -> str:
        return v.lower()

    @field_validator('password')
    @classmethod
    def password_too_short(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters long')
        return v

# --- ОНОВЛЕНО: Схема відповіді сервера (Response) ---
class User(UserBase):
    id: int
    full_name: Optional[str] = None
    
    # Profile stats (те, що ми додали в SQL)
    age: Optional[int] = None
    weight: Optional[float] = None
    height: Optional[float] = None
    gender: Optional[str] = None
    activity_level: Optional[str] = None
    calories_goal: int # Це поле завжди має дефолт 2000
    
    created_at: datetime

    class Config:
        from_attributes = True

# --- НОВЕ: Схема для редагування профілю (PATCH) ---
class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    email: Optional[EmailStr] = None
    age: Optional[int] = None
    weight: Optional[float] = None
    height: Optional[float] = None
    gender: Optional[str] = None         # 'male', 'female'
    activity_level: Optional[str] = None # 'sedentary', 'active', etc.
    calories_goal: Optional[int] = None  # Якщо юзер хоче вручну задати ціль

# Used for resetting password via email token
class NewPassword(BaseModel):
    token: str
    new_password: str
    
    @field_validator('new_password')
    @classmethod
    def password_too_short(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters long')
        return v

# Used for changing password while logged in
class UserUpdatePassword(BaseModel):
    current_password: str
    new_password: str

    @field_validator('new_password')
    @classmethod
    def password_too_short(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters long')
        return v