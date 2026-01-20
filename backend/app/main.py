# backend/app/main.py
import os
import time
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

from app.core.config import settings
from app.api.api import api_router

# fix rate limit by ip addr 
limiter = Limiter(key_func=get_remote_address)

app = FastAPI(title=settings.PROJECT_NAME)

# connect to app and handle too many reqs
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# allow ios apps to talk to us
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# static files dir setup here
os.makedirs("app/static", exist_ok=True)
app.mount("/static", StaticFiles(directory="app/static"), name="static")

# log stuff and check time
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    
    # run request
    response = await call_next(request)
    
    # check speed
    process_time = time.time() - start_time
    
    # print to console for debug
    print(f"📡 {request.method} {request.url.path} - status: {response.status_code} - took: {process_time:.4f}s")
    
    return response

# all routs are here
app.include_router(api_router, prefix=settings.API_V1_STR)

# standard ping for docker
@app.get("/ping")
async def health_check():
    return {"status": "ok", "service": "smart calorie tracker", "version": "1.0.0"}

@app.get("/")
async def root():
    return {"status": "ok", "message": "api is running. go to /docs for swagger."}