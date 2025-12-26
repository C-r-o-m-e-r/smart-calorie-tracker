# backend/app/api/deps.py
# dependency injection: handling db sessions and user auth

from typing import AsyncGenerator
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from pydantic import ValidationError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core import security
from app.core.config import settings
from app.db.session import SessionLocal
from app.models.user import User

# This tells FastAPI that the token creates a "lock" on endpoints
# The tokenUrl points to where the user sends their password to get a token
reusable_oauth2 = OAuth2PasswordBearer(
    tokenUrl=f"{settings.API_V1_STR}/login/access-token"
)

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    # creates a new database session for a request and closes it afterwards
    async with SessionLocal() as session:
        yield session

async def get_current_user(
    db: AsyncSession = Depends(get_db),
    token: str = Depends(reusable_oauth2)
) -> User:
    # 1. Decode the token
    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        token_data = payload.get("sub")
    except (JWTError, ValidationError):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Could not validate credentials",
        )
    
    # 2. Check if user exists in DB
    # (user_id is stored as string in token, so we cast to int if needed)
    user = await db.get(User, int(token_data))
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return user