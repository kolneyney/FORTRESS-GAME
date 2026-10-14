from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel

from .database import get_db
from .models import QuizQuestion, Player, QuizSession
from .auth import get_current_user


router = APIRouter(
    prefix="/quiz",
    tags=["Quiz"]
)


class AnswerRequest(BaseModel):
    question_id: int
    answer: str

def get_difficulty_from_streak(streak: int) -> int:
    if streak <= 2:
        return 1
    elif streak <= 5:
        return 2
    elif streak <= 8:
        return 3
    elif streak <= 10:
        return 4
    else:
        return 5


def get_base_reward(difficulty: int) -> int:
    rewards = {
        1: 10,
        2: 20,
        3: 30,
        4: 40,
        5: 50
    }

    return rewards.get(difficulty, 10)


@router.post("/start")
def start_quiz(
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    player = current_user.player

    if not player:
        raise HTTPException(
            status_code=404,
            detail="Player not found"
        )

    old_sessions = db.query(QuizSession).filter(
        QuizSession.player_id == player.id,
        QuizSession.is_active == True
    ).all()

    for old_session in old_sessions:
        old_session.is_active = False

    player.current_streak = 0

    session = QuizSession(
        player_id=player.id,
        current_streak=0,
        temporary_reward=0,
        is_active=True
    )

    db.add(session)
    db.commit()
    db.refresh(session)

    return {
        "message": "Quiz started!",
        "session_id": session.id,
        "current_streak": 0,
        "session_coins": 0,
        "player_total_coins": player.coins
    }



@router.get("/question")
def get_question(
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    player = current_user.player

    if not player:
        raise HTTPException(
            status_code=404,
            detail="Player not found"
        )

    session = db.query(QuizSession).filter(
        QuizSession.player_id == player.id,
        QuizSession.is_active == True
    ).order_by(
        QuizSession.id.desc()
    ).first()

    if not session:
        raise HTTPException(
            status_code=400,
            detail="No active quiz session. Start a quiz first."
        )

    difficulty = get_difficulty_from_streak(
        session.current_streak
    )

    questions = (
        db.query(QuizQuestion)
        .filter(
            QuizQuestion.difficulty == difficulty,
            QuizQuestion.status == "approved"
        )
        .all()
    )

    if not questions:
        raise HTTPException(
            status_code=404,
            detail="No approved questions available for this difficulty"
        )

    import random
    question = random.choice(questions)

    return {
        "id": question.id,
        "question": question.question,
        "options": {
            "A": question.option_a,
            "B": question.option_b,
            "C": question.option_c,
            "D": question.option_d
        },
        "difficulty": question.difficulty,
        "topic": question.topic,
        "session_id": session.id,
        "current_streak": session.current_streak,
        "session_coins": session.temporary_reward,
        "player_total_coins": player.coins
    }


@router.post("/answer")
def submit_answer(
    answer_data: AnswerRequest,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    player = current_user.player

    if not player:
        raise HTTPException(
            status_code=404,
            detail="Player not found"
        )

    session = db.query(QuizSession).filter(
        QuizSession.player_id == player.id,
        QuizSession.is_active == True
    ).order_by(
        QuizSession.id.desc()
    ).first()

    if not session:
        raise HTTPException(
            status_code=400,
            detail="No active quiz session. Start a quiz first."
        )

    question = db.query(QuizQuestion).filter(
        QuizQuestion.id == answer_data.question_id
    ).first()

    if not question:
        raise HTTPException(
            status_code=404,
            detail="Question not found"
        )

    is_correct = (
        answer_data.answer.upper()
        == question.correct_answer.upper()
    )

    if is_correct:
        session.current_streak += 1
        player.current_streak = session.current_streak

        if session.current_streak > player.best_streak:
            player.best_streak = session.current_streak

        reward = get_base_reward(question.difficulty)

        session.temporary_reward += reward

        db.commit()

        return {
            "correct": True,
            "message": "Correct answer!",
            "reward": reward,
            "session_coins": session.temporary_reward,
            "player_total_coins": player.coins,
            "current_streak": session.current_streak,
            "best_streak": player.best_streak,
            "game_over": False
        }

    else:
        session_coins = session.temporary_reward
        earned_coins = session_coins // 2

        player.coins += earned_coins

        session.current_streak = 0
        player.current_streak = 0
        session.is_active = False
        session.temporary_reward = 0

        db.commit()

        return {
            "correct": False,
            "message": "Wrong answer! Game over!",
            "reward": 0,
            "session_coins": session_coins,
            "earned_coins": earned_coins,
            "player_total_coins": player.coins,
            "current_streak": 0,
            "best_streak": player.best_streak,
            "game_over": True
        }


@router.post("/cashout")
def cashout_quiz(
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    player = current_user.player

    if not player:
        raise HTTPException(
            status_code=404,
            detail="Player not found"
        )

    session = db.query(QuizSession).filter(
        QuizSession.player_id == player.id,
        QuizSession.is_active == True
    ).order_by(
        QuizSession.id.desc()
    ).first()

    if not session:
        raise HTTPException(
            status_code=400,
            detail="No active quiz session."
        )

    earned_coins = session.temporary_reward

    player.coins += earned_coins

    session.is_active = False
    session.current_streak = 0
    player.current_streak = 0
    session.temporary_reward = 0

    db.commit()

    return {
        "message": "Quiz ended successfully!",
        "earned_coins": earned_coins,
        "player_total_coins": player.coins,
        "current_streak": 0,
        "best_streak": player.best_streak,
        "game_over": False,
        "cashed_out": True
    }