from .database import SessionLocal
from .models import QuizQuestion


questions = [
    {
        "question": "What is phishing?",
        "option_a": "A type of computer hardware",
        "option_b": "A cyberattack that tricks users into revealing information",
        "option_c": "A method of encrypting files",
        "option_d": "A type of firewall",
        "correct_answer": "B",
        "difficulty": 1,
    },
    {
        "question": "Which password is the strongest?",
        "option_a": "password123",
        "option_b": "12345678",
        "option_c": "P@ssword",
        "option_d": "vR7!kQ2#Lm9$xP",
        "correct_answer": "D",
        "difficulty": 1,
    },
    {
        "question": "What does MFA stand for?",
        "option_a": "Multi-Factor Authentication",
        "option_b": "Multiple Firewall Access",
        "option_c": "Main File Authorization",
        "option_d": "Managed Firewall Application",
        "correct_answer": "A",
        "difficulty": 1,
    },
    {
        "question": "What is the main purpose of a firewall?",
        "option_a": "To increase internet speed",
        "option_b": "To store passwords",
        "option_c": "To control and filter network traffic",
        "option_d": "To create backups",
        "correct_answer": "C",
        "difficulty": 1,
    },
    {
        "question": "What does IDS stand for?",
        "option_a": "Internet Data System",
        "option_b": "Intrusion Detection System",
        "option_c": "Internal Defense Service",
        "option_d": "Internet Defense Software",
        "correct_answer": "B",
        "difficulty": 2,
    },
    {
        "question": "What is the main difference between IDS and IPS?",
        "option_a": "IDS detects threats while IPS can detect and block threats",
        "option_b": "IDS blocks threats while IPS only detects them",
        "option_c": "They are exactly the same",
        "option_d": "IPS is only used for passwords",
        "correct_answer": "A",
        "difficulty": 2,
    },
    {
        "question": "What is ransomware?",
        "option_a": "Software that improves computer performance",
        "option_b": "Malware that encrypts or locks data and demands payment",
        "option_c": "A type of antivirus",
        "option_d": "A secure backup system",
        "correct_answer": "B",
        "difficulty": 2,
    },
    {
        "question": "Why are software updates important for cybersecurity?",
        "option_a": "They always make computers faster",
        "option_b": "They remove all user files",
        "option_c": "They can fix security vulnerabilities",
        "option_d": "They disable antivirus software",
        "correct_answer": "C",
        "difficulty": 2,
    },
    {
        "question": "What is the principle of least privilege?",
        "option_a": "Giving users the maximum possible permissions",
        "option_b": "Giving users only the permissions they need",
        "option_c": "Giving everyone administrator access",
        "option_d": "Removing all user accounts",
        "correct_answer": "B",
        "difficulty": 3,
    },
    {
        "question": "What is a zero-day vulnerability?",
        "option_a": "A vulnerability that has never existed",
        "option_b": "A vulnerability that has been publicly fixed for years",
        "option_c": "A newly discovered vulnerability for which a patch may not yet be available",
        "option_d": "A type of backup",
        "correct_answer": "C",
        "difficulty": 3,
    },
]


def seed_questions():
    db = SessionLocal()

    try:
        existing_count = db.query(QuizQuestion).count()

        if existing_count > 0:
            print(f"Database already contains {existing_count} questions.")
            return

        for question_data in questions:
            question = QuizQuestion(**question_data)
            db.add(question)

        db.commit()

        print(f"Successfully added {len(questions)} questions!")

    except Exception as e:
        db.rollback()
        print(f"Error: {e}")

    finally:
        db.close()


if __name__ == "__main__":
    seed_questions()