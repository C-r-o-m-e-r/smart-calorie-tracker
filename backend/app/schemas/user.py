# backend/app/schemas/user.py

from pydantic import BaseModel, EmailStr
from datetime import datetime

class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str
    # password needed only here dont want to leak it later

class User(UserBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True