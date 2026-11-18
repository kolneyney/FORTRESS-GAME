
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from .database import get_db
from .models import User, Player
from .auth import get_current_user

router = APIRouter(
    prefix="/leaderboard",
    tags=["Leaderboard"]
)


class ScoreSubmission(BaseModel):
    coins: int = Field(ge=0)
    level: int = Field(ge=1)


@router.get("")
def get_leaderboard(db: Session = Depends(get_db)):
    results = (
        db.query(User.username, Player.coins, Player.best_level)
        .join(Player, Player.user_id == User.id)
        .filter(User.is_guest.is_(False))
        .order_by(
            Player.coins.desc(),
            Player.best_level.desc()
        )
        .limit(10)
        .all()
    )

    return {
        "entries": [
            {
                "username": username,
                "coins": coins,
                "level": best_level
            }
            for username, coins, best_level in results
        ]
    }


@router.post("/score")
def submit_score(
    data: ScoreSubmission,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    player = db.query(Player).filter(
        Player.user_id == current_user.id
    ).first()

    if not player:
        raise HTTPException(
            status_code=404,
            detail="Player profile not found"
        )

    # Save the latest coin balance.
    player.coins = data.coins

    # Keep the highest level ever cleared.
    player.best_level = max(player.best_level, data.level)

    db.commit()
    db.refresh(player)

    return {
        "message": "Progress saved successfully",
        "coins": player.coins,
        "level": player.best_level
    }
