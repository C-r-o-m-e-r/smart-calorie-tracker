# backend/app/db/session.py
# setting up db engine and session stuff here

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from app.core.config import settings

# creating the engine using url from config
engine = create_async_engine(settings.DATABASE_URL, echo=True)

# factory for creating new database sessions
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
    class_=AsyncSession
)