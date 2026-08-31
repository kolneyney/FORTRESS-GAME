from fastapi import FastAPI

app = FastAPI(
    title="Fortress Quiz API",
    description="Backend API for the Fortress Quiz cybersecurity game",
    version="1.0.0"
)


@app.get("/")
def home():
    return {
        "message": "Fortress Quiz API is running!"
    }