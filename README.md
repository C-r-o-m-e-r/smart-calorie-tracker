# Smart Calorie Tracker AI 🍎📸

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Smart Calorie Tracker is a cross-platform mobile application designed to simplify nutrition tracking. By leveraging AI (ChatGPT Vision), users can simply take a photo of their meal to receive an instant estimation of calories and macronutrients (proteins, fats, carbs).

-----

## 🚀 Features

### Core Functionality

- **AI-Powered Recognition:** Upload a food photo to get automatic calorie and nutrition breakdown.
- **Smart Journal:** Track daily intake with a detailed history log.
- **Cross-Platform:** Native applications for both Android (Java) and iOS (Swift).
- **Secure:** JWT-based authentication and secure data storage.

-----

## 🛠 Tech Stack

| Area | Technology |
|:---|:---|
| Backend | Python (FastAPI), PostgreSQL (Async via SQLAlchemy & asyncpg), OpenAI API (GPT-4 Vision), Docker & Docker Compose |
| Mobile Clients | Android (Native Java + Retrofit), iOS (Native Swift + SwiftUI + MVVM) |

-----

## 📂 Project Structure

```
smart-calorie-tracker/
├── backend/          # FastAPI application & business logic
├── android-app/      # Native Android client source code
├── ios-app/          # Native iOS client source code
├── database/         # SQL initialization scripts
├── docs/             # Project documentation & requirements
└── docker-compose.yml # Orchestration for DB and Backend services
```

-----

## ⚡️ Getting Started (Backend)

Follow these steps to set up the backend and database locally.

### Prerequisites

- Docker & Docker Compose
- Python 3.11+

-----

## Installation

### Clone the repository:

```
git clone [https://github.com/YOUR_USERNAME/smart-calorie-tracker.git](https://github.com/YOUR_USERNAME/smart-calorie-tracker.git)
cd smart-calorie-tracker
```

### Environment Setup:

Navigate to the backend folder and create your .env file (you will need to add your OpenAI API Key later).

```
cd backend
cp .env.example .env
```

### Start the Database:

Run PostgreSQL using Docker Compose. This will also initialize the tables defined in database/init.sql.

```
# Run from the root directory
docker-compose up -d
```

### Install Python Dependencies:

```
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### Run the Server:

```
uvicorn app.main:app --reload
```

The API will be available at: http://localhost:8000  
Interactive Docs: http://localhost:8000/docs

-----

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
