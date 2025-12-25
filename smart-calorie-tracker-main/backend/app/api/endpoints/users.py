# backend/app/api/endpoints/users.py

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from passlib.context import CryptContext
from app.db.session import SessionLocal
from app.models.user import User
from app.schemas.user import UserCreate, User as UserSchema

router = APIRouter()

# setting up password hashing here
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

async def get_db():
    async with SessionLocal() as session:
        yield session

@router.post("/", response_model=UserSchema)
async def create_user(user_in: UserCreate, db: AsyncSession = Depends(get_db)):
    # checking if user already exists in db
    result = await db.execute(select(User).where(User.email == user_in.email))
    if result.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Email already registered")

    hashed_password = pwd_context.hash(user_in.password)

    new_user = User(email=user_in.email, hashed_password=hashed_password)
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)

    return new_user