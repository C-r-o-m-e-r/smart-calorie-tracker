# backend/app/models/user.py
# added profile fields for health calculation

from sqlalchemy import Column, Integer, String, Float, DateTime
from sqlalchemy.sql import func
from app.db.base import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    
    # --- New Profile Fields ---
    full_name = Column(String, nullable=True)
    age = Column(Integer, nullable=True)
    weight = Column(Float, nullable=True)       # kg
    height = Column(Float, nullable=True)       # cm
    gender = Column(String, nullable=True)      # 'male' or 'female'
    activity_level = Column(String, nullable=True) # e.g. 'sedentary'
    calories_goal = Column(Integer, default=2000) # target daily intake
    # --------------------------

    created_at = Column(DateTime(timezone=True), server_default=func.now())