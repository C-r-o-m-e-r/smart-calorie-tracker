# backend/app/api/api.py

from fastapi import APIRouter
from app.api.endpoints import users, meals, login # <--- Додали login сюди

# gathering all endpoints here to keep main clean
api_router = APIRouter()

# login route for authentication
api_router.include_router(login.router, tags=["login"]) # <--- Підключили роутер

# users route is ready others coming soon
api_router.include_router(users.router, prefix="/users", tags=["users"])

# adding meals router finally we can track food
api_router.include_router(meals.router, prefix="/meals", tags=["meals"])