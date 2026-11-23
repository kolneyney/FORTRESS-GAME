from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .database import Base, engine
from . import models
from .quiz import router as quiz_router
from .defense import router as defense_router
from .auth import router as auth_router
from .leaderboard import router as leaderboard_router

app = FastAPI(
    title="Fortress Quiz API",
    description="Backend API for the Fortress Quiz game",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://www.fortressquizgame.site",
        "https://fortressquizgame.site",
        "https://fortress-quiz.vercel.app",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create database tables
Base.metadata.create_all(bind=engine)

app.include_router(quiz_router)
app.include_router(defense_router)
app.include_router(auth_router)
app.include_router(leaderboard_router)


@app.get("/")
def home():
    return {
        "message": "Fortress Quiz Backend is running!"
    }