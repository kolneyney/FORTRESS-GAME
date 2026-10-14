from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .database import get_db
from .models import Player, PlayerDefense
from .auth import get_current_user



router = APIRouter(
    prefix="/defenses",
    tags=["Defenses"]
)


DEFENSES = [
    "Firewall",
    "Antivirus",
    "MFA",
    "IDS/IPS",
    "Backup"
]


def initialize_defenses(player_id: int, db: Session):
    prices = {
        "Firewall": 300,
        "Antivirus": 500,
        "MFA": 1500,
        "IDS/IPS": 3000,
        "Backup": 5000
    }

    for defense_name in DEFENSES:
        existing = db.query(PlayerDefense).filter(
            PlayerDefense.player_id == player_id,
            PlayerDefense.defense_name == defense_name
        ).first()

        if not existing:
            defense = PlayerDefense(
                player_id=player_id,
                defense_name=defense_name,
                price=prices[defense_name],
                is_owned=False
            )
            db.add(defense)

    db.commit()


@router.get("")
def get_defenses(
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    player = current_user.player

    if not player:
        raise HTTPException(
            status_code=404,
            detail="Player not found"
        )

    defenses = db.query(PlayerDefense).filter(
        PlayerDefense.player_id == player.id
    ).all()

    return {
        "player_id": player.id,
        "coins": player.coins,
        "defenses": [
            {
                "id": defense.id,
                "name": defense.defense_name,
                "price": defense.price,
                "is_owned": defense.is_owned
            }
            for defense in defenses
        ]
    }

@router.post("/buy/{defense_id}")
def buy_defense(
    defense_id: int,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    player = current_user.player

    if not player:
        raise HTTPException(
            status_code=404,
            detail="Player not found"
        )

    defense = db.query(PlayerDefense).filter(
    PlayerDefense.id == defense_id,
    PlayerDefense.player_id == player.id
    ).first()

    if not defense:
        raise HTTPException(
            status_code=404,
            detail="Defense not found"
        )

    if defense.is_owned:
        raise HTTPException(
            status_code=400,
            detail="Defense already owned"
        )

    if player.coins < defense.price:
        raise HTTPException(
            status_code=400,
            detail="Not enough coins"
        )

    player.coins -= defense.price
    defense.is_owned = True

    db.commit()

    return {
        "message": "Defense purchased successfully!",
        "defense": defense.defense_name,
        "price": defense.price,
        "remaining_coins": player.coins,
        "is_owned": defense.is_owned
    }