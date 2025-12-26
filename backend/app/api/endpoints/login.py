# backend/app/api/endpoints/login.py
# handling login, refresh token, and password recovery

from datetime import timedelta
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status, Body
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from jose import jwt, JWTError
from pydantic import ValidationError

from app.api import deps
from app.core import security
from app.core.config import settings
from app.models.user import User
from app.schemas.token import Token
from app.schemas.user import NewPassword  # <--- Імпортували схему для пароля
from app.schemas.msg import Msg           # <--- Імпортували схему повідомлення

router = APIRouter()

@router.post("/login/access-token", response_model=Token)
async def login_access_token(
    db: AsyncSession = Depends(deps.get_db),
    form_data: OAuth2PasswordRequestForm = Depends()
) -> Any:
    """
    OAuth2 compatible token login, get an access token AND refresh token
    """
    # 1. Find user
    result = await db.execute(select(User).where(User.email == form_data.username))
    user = result.scalars().first()

    # 2. Check password
    if not user or not security.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Incorrect email or password",
        )

    # 3. Create BOTH tokens
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    refresh_token_expires = timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)

    return {
        "access_token": security.create_access_token(
            subject=user.id, expires_delta=access_token_expires
        ),
        "refresh_token": security.create_refresh_token(
            subject=user.id, expires_delta=refresh_token_expires
        ),
        "token_type": "bearer",
    }

@router.post("/login/refresh-token", response_model=Token)
async def refresh_token(
    refresh_token: str = Body(..., embed=True),
    db: AsyncSession = Depends(deps.get_db)
) -> Any:
    """
    Get a new access token using a refresh token.
    """
    try:
        payload = jwt.decode(
            refresh_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        token_data = payload.get("sub")
        token_type = payload.get("type")
        
        if token_type != "refresh":
             raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token type",
            )
            
        if token_data is None:
             raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token data",
            )
            
    except (JWTError, ValidationError):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Could not validate credentials",
        )
        
    user = await db.get(User, int(token_data))
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    refresh_token_expires = timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)

    return {
        "access_token": security.create_access_token(
            subject=user.id, expires_delta=access_token_expires
        ),
        "refresh_token": security.create_refresh_token(
            subject=user.id, expires_delta=refresh_token_expires
        ),
        "token_type": "bearer",
    }

# --- NEW: Password Recovery Endpoints ---

@router.post("/password-recovery/{email}", response_model=Msg)
async def recover_password(email: str, db: AsyncSession = Depends(deps.get_db)) -> Any:
    """
    Password Recovery. Since we don't have SMTP, we print token to console.
    """
    result = await db.execute(select(User).where(User.email == email))
    user = result.scalars().first()

    if not user:
        # Security: fake success to prevent email enumeration
        print(f"DEBUG: Recovery requested for non-existent email {email}")
        return {"msg": "Password recovery email sent"}

    password_reset_token = security.create_password_reset_token(email=email)
    
    # --- SIMULATION ---
    print("\n" + "="*50)
    print(f"📧 EMAIL SIMULATION for: {email}")
    print(f"🔗 RECOVERY TOKEN: {password_reset_token}")
    print("="*50 + "\n")
    # ------------------
    
    return {"msg": "Password recovery email sent"}

@router.post("/reset-password", response_model=Msg)
async def reset_password(
    body: NewPassword,
    db: AsyncSession = Depends(deps.get_db)
) -> Any:
    """
    Reset password using the token received in email (console).
    """
    try:
        payload = jwt.decode(
            body.token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        token_type = payload.get("type")
        email = payload.get("sub")
        
        if token_type != "reset":
            raise HTTPException(status_code=400, detail="Invalid token type")
            
    except (JWTError, ValidationError):
        raise HTTPException(status_code=400, detail="Invalid token or expired")

    result = await db.execute(select(User).where(User.email == email))
    user = result.scalars().first()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    # Set new password
    user.hashed_password = security.get_password_hash(body.new_password)
    db.add(user)
    await db.commit()
    
    return {"msg": "Password updated successfully"}