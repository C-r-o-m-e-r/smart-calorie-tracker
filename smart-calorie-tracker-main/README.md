# Smart Calorie Tracker AI 🍎📸

[![License:MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Smart Calorie Tracker is a cross-platform mobile application designed to
simplify nutrition tracking. By leveraging **AI (ChatGPT Vision / GPT‑4o
mini)**, users can take a photo of their meal and instantly receive an
estimation of calories and macronutrients.

------------------------------------------------------------------------

## 🚀 Features

### **Core Functionality**

-   🔍 **AI-Powered Recognition:** Automatic calorie & macro estimation
    from photos\
-   📘 **Smart Journal:** Daily nutrition log\
-   📱 **Cross-Platform:** Android (Java) + iOS (Swift)\
-   🔐 **Secure:** JWT authentication + safe data storage

------------------------------------------------------------------------

## 🛠 Tech Stack

  -----------------------------------------------------------------------
  Area                                Technology
  ----------------------------------- -----------------------------------
  **Backend**                         Python (FastAPI), PostgreSQL
                                      (Async), SQLAlchemy, asyncpg,
                                      OpenAI GPT‑4o mini, Docker

  **Mobile**                          Android (Java + Retrofit), iOS
                                      (Swift + SwiftUI + MVVM)
  -----------------------------------------------------------------------

------------------------------------------------------------------------

## 📂 Project Structure

``` text
smart-calorie-tracker/
├── android-app/         # Android native client
├── backend/
│   ├── app/
│   │   ├── api/         # Endpoints (auth, meals, AI)
│   │   ├── core/        # Config, settings
│   │   ├── db/          # Sessions, base
│   │   ├── models/      # ORM models
│   │   ├── schemas/     # Pydantic schemas
│   │   └── services/    # OpenAI integration
│   ├── Dockerfile
│   └── requirements.txt
├── database/            # SQL init scripts
├── docs/                # Documentation
├── ios-app/             # iOS native client
└── docker-compose.yml   # Docker orchestration
```

------------------------------------------------------------------------

## ⚡️ Getting Started (Backend)

Follow these steps to run the backend locally.

### **Prerequisites**

-   Docker & Docker Compose\
-   Python **3.11+**

------------------------------------------------------------------------

## 🛠 Installation

### **1. Clone the repository**

``` bash
git clone https://github.com/C-r-o-m-e-r/smart-calorie-tracker.git
cd smart-calorie-tracker
```

------------------------------------------------------------------------

### **2. Environment Setup**

``` bash
cd backend
cp .env.example .env
# Add your OpenAI API Key inside .env
```

------------------------------------------------------------------------

## 🚀 Option A --- Run Fully in Docker (Recommended)

``` bash
docker-compose up --build
```

**Backend:** http://localhost:8000\
**Docs (Swagger):** http://localhost:8000/docs

------------------------------------------------------------------------

## 🧩 Option B --- Hybrid Mode (DB in Docker, Backend Locally)

### Start only PostgreSQL:

``` bash
docker-compose up -d db
```

### Run backend locally:

``` bash
cd backend
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

------------------------------------------------------------------------

## 📄 License

Licensed under the **MIT License**. See the `LICENSE` file for details.