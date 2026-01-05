# Smart Calorie Tracker AI 🍎📸

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.109-009688.svg?style=flat&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-F05138.svg?style=flat&logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-336791.svg?style=flat&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Docker](https://img.shields.io/badge/Docker-Enabled-2496ED.svg?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)

**Smart Calorie Tracker** is a comprehensive, full-stack mobile solution designed to automate nutrition tracking using state-of-the-art Generative AI. 

Unlike traditional trackers that require manual input, this system leverages **GPT-5 Mini (Vision)** to analyze food images, instantly estimating calories, macronutrients (proteins, fats, carbs), and portion sizes. The system is built on a high-performance asynchronous Python backend and a native iOS client implementing modern MVVM architecture.

---

## 🏗 System Architecture

The project follows a decoupled client-server architecture, ensuring scalability and security.

### 1. Backend Core (Python / FastAPI)
The server functionality is built with **FastAPI**, chosen for its asynchronous capabilities and automatic validation features.
-   **AI Pipeline:** Implements a robust image processing pipeline. User images are uploaded via `multipart/form-data`, securely stored, and processed via Base64 encoding before being analyzed by the **GPT-5 Mini** model.
-   **Security Layer:** Features a complete OAuth2 implementation with **JWT (JSON Web Tokens)**. It supports Access Token (short-lived) and Refresh Token (long-lived) rotation strategies.
-   **Data Persistence:** Uses **PostgreSQL** with `asyncpg` driver and **SQLAlchemy 2.0** ORM. Database schema changes are managed via **Alembic** migrations.

### 2. iOS Client (Swift / SwiftUI)
The mobile application is developed using **SwiftUI** and strictly adheres to the **MVVM (Model-View-ViewModel)** design pattern.
-   **Separation of Concerns:** ViewModels handle business logic and state transformation, ensuring the UI remains declarative and stateless.
-   **Reactive Updates:** Utilizes `Combine` and `@Published` properties to automatically reflect backend data changes (e.g., daily calorie progress) on the dashboard.

---

## 🚀 Key Features

### 🧠 Intelligent Analysis (AI)
* **Visual Recognition:** Identifies complex meals from a single photo using **GPT-5 Mini**.
* **Guardrails:** Includes an `is_food` validation check. The AI automatically rejects non-food images (e.g., objects, pets) to maintain data integrity.
* **Detailed Breakdown:** Returns precise data: Calories (kcal), Protein (g), Fats (g), Carbs (g), and approximate weight.

### 📊 Advanced Analytics & Physiology
* **Auto-BMR Calculation:** The system automatically calculates the user's Basal Metabolic Rate (BMR) using the **Mifflin-St Jeor Equation**.
* **Dynamic Goals:** TDEE (Total Daily Energy Expenditure) is recalculated in real-time whenever the user updates their weight or activity level.
* **Trend Visualization:** Provides JSON endpoints for weekly statistics, enabling the client to render 7-day trend charts.
* **Daily Summaries:** Aggregates data for "Progress Rings", showing remaining calories vs. daily goal.

### 🛡️ Infrastructure & Stability
* **Rate Limiting:** Implemented `SlowAPI` to limit expensive AI requests (e.g., 5 requests/minute per IP) to manage operational costs.
* **Static File Serving:** Configured secure serving of user-uploaded images for history review.
* **Containerization:** Fully dockerized environment (Application + Database) ensures consistency across development and production.

---

## 🛠 Technology Stack

### Backend
| Component | Technology | Version | Description |
| :--- | :--- | :--- | :--- |
| **Framework** | FastAPI | 0.109 | Async Web Framework |
| **Language** | Python | 3.12+ | Server-side logic |
| **Database** | PostgreSQL | 15.0 | Relational Data Storage |
| **ORM** | SQLAlchemy | 2.0 | Async Database Abstraction |
| **Migrations**| Alembic | 1.13 | Database Schema Migrations |
| **AI Model** | **GPT-5 Mini** | Vision | Image Analysis Engine |
| **Security** | Passlib / Jose | - | Bcrypt Hashing & JWT |

### iOS Client
| Component | Technology | Description |
| :--- | :--- | :--- |
| **UI Framework** | SwiftUI | Native Declarative UI |
| **Architecture** | MVVM | Model-View-ViewModel Pattern |
| **Networking** | URLSession | REST API Communication |

---

## 📂 Project Structure

The project is organized into distinct modules for the API, Database, and Client Application.

```text
smart-calorie-tracker/
├── backend/
│   ├── alembic/             # Database migrations
│   ├── app/
│   │   ├── api/             # API Route handlers (Auth, Meals, Users)
│   │   ├── core/            # App configuration and Security settings
│   │   ├── db/              # Database session management
│   │   ├── models/          # SQLAlchemy ORM models
│   │   ├── schemas/         # Pydantic data schemas for validation
│   │   ├── services/        # External integrations (OpenAI Service)
│   │   └── static/          # Local storage for uploaded images
│   ├── Dockerfile           # Backend container definition
│   ├── alembic.ini          # Alembic configuration
│   └── requirements.txt     # Python dependencies
├── database/
│   └── init.sql             # SQL schema initialization
├── ios-app/
│   └── smart-calorie-tracker/
│       ├── models/          # Swift Data Models (UserProfile, FoodEntry)
│       ├── ViewModels/      # Logic (DashboardViewModel, ChatViewModel)
│       ├── Views/           # UI Screens (Dashboard, AddMeal, Profile)
│       └── Services/        # Network Layer (APIService)
├── docs/                    # Architectural documentation
└── docker-compose.yml       # Orchestration for Backend + DB

```

---

## ⚡️ Setup & Installation

### Prerequisites

* Docker & Docker Compose
* Python 3.12+ (optional, for local debugging)
* **OpenAI API Key** (with access to GPT-5 Mini / Vision models)

### 1. Backend Deployment (Docker)

The recommended way to run the server is via Docker Compose.

```bash
# Clone the repository
git clone [https://github.com/C-r-o-m-e-r/smart-calorie-tracker.git](https://github.com/C-r-o-m-e-r/smart-calorie-tracker.git)

# Configure Environment
cd backend
cp .env.example .env
# Edit .env and add your OPENAI_API_KEY

# Launch Services
docker-compose up --build

```

### 2. Database Migrations

Once the containers are running, apply the database migrations to create the schema:

```bash
# If running locally with venv:
python -m alembic upgrade head

# If running via Docker:
docker-compose exec backend alembic upgrade head

```

* **API Health Check:** `http://localhost:8000/ping`
* **Interactive Docs:** `http://localhost:8000/docs`

### 3. iOS Client Setup

1. Open `ios-app/smart-calorie-tracker.xcodeproj` in **Xcode 15+**.
2. If running on a simulator, ensure the API URL points to `http://localhost:8000`.
3. Build and run the target `smart-calorie-tracker`.

---

## 📄 License

This project is licensed under the **MIT License**. See the `LICENSE` file for details.