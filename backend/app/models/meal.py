# backend/app/models/meal.py
# sqlalchemy model definition (db schema)

from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.base import Base

class Meal(Base):
    __tablename__ = "meals"

    id = Column(Integer, primary_key=True, index=True)
    # foreign key is required for linking to user
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    name = Column(String, nullable=False)
    calories = Column(Integer, nullable=False)
    
    # using float for macros as requested
    protein = Column(Float, default=0.0)
    fats = Column(Float, default=0.0)
    carbs = Column(Float, default=0.0)
    
    weight_grams = Column(Float, nullable=True)
    image_url = Column(String, nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)

    # relationship back to user
    # this corresponds to 'meals' in user model
    owner = relationship("User", back_populates="meals")