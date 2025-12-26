# backend/app/main.py
# Final configuration: Rate Limiting, Logging, Static Files

import os
import time
from fastapi import FastAPI, Request
from fastapi.staticfiles import StaticFiles
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

from app.core.config import settings
from app.api.api import api_router

# 1. Setup Rate Limiter (Identify users by IP address)
limiter = Limiter(key_func=get_remote_address)

app = FastAPI(title=settings.PROJECT_NAME)

# 2. Connect Limiter to App
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# 3. Setup Static Files
os.makedirs("app/static", exist_ok=True)
app.mount("/static", StaticFiles(directory="app/static"), name="static")

# 4. Middleware: Logging & Performance Monitoring
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    
    # Process the request
    response = await call_next(request)
    
    # Calculate duration
    process_time = time.time() - start_time
    
    # Log to console (Green for success, Red/Yellow logic could be added)
    print(f"📡 {request.method} {request.url.path} - Status: {response.status_code} - Took: {process_time:.4f}s")
    
    return response

# Including routes
app.include_router(api_router, prefix=settings.API_V1_STR)

# 5. Health Check Endpoint (Standard for Docker/K8s)
@app.get("/ping")
async def health_check():
    return {"status": "ok", "service": "Smart Calorie Tracker", "version": "1.0.0"}

@app.get("/")
async def root():
    return {"status": "ok", "message": "API is running. Go to /docs for Swagger."}