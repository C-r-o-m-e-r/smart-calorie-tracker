# backend/app/core/config.py
# adding refresh token settings

from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    PROJECT_NAME: str = "Smart Calorie Tracker AI"
    API_V1_STR: str = "/api/v1"

    # Database settings
    POSTGRES_USER: str
    POSTGRES_PASSWORD: str
    POSTGRES_DB: str
    POSTGRES_HOST: str = "db"
    POSTGRES_PORT: int = 5432

    # AI settings
    OPENAI_API_KEY: str

    # Security settings
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    
    # Access token is short-lived (e.g., 60 minutes) for security
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 
    
    # Refresh token is long-lived (e.g., 30 days) so user stays logged in
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    model_config = SettingsConfigDict(env_file=".env", case_sensitive=True, extra="ignore")

    @property
    def DATABASE_URL(self) -> str:
        return f"postgresql+asyncpg://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}@{self.POSTGRES_HOST}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"

settings = Settings()