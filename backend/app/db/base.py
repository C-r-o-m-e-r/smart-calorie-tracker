# backend/app/db/base.py
# FINAL: Clean Base definition to avoid circular imports

from sqlalchemy.orm import DeclarativeBase

class Base(DeclarativeBase):
    pass