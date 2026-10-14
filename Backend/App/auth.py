from datetime import datetime, timedelta
import os
from jose import jwt
from dotenv import load_dotenv
from fastapi import APIRouter, Depends, HTTPException, Header
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
import random
import secrets
import re
from pydantic import BaseModel
from passlib.context import CryptContext
from .database import get_db
from .models import User, Player


load_dotenv()

JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
JWT_EXPIRE_MINUTES = int(os.getenv("JWT_EXPIRE_MINUTES", "1440"))

router = APIRouter(
    prefix="/auth",
    tags=["Auth"]
)


pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto"
)

security = HTTPBearer()


def create_access_token(user_id: int):
    expire = datetime.utcnow() + timedelta(
        minutes=JWT_EXPIRE_MINUTES
    )

    payload = {
        "sub": str(user_id),
        "exp": expire
    }

    return jwt.encode(
        payload,
        JWT_SECRET_KEY,
        algorithm=JWT_ALGORITHM
    )

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
):
    token = credentials.credentials

    try:
        payload = jwt.decode(
            token,
            JWT_SECRET_KEY,
            algorithms=[JWT_ALGORITHM]
        )

        user_id = payload.get("sub")

        if not user_id:
            raise HTTPException(
                status_code=401,
                detail="Invalid authentication token"
            )

        user = db.query(User).filter(
            User.id == int(user_id)
        ).first()

        if not user:
            raise HTTPException(
                status_code=401,
                detail="User not found"
            )

        return user

    except Exception:
        raise HTTPException(
            status_code=401,
            detail="Invalid or expired authentication token"
        )

@router.get("/me")
def get_me(
    current_user: User = Depends(get_current_user)
):
    return {
        "user_id": current_user.id,
        "username": current_user.username,
        "is_guest": current_user.is_guest,
        "player_id": current_user.player.id,
        "coins": current_user.player.coins
    }


class RegisterRequest(BaseModel):
    guest_token: str
    username: str
    email: str
    password: str

class LoginRequest(BaseModel):
    username: str
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

    from .defense import initialize_defenses

    initialize_defenses(player.id, db)

    access_token = create_access_token(user.id)

    return {
        "message": "Guest player created!",
        "user_id": user.id,
        "player_id": player.id,
        "username": user.username,
        "guest_token": user.guest_token,
        "access_token": access_token,
        "token_type": "bearer",
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

@router.post("/login")
def login(
    data: LoginRequest,
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(
        User.username == data.username,
        User.is_guest == False
    ).first()

    if not user:
        raise HTTPException(
            status_code=401,
            detail="Invalid username or password"
        )

    if not user.password_hash:
        raise HTTPException(
            status_code=401,
            detail="Invalid username or password"
        )

    if not pwd_context.verify(data.password, user.password_hash):
        raise HTTPException(
            status_code=401,
            detail="Invalid username or password"
        )

    access_token = create_access_token(user.id)

    return {
        "message": "Login successful!",
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": user.id,
        "username": user.username,
        "is_guest": user.is_guest,
        "player_id": user.player.id,
        "coins": user.player.coins
    }