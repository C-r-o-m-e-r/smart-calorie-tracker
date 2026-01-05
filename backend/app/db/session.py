# backend/app/db/session.py
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

from app.core.config import settings

# FIX: Changed settings.DATABASE_URL to settings.SQLALCHEMY_DATABASE_URI
engine = create_async_engine(settings.SQLALCHEMY_DATABASE_URI, echo=True)

SessionLocal = sessionmaker(
    autocommit=False, 
    autoflush=False, 
    bind=engine, 
    class_=AsyncSession
)