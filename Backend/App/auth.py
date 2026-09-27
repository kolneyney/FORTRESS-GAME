from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
import random
import secrets
import re
from pydantic import BaseModel
from passlib.context import CryptContext

from .database import get_db
from .models import User, Player
from .defense import initialize_defenses


router = APIRouter(
    prefix="/auth",
    tags=["Auth"]
)


pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto"
)


class RegisterRequest(BaseModel):
    guest_token: str
    username: str
    email: str
    password: str


@router.post("/guest")
def create_guest(
    db: Session = Depends(get_db)
):
    while True:
        guest_number = random.randint(10000, 99999)
        guest_username = f"guest_{guest_number}"

        existing_user = db.query(User).filter(
            User.username == guest_username
        ).first()

        if not existing_user:
            break

    guest_token = secrets.token_urlsafe(32)

    user = User(
        username=guest_username,
        is_guest=True,
        guest_token=guest_token
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    player = Player(
        user_id=user.id,
        coins=0,
        fortress_level=1,
        current_streak=0,
        best_streak=0
    )

    db.add(player)
    db.commit()
    db.refresh(player)

    initialize_defenses(player.id, db)

    return {
        "message": "Guest player created!",
        "user_id": user.id,
        "player_id": player.id,
        "username": user.username,
        "guest_token": user.guest_token,
        "is_guest": True,
        "coins": player.coins
    }


@router.get("/guest/{guest_token}")
def get_guest(
    guest_token: str,
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(
        User.guest_token == guest_token,
        User.is_guest == True
    ).first()

    if not user:
        raise HTTPException(
            status_code=404,
            detail="Guest account not found"
        )

    return {
        "user_id": user.id,
        "player_id": user.player.id,
        "username": user.username,
        "is_guest": user.is_guest,
        "coins": user.player.coins
    }

def is_valid_email(email: str) -> bool:
    pattern = r"^[^@\s]+@[^@\s]+\.[^@\s]+$"
    return re.match(pattern, email) is not None


def is_valid_password(password: str) -> bool:
    return len(password) >= 8

@router.post("/register")
def register_guest(
    data: RegisterRequest,
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(
        User.guest_token == data.guest_token,
        User.is_guest == True
    ).first()

    if not user:
        raise HTTPException(
            status_code=404,
            detail="Guest account not found"
        )

    if not is_valid_email(data.email):
        raise HTTPException(
            status_code=400,
            detail="Invalid email format"
        )

    if not is_valid_password(data.password):
        raise HTTPException(
            status_code=400,
            detail="Password must be at least 8 characters"
        )

    existing_username = db.query(User).filter(
        User.username == data.username,
        User.id != user.id
    ).first()

    if existing_username:
        raise HTTPException(
            status_code=400,
            detail="Username already exists"
        )

    existing_email = db.query(User).filter(
        User.email == data.email,
        User.id != user.id
    ).first()

    if existing_email:
        raise HTTPException(
            status_code=400,
            detail="Email already exists"
        )

    user.username = data.username
    user.email = data.email
    user.password_hash = pwd_context.hash(data.password)
    user.is_guest = False
    user.guest_token = None

    db.commit()
    db.refresh(user)

    return {
        "message": "Guest account converted successfully!",
        "user_id": user.id,
        "is_guest": user.is_guest,
        "username": user.username,
        "email": user.email,
        "player_id": user.player.id
    }