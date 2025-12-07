# backend/app/main.py
# putting everything together here mostly routing stuff
# api v1 prefix is important dont forget it

from fastapi import FastAPI
from app.core.config import settings
from app.api.api import api_router

app = FastAPI(title=settings.PROJECT_NAME)

# including the main router that holds all endpoints
app.include_router(api_router, prefix=settings.API_V1_STR)

@app.get("/")
async def root():
    # simple health check for docker or uptime robot
    return {"status": "ok", "message": "Smart Calorie Tracker API is running"}