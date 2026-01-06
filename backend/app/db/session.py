# backend/app/db/session.py
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from app.core.config import settings

# Initialize the asynchronous SQLAlchemy engine
# Echo is enabled to log SQL queries for easier debugging during development
engine = create_async_engine(
    settings.SQLALCHEMY_DATABASE_URI, 
    echo=True,
    future=True
)

# Configure the session factory for asynchronous database interactions
# expire_on_commit is set to False to prevent issues with detached objects
SessionLocal = sessionmaker(
    autocommit=False, 
    autoflush=False, 
    bind=engine, 
    class_=AsyncSession,
    expire_on_commit=False
)