from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    username: Mapped[str] = mapped_column(
        String(50),
        unique=True,
        nullable=False
    )

    email: Mapped[str | None] = mapped_column(
        String(255),
        unique=True,
        nullable=True
    )

    password_hash: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True
    )

    is_guest: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False
    )

    guest_token: Mapped[str | None] = mapped_column(
    String(100),
    unique=True,
    nullable=True
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow
    )

    last_active: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow
    )

    player: Mapped["Player"] = relationship(
        back_populates="user",
        uselist=False
    )


class Player(Base):
    __tablename__ = "players"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    user_id: Mapped[int] = mapped_column(
        ForeignKey("users.id"),
        unique=True,
        nullable=False
    )

    coins: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False
    )

    fortress_level: Mapped[int] = mapped_column(
        Integer,
        default=1,
        nullable=False
    )

    current_streak: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False
    )

    best_streak: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False
    )

    user: Mapped["User"] = relationship(
        back_populates="player"
    )

class QuizQuestion(Base):
    __tablename__ = "quiz_questions"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        index=True
    )

    question: Mapped[str] = mapped_column(
        String(500),
        nullable=False
    )

    option_a: Mapped[str] = mapped_column(
        String(300),
        nullable=False
    )

    option_b: Mapped[str] = mapped_column(
        String(300),
        nullable=False
    )

    option_c: Mapped[str] = mapped_column(
        String(300),
        nullable=False
    )

    option_d: Mapped[str] = mapped_column(
        String(300),
        nullable=False
    )

    correct_answer: Mapped[str] = mapped_column(
        String(1),
        nullable=False
    )

    difficulty: Mapped[int] = mapped_column(
        Integer,
        default=1,
        nullable=False
    )

    topic: Mapped[str] = mapped_column(
        String(100),
        nullable=False
    )

    explanation: Mapped[str] = mapped_column(
        String(1000),
        nullable=False
    )

    question_type: Mapped[str] = mapped_column(
        String(20),
        default="permanent",
        nullable=False
    )

    status: Mapped[str] = mapped_column(
        String(20),
        default="approved",
        nullable=False
    )

    source: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True
    )

    source_url: Mapped[str | None] = mapped_column(
        String(500),
        nullable=True
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow
    )

class QuizSession(Base):
    __tablename__ = "quiz_sessions"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        index=True
    )

    player_id: Mapped[int] = mapped_column(
        ForeignKey("players.id"),
        nullable=False
    )

    current_streak: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False
    )

    temporary_reward: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False
    )

    is_active: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False
    )

    started_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow
    )

class PlayerDefense(Base):
    __tablename__ = "player_defenses"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        index=True
    )

    player_id: Mapped[int] = mapped_column(
        ForeignKey("players.id"),
        nullable=False
    )

    defense_name: Mapped[str] = mapped_column(
        String(50),
        nullable=False
    )

    price: Mapped[int] = mapped_column(
        Integer,
        nullable=False
    )

    is_owned: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False
    )