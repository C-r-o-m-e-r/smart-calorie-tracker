# backend/app/api/api.py

from fastapi import APIRouter
from app.api.endpoints import users, meals

# gathering all endpoints here to keep main clean
api_router = APIRouter()

# users route is ready others coming soon
api_router.include_router(users.router, prefix="/users", tags=["users"])

# adding meals router finally we can track food
api_router.include_router(meals.router, prefix="/meals", tags=["meals"])