import os
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

from app.core.config import settings
from app.api.api import api_router
from app.api.endpoints import chat

# --- DATABASE IMPORTS ---
from app.db.session import engine
from app.db.base import Base
# Import models to ensure they are registered with Base.metadata
# (Even if unused here, the import is necessary for table creation)
try:
    from app.models.user import User
    from app.models.meal import Meal
except ImportError:
    print("⚠️ Warning: Could not import models. Tables might not be created correctly.")

# --- LIFESPAN (AUTO-CREATE TABLES) ---
@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Runs on startup. Checks if database tables exist and creates them if missing.
    """
    print("🔄 STARTUP: Checking database tables...")
    try:
        async with engine.begin() as conn:
            # Create all tables defined in Base
            await conn.run_sync(Base.metadata.create_all)
        print("✅ STARTUP: Database tables checked/created successfully.")
    except Exception as e:
        print(f"❌ STARTUP ERROR: Could not create tables. Reason: {e}")
    
    yield
    # Code after yield runs on shutdown (nothing needed here)

# Setup rate limiter by remote address
limiter = Limiter(key_func=get_remote_address)

# Attach lifespan logic to FastAPI app
app = FastAPI(title=settings.PROJECT_NAME, lifespan=lifespan)

# Attach limiter to app
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS Setup - Allow all for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static files setup (for images)
os.makedirs("app/static", exist_ok=True)
app.mount("/static", StaticFiles(directory="app/static"), name="static")

# Middleware to log requests and execution time
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    
    # Process request
    response = await call_next(request)
    
    # Calculate duration
    process_time = time.time() - start_time
    
    # Log to console
    print(f"📡 {request.method} {request.url.path} - status: {response.status_code} - took: {process_time:.4f}s")
    
    return response

# Include all routers
# 1. Standard API (login, users, meals)
app.include_router(api_router, prefix=settings.API_V1_STR)
# 2. Chat API (AI Nutritionist)
app.include_router(chat.router, prefix="/api/v1/chat", tags=["chat"])

# Health check endpoint
@app.get("/ping")
async def health_check():
    return {"status": "ok", "service": "smart calorie tracker", "version": "1.0.0"}

# Root endpoint
@app.get("/")
async def root():
    return {"status": "ok", "message": "API is running. Go to /docs for Swagger UI."}