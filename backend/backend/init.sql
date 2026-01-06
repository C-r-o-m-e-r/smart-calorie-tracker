-- database/init.sql
-- Updated for Block 2: Profile & Physiology

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    
    -- New Profile Fields
    full_name VARCHAR(255),
    age INTEGER,
    weight FLOAT,             -- kg
    height FLOAT,             -- cm
    gender VARCHAR(50),       -- 'male', 'female'
    activity_level VARCHAR(50), -- 'sedentary', 'moderate', 'active'
    calories_goal INTEGER DEFAULT 2000,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS meals (
    id SERIAL PRIMARY KEY,
    -- Added ON DELETE CASCADE for account deletion feature
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255),
    calories INTEGER,
    protein FLOAT,
    fats FLOAT,
    carbs FLOAT,
    weight_grams FLOAT,
    image_url VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);