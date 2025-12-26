# backend/app/schemas/token.py
from pydantic import BaseModel

class Token(BaseModel):
    access_token: str
    refresh_token: str  # <--- Нове поле
    token_type: str

class TokenPayload(BaseModel):
    sub: int | None = None