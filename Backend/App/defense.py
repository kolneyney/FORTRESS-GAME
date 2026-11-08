
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .database import get_db
from .models import PlayerDefense
from .auth import get_current_user


router = APIRouter(
    prefix="/defenses",
    tags=["Defenses"]
)


DEFENSE_PRICES = {
    "Firewall": 15,
    "Antivirus": 25,
    "MFA": 50,
    "Backup": 100
}

MAX_LEVEL = 5


def initialize_defenses(player_id: int, db: Session):
    for defense_name, base_price in DEFENSE_PRICES.items():

        existing = db.query(PlayerDefense).filter(
            PlayerDefense.player_id == player_id,
            PlayerDefense.defense_name == defense_name
        ).first()

        if not existing:
            defense = PlayerDefense(
                player_id=player_id,
                defense_name=defense_name,
                price=base_price,
                level=0,
                is_owned=False
            )
            db.add(defense)
        else:
            existing.price = base_price



@router.get("")
def get_defenses(
    current_user=Depends(get_current_user),
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
                "level": defense.level,
                "max_level": MAX_LEVEL,
                "price": defense.price,
                "next_upgrade_price": (
                    defense.price * (defense.level + 1)
                    if defense.level < MAX_LEVEL
                    else None
                ),
                "is_owned": defense.is_owned
            }
            for defense in defenses
        ]
    }


@router.post("/buy/{defense_id}")
def buy_defense(
    defense_id: int,
    current_user=Depends(get_current_user),
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

    if defense.level >= MAX_LEVEL:
        raise HTTPException(
            status_code=400,
            detail="Defense has already reached maximum level"
        )

    upgrade_price = defense.price * (2 ** defense.level)

    if player.coins < upgrade_price:
        raise HTTPException(
            status_code=400,
            detail="Not enough coins"
        )

    player.coins -= upgrade_price
    defense.level += 1
    defense.is_owned = defense.level > 0

    db.commit()
    db.refresh(defense)
    db.refresh(player)

    next_price = (
        defense.price * (defense.level + 1)
        if defense.level < MAX_LEVEL
        else None
    )

    return {
        "message": "Defense upgraded successfully!",
        "defense": defense.defense_name,
        "level": defense.level,
        "price_paid": upgrade_price,
        "next_upgrade_price": next_price,
        "remaining_coins": player.coins,
        "is_owned": defense.is_owned
    }
