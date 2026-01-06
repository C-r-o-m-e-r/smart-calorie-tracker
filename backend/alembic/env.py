# backend/alembic/env.py
import asyncio
from logging.config import fileConfig

from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import create_async_engine

from alembic import context

# --- Custom Imports ---
# Ensure the current working directory is added to sys.path to allow importing the 'app' package
import sys
import os
sys.path.append(os.getcwd())

from app.core.config import settings
from app.db.base import Base

# Import models here to ensure they are registered with Base.metadata for autogenerate support
from app.models.user import User  # noqa: F401
from app.models.meal import Meal  # noqa: F401
# ----------------------

# Alembic Config object, providing access to the values within the .ini file
config = context.config

# Interpret the config file for Python logging
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Set the SQLAlchemy URL dynamically from the application settings
config.set_main_option("sqlalchemy.url", str(settings.SQLALCHEMY_DATABASE_URI))

# Target metadata for autogenerate support
target_metadata = Base.metadata

def run_migrations_offline() -> None:
    """
    Run migrations in 'offline' mode.
    This configures the context with just a URL and not an Engine.
    """
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()

def do_run_migrations(connection: Connection) -> None:
    """
    Apply migrations using the provided database connection.
    """
    context.configure(connection=connection, target_metadata=target_metadata)

    with context.begin_transaction():
        context.run_migrations()

async def run_migrations_online() -> None:
    """
    Run migrations in 'online' mode.
    Creates an asynchronous engine and associates a connection with the context.
    """
    
    # Create the asynchronous engine using the URI from our settings
    # We use create_async_engine directly to ensure Docker environment variables are respected
    connectable = create_async_engine(
        str(settings.SQLALCHEMY_DATABASE_URI),
        poolclass=pool.NullPool,
    )

    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

    await connectable.dispose()

# Decide whether to run migrations in offline or online mode
if context.is_offline_mode():
    run_migrations_offline()
else:
    asyncio.run(run_migrations_online())