from fastapi import FastAPI

from .database import Base, engine
from . import models

app = FastAPI(
    title="Fortress Quiz API",
    description="Backend API for the Fortress Quiz game",
    version="1.0.0"
)


# Create database tables
Base.metadata.create_all(bind=engine)


@app.get("/")
def home():
    return {
        "message": "Fortress Quiz Backend is running!"
    }