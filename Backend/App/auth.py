
from datetime import datetime, timedelta
import os
import re

from jose import jwt, JWTError
from dotenv import load_dotenv
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from pydantic import BaseModel, Field
from passlib.context import CryptContext

from .database import get_db
from .models import User, Player, PlayerDefense


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

security = HTTPBearer(auto_error=False)


# Create a JWT for a registered user.
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


# Get the registered user from their JWT.
def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
):
    if credentials is None:
        raise HTTPException(
            status_code=401,
            detail="Authentication required"
        )

    try:
        payload = jwt.decode(
            credentials.credentials,
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

        if not user or user.is_guest:
            raise HTTPException(
                status_code=401,
                detail="Registered account not found"
            )

        # Update the registered user's activity.
        user.last_active = datetime.utcnow()
        db.commit()

        return user

    except HTTPException:
        raise

    except (JWTError, ValueError, TypeError):
        raise HTTPException(
            status_code=401,
            detail="Invalid or expired authentication token"
        )


# Request models.
class DefenseProgress(BaseModel):
    name: str
    level: int = Field(ge=0, le=5)


class GuestProgress(BaseModel):
    coins: int = Field(default=0, ge=0)
    current_streak: int = Field(default=0, ge=0)
    best_streak: int = Field(default=0, ge=0)
    defenses: list[DefenseProgress] = Field(default_factory=list)


class RegisterRequest(BaseModel):
    username: str
    password: str
    guest_progress: GuestProgress | None = None


class LoginRequest(BaseModel):
    username: str
    password: str


# Password validation.
def is_valid_password(password: str) -> bool:
    return (
        len(password) >= 8
        and re.search(r"[A-Z]", password) is not None
        and re.search(r"[a-z]", password) is not None
        and re.search(r"[0-9]", password) is not None
        and re.search(r"[^A-Za-z0-9]", password) is not None
    )


@router.get("/me")
def get_me(current_user=Depends(get_current_user)):
    player = current_user.player

    if not player:
        raise HTTPException(status_code=404, detail="Player profile not found")

    return {
        "user_id": current_user.id,
        "username": current_user.username,
        "is_guest": current_user.is_guest,
        "player_id": player.id,
        "coins": player.coins,
        "current_streak": player.current_streak,
        "best_streak": player.best_streak
    }

# Register a new account.
@router.post("/register")
def register(
    data: RegisterRequest,
    db: Session = Depends(get_db)
):
    username = data.username.strip()

    if not username:
        raise HTTPException(
            status_code=400,
            detail="Username is required"
        )

    if len(username) > 50:
        raise HTTPException(
            status_code=400,
            detail="Username must be 50 characters or fewer"
        )

    if not is_valid_password(data.password):
        raise HTTPException(
            status_code=400,
            detail=(
                "Password must be at least 8 characters "
                "and include uppercase, lowercase, "
                "a number, and a symbol"
            )
        )

    existing_user = db.query(User).filter(
        User.username == username
    ).first()

    if existing_user:
        raise HTTPException(
            status_code=400,
            detail="Username already exists"
        )

    progress = data.guest_progress

    # Validate guest defense information.
    valid_defenses = {
        "Firewall",
        "Antivirus",
        "MFA",
        "Backup"
    }

    defense_levels = {}

    if progress:
        for defense in progress.defenses:

            if defense.name not in valid_defenses:
                raise HTTPException(
                    status_code=400,
                    detail=f"Invalid defense: {defense.name}"
                )

            if defense.name in defense_levels:
                raise HTTPException(
                    status_code=400,
                    detail=f"Duplicate defense: {defense.name}"
                )

            defense_levels[defense.name] = defense.level

    # Create the registered account.
    try:
        user = User(
            username=username,
            password_hash=pwd_context.hash(data.password),
            is_guest=False
        )

        db.add(user)
        db.flush()

        # Create the player and transfer guest progress.
        player = Player(
            user_id=user.id,
            coins=progress.coins if progress else 0,
            fortress_level=1,
            current_streak=(
                progress.current_streak if progress else 0
            ),
            best_streak=(
                max(progress.best_streak, progress.current_streak)
                if progress else 0
            )
        )

        db.add(player)
        db.flush()

        # Create the four defense records.
        from .defense import DEFENSE_PRICES

        for defense_name, base_price in DEFENSE_PRICES.items():

            level = defense_levels.get(defense_name, 0)

            defense = PlayerDefense(
                player_id=player.id,
                defense_name=defense_name,
                price=base_price,
                level=level,
                is_owned=level > 0
            )

            db.add(defense)

        # Save everything together.
        db.commit()

        db.refresh(user)
        db.refresh(player)

        access_token = create_access_token(user.id)

        return {
            "message": "Registration successful!",
            "access_token": access_token,
            "token_type": "bearer",
            "user_id": user.id,
            "player_id": player.id,
            "username": user.username,
            "is_guest": False,
            "coins": player.coins,
            "current_streak": player.current_streak,
            "best_streak": player.best_streak
        }

    except Exception:
        db.rollback()

        raise HTTPException(
            status_code=500,
            detail="Registration failed. Please try again."
        )


# Login with username and password.
@router.post("/login")
def login(
    data: LoginRequest,
    db: Session = Depends(get_db)
):
    username = data.username.strip()

    user = db.query(User).filter(
        User.username == username,
        User.is_guest == False
    ).first()

    if not user or not user.password_hash:
        raise HTTPException(
            status_code=401,
            detail="Invalid username or password"
        )

    if not pwd_context.verify(data.password, user.password_hash):
        raise HTTPException(
            status_code=401,
            detail="Invalid username or password"
        )

    user.last_active = datetime.utcnow()
    db.commit()

    access_token = create_access_token(user.id)

    return {
        "message": "Login successful!",
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": user.id,
        "username": user.username,
        "is_guest": False,
        "player_id": user.player.id,
        "coins": user.player.coins
    }
