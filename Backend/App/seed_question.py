from .database import SessionLocal
from .models import QuizQuestion


questions = [
    # =========================
    # LEVEL 1 - EASY
    # =========================

    {
        "question": "What is phishing?",
        "option_a": "A technique used to physically damage a computer",
        "option_b": "An attack that tricks people into revealing sensitive information",
        "option_c": "A method used to increase network speed",
        "option_d": "A process used to back up files",
        "correct_answer": "B",
        "difficulty": 1,
        "topic": "Phishing",
        "explanation": "Phishing is a social engineering attack that tricks people into providing sensitive information.",
        "question_type": "permanent",
        "status": "approved",
        "source": "Scribd reference",
        "source_url": "https://www.scribd.com/document/724774235/100-Q-A-CyberSecurity",
    },

    {
        "question": "What is the main purpose of a firewall?",
        "option_a": "To recover deleted files",
        "option_b": "To create user passwords",
        "option_c": "​​To filter and control network traffic",
        "option_d": "To increase CPU performance",
        "correct_answer": "C",
        "difficulty": 1,
        "topic": "Firewall",
        "explanation": "A firewall controls network traffic based on configured security rules.",
        "question_type": "permanent",
        "status": "approved",
        "source": "Scribd reference",
        "source_url": "https://www.scribd.com/document/724774235/100-Q-A-CyberSecurity",
    },

    {
        "question": "What does the term malware refer to?",
        "option_a": "A method of encrypting a database",
        "option_b": "Software used only for video editing",
        "option_c": "A physical network cable",
        "option_d": "Malicious software designed to harm or compromise systems",
        "correct_answer": "D",
        "difficulty": 1,
        "topic": "Malware",
        "explanation": "Malware is software intentionally designed to damage, disrupt, exploit, or gain unauthorized access to systems.",
        "question_type": "permanent",
        "status": "approved",
        "source": "Scribd reference",
        "source_url": "https://www.scribd.com/document/724774235/100-Q-A-CyberSecurity",
    },

    {
        "question": "What does Multi-Factor Authentication (MFA) provide?",
        "option_a": "Multiple copies of the same password",
        "option_b": "More than one type of authentication factor",
        "option_c": "Faster internet access",
        "option_d": "Automatic file backup",
        "correct_answer": "B",
        "difficulty": 1,
        "topic": "Authentication",
        "explanation": "MFA requires two or more authentication factors to verify a user's identity.",
        "question_type": "permanent",
        "status": "approved",
        "source": "Scribd reference",
        "source_url": "https://www.scribd.com/document/724774235/100-Q-A-CyberSecurity",
    },

    {
        "question": "What is a VPN commonly used for?",
        "option_a": "Encrypting network communication and providing a secure connection",
        "option_b": "Increasing hard-drive capacity",
        "option_c": "Removing all malware automatically",
        "option_d": "Creating new computer accounts",
        "correct_answer": "A",
        "difficulty": 1,
        "topic": "VPN",
        "explanation": "A VPN can create an encrypted connection over a network, helping protect data in transit.",
        "question_type": "permanent",
        "status": "approved",
        "source": "Scribd reference",
        "source_url": "https://www.scribd.com/document/724774235/100-Q-A-CyberSecurity",
    },


    # =========================
    # LEVEL 2 - MEDIUM
    # =========================

    {
        "question": "What type of attack attempts many possible passwords until the correct one is found?",
        "option_a": "Phishing",
        "option_b": "Brute-force attack",
        "option_c": "DDoS attack",
        "option_d": "SQL injection",
        "correct_answer": "B",
        "difficulty": 2,
        "topic": "Brute Force",
        "explanation": "A brute-force attack repeatedly tries possible password combinations until a valid credential is discovered.",
        "question_type": "permanent",
        "status": "approved",
        "source": "Scribd reference",
        "source_url": "https://www.scribd.com/document/724774235/100-Q-A-CyberSecurity",
    },

    {
        "question": "What is the main objective of a Distributed Denial-of-Service (DDoS) attack?",
        "option_a": "To improve server performance",
        "option_b": "To encrypt a user's password",
        "option_c": "To install an antivirus program",
        "option_d": "​To make a service unavailable by overwhelming it with traffic",
        "correct_answer": "D",
        "difficulty": 2,
        "topic": "DDoS",
        "explanation": "A DDoS attack attempts to make a service unavailable by overwhelming it with traffic or requests.",
        "question_type": "permanent",
        "status": "approved",
        "source": "Scribd reference",
        "source_url": "https://www.scribd.com/document/724774235/100-Q-A-CyberSecurity",
    },

    {
        "question": "What is the primary function of an Intrusion Detection System (IDS)?",
        "option_a": "Encrypt every file on a computer",
        "option_b": "Automatically replace damaged hardware",
        "option_c": "Detect and alert about potentially malicious activity",
        "option_d": "Create employee accounts",
        "correct_answer": "C",
        "difficulty": 2,
        "topic": "IDS",
        "explanation": "An IDS monitors activity and generates alerts when potentially malicious behavior is detected.",
        "question_type": "permanent",
        "status": "approved",
        "source": "Scribd reference",
        "source_url": "https://www.scribd.com/document/724774235/100-Q-A-CyberSecurity",
    },

    {
        "question": "What is the purpose of encryption?",
        "option_a": "To convert information into a form that unauthorized people cannot easily understand",
        "option_b": "To increase the physical storage capacity of a computer",
        "option_c": "To remove unnecessary files",
        "option_d": "To make a network physically faster",
        "correct_answer": "A",
        "difficulty": 2,
        "topic": "Encryption",
        "explanation": "Encryption transforms readable data into ciphertext so that unauthorized users cannot easily understand it.",
        "question_type": "permanent",
        "status": "approved",
        "source": "Scribd reference",
        "source_url": "https://www.scribd.com/document/724774235/100-Q-A-CyberSecurity",
    },

    {
        "question": "What is antivirus software primarily designed to do?",
        "option_a": "Increase internet bandwidth",
        "option_b": "Detect and help remove malicious software",
        "option_c": "Create network cables",
        "option_d": "Replace a firewall",
        "correct_answer": "B",
        "difficulty": 2,
        "topic": "Antivirus",
        "explanation": "Antivirus software helps detect, prevent, and remove malicious software.",
        "question_type": "permanent",
        "status": "approved",
        "source": "Scribd reference",
        "source_url": "https://www.scribd.com/document/724774235/100-Q-A-CyberSecurity",
    },


    # =========================
    # LEVEL 3 - HARD
    # =========================

    {
        "question": "A web application places user input directly into a database query without proper validation. What attack could exploit this weakness?",
        "option_a": "Phishing",
        "option_b": "DDoS",
        "option_c": "SQL injection",
        "option_d": "Brute-force attack",
        "correct_answer": "C",
        "difficulty": 3,
        "topic": "SQL Injection",
        "explanation": "SQL injection can occur when untrusted input is incorporated into database queries without proper protection.",
        "question_type": "permanent",
        "status": "approved",
        "source": "Scribd reference",
        "source_url": "https://www.scribd.com/document/724774235/100-Q-A-CyberSecurity",
    },

    {
        "question": "An attacker inserts malicious JavaScript into content displayed by a website to other users. What type of attack is this?",
        "option_a": "Distributed Denial-of-Service",
        "option_b": "Cross-Site Scripting (XSS)",
        "option_c": "Password spraying",
        "option_d": "Network sniffing",
        "correct_answer": "B",
        "difficulty": 3,
        "topic": "XSS",
        "explanation": "Cross-Site Scripting occurs when attackers cause malicious scripts to execute in another user's browser.",
        "question_type": "permanent",
        "status": "approved",
        "source": "Scribd reference",
        "source_url": "https://www.scribd.com/document/724774235/100-Q-A-CyberSecurity",
    },

    {
        "question": "An attacker sends false ARP messages on a local network to associate their MAC address with another device's IP address. What attack is being performed?",
        "option_a": "Man-in-the-Middle",
        "option_b": "ARP spoofing",
        "option_c": "Phishing",
        "option_d": "Ransomware",
        "correct_answer": "B",
        "difficulty": 3,
        "topic": "ARP Spoofing",
        "explanation": "ARP spoofing involves sending forged ARP information to associate an attacker's MAC address with another IP address.",
        "question_type": "permanent",
        "status": "approved",
        "source": "Scribd reference",
        "source_url": "https://www.scribd.com/document/724774235/100-Q-A-CyberSecurity",
    },

    {
        "question": "A company wants a security system that can detect malicious network traffic and automatically take action to block it. Which technology is most appropriate?",
        "option_a": "IDS",
        "option_b": "Antivirus",
        "option_c": "VPN",
        "option_d": "IPS",
        "correct_answer": "D",
        "difficulty": 3,
        "topic": "IDS and IPS",
        "explanation": "An IPS can detect suspicious traffic and take preventive action, such as blocking the traffic.",
        "question_type": "permanent",
        "status": "approved",
        "source": "Scribd reference",
        "source_url": "https://www.scribd.com/document/724774235/100-Q-A-CyberSecurity",
    },

    {
        "question": "A user's files suddenly become encrypted, and a message demands payment in exchange for restoring access. What type of malware is most likely responsible?",
        "option_a": "Ransomware",
        "option_b": "Spyware",
        "option_c": "Adware",
        "option_d": "Rootkit",
        "correct_answer": "A",
        "difficulty": 3,
        "topic": "Ransomware",
        "explanation": "Ransomware is malware that can encrypt or otherwise deny access to data and demand payment from the victim.",
        "question_type": "permanent",
        "status": "approved",
        "source": "Scribd reference",
        "source_url": "https://www.scribd.com/document/724774235/100-Q-A-CyberSecurity",
    },


    # =========================
    # LEVEL 4 - VERY HARD
    # =========================

    {
        "question": "A vulnerability is discovered in a company's software, but no security patch is available yet. Attackers are already exploiting it. What is this situation commonly called?",
        "option_a": "Zero-day vulnerability",
        "option_b": "Brute-force attack",
        "option_c": "Backup failure",
        "option_d": "Password expiration",
        "correct_answer": "A",
        "difficulty": 4,
        "topic": "Zero-Day",
        "explanation": "A zero-day vulnerability is a security flaw that is unknown or has not yet been addressed with an available patch when exploitation occurs.",
        "question_type": "permanent",
        "status": "approved",
        "source": "Scribd reference",
        "source_url": "https://www.scribd.com/document/724774235/100-Q-A-CyberSecurity",
    },

    {
        "question": "An attacker secretly intercepts communication between two parties and can potentially modify the information being exchanged. What type of attack is this?",
        "option_a": "Password spraying",
        "option_b": "DDoS attack",
        "option_c": "SQL injection",
        "option_d": "Man-in-the-Middle attack",
        "correct_answer": "D",
        "difficulty": 4,
        "topic": "Man-in-the-Middle",
        "explanation": "A Man-in-the-Middle attack occurs when an attacker intercepts communication between two parties.",
        "question_type": "permanent",
        "status": "approved",
        "source": "Scribd reference",
        "source_url": "https://www.scribd.com/document/724774235/100-Q-A-CyberSecurity",
    },

    {
        "question": "A security team wants to collect and analyze logs from firewalls, servers, endpoints, and other systems in one platform to identify suspicious activity. Which technology is designed for this purpose?",
        "option_a": "Antivirus",
        "option_b": "VPN",
        "option_c": "SIEM",
        "option_d": "File compression",
        "correct_answer": "C",
        "difficulty": 4,
        "topic": "SIEM",
        "explanation": "A SIEM collects and analyzes security-related data from multiple sources to help detect and investigate suspicious activity.",
        "question_type": "permanent",
        "status": "approved",
        "source": "Scribd reference",
        "source_url": "https://www.scribd.com/document/724774235/100-Q-A-CyberSecurity",
    },

    {
        "question": "A company uses firewalls, endpoint protection, MFA, network monitoring, and backups instead of relying on only one security control. What security principle does this demonstrate?",
        "option_a": "Defense in depth",
        "option_b": "Single sign-on",
        "option_c": "Data compression",
        "option_d": "Network segmentation",
        "correct_answer": "A",
        "difficulty": 4,
        "topic": "Defense in Depth",
        "explanation": "Defense in depth uses multiple layers of security controls so that one failed control does not expose the entire system.",
        "question_type": "permanent",
        "status": "approved",
        "source": "Scribd reference",
        "source_url": "https://www.scribd.com/document/724774235/100-Q-A-CyberSecurity",
    },

    {
        "question": "A company separates its employee network from its critical server network so that a compromised employee computer cannot directly access all critical systems. What security technique is being used?",
        "option_a": "Firewall",
        "option_b": "Network segmentation",
        "option_c": "Encryption",
        "option_d": "Password hashing",
        "correct_answer": "B",
        "difficulty": 4,
        "topic": "Network Segmentation",
        "explanation": "Network segmentation divides a network into separate sections to limit access and reduce the spread of attacks.",
        "question_type": "permanent",
        "status": "approved",
        "source": "Scribd reference",
        "source_url": "https://www.scribd.com/document/724774235/100-Q-A-CyberSecurity",
    },


    # =========================
    # LEVEL 5 - EXTREME
    # =========================

    {
        "question": "A security team notices thousands of failed login attempts against several employee accounts, followed by successful logins from unusual locations. Which activity should the team investigate first?",
        "option_a": "Printer configuration",
        "option_b": "Normal software installation",
        "option_c": "Routine file backup",
        "option_d": "Possible credential attack or account compromise",
        "correct_answer": "D",
        "difficulty": 5,
        "topic": "Account Security",
        "explanation": "A large number of failed logins followed by unusual successful logins can indicate a credential attack or compromised accounts.",
        "question_type": "permanent",
        "status": "approved",
        "source": "Scribd reference",
        "source_url": "https://www.scribd.com/document/724774235/100-Q-A-CyberSecurity",
    },

    {
        "question": "A company's web server has been compromised through a vulnerable application. The attacker may now access sensitive internal resources from the server. Which control would BEST reduce the attacker's ability to move to other systems?",
        "option_a": "Network segmentation",
        "option_b": "Increasing monitor resolution",
        "option_c": "Disabling screen savers",
        "option_d": "Increasing hard-drive capacity",
        "correct_answer": "A",
        "difficulty": 5,
        "topic": "Network Security",
        "explanation": "Network segmentation can limit communication between systems and reduce an attacker's ability to move laterally after compromising one system.",
        "question_type": "permanent",
        "status": "approved",
        "source": "Scribd reference",
        "source_url": "https://www.scribd.com/document/724774235/100-Q-A-CyberSecurity",
    },

    {
        "question": "A company wants to reduce the impact of ransomware. Which combination provides the strongest protection among the following choices?",
        "option_a": "A single antivirus installation",
        "option_b": "Backups, endpoint protection, network segmentation, and user awareness",
        "option_c": "One shared administrator password",
        "option_d": "Disabling all system logs",
        "correct_answer": "B",
        "difficulty": 5,
        "topic": "Ransomware Protection",
        "explanation": "Multiple layers including reliable backups, endpoint protection, segmentation, and security awareness can reduce both the likelihood and impact of ransomware.",
        "question_type": "permanent",
        "status": "approved",
        "source": "Scribd reference",
        "source_url": "https://www.scribd.com/document/724774235/100-Q-A-CyberSecurity",
    },

    {
        "question": "A company detects that an attacker has gained access to an employee account. What should the security team do FIRST?",
        "option_a": "Publish the incident on social media",
        "option_b": "Delete every server in the company",
        "option_c": "Immediately understand and contain the incident according to the organization's incident-response process",
        "option_d": "Ignore the event until more users are affected",
        "correct_answer": "C",
        "difficulty": 5,
        "topic": "Incident Response",
        "explanation": "A suspected compromise should be handled through the organization's incident-response process, including appropriate investigation and containment.",
        "question_type": "permanent",
        "status": "approved",
        "source": "Scribd reference",
        "source_url": "https://www.scribd.com/document/724774235/100-Q-A-CyberSecurity",
    },

    {
        "question": "An attacker obtains an employee's password through phishing but cannot access the account because a second authentication factor is required. Which security principle is demonstrated?",
        "option_a": "Using multiple security controls to reduce the impact of a compromised credential",
        "option_b": "Eliminating the need for authentication",
        "option_c": "Relying entirely on passwords",
        "option_d": "Removing access controls from the account",
        "correct_answer": "A",
        "difficulty": 5,
        "topic": "Multi-Factor Authentication",
        "explanation": "MFA provides an additional authentication requirement, which can prevent a stolen password from being sufficient to access an account.",
        "question_type": "permanent",
        "status": "approved",
        "source": "Scribd reference",
        "source_url": "https://www.scribd.com/document/724774235/100-Q-A-CyberSecurity",
    },
]


def seed_questions():
    db = SessionLocal()

    try:
        existing_count = db.query(QuizQuestion).count()

        if existing_count > 0:
            print(f"Database already contains {existing_count} questions.")
            print("No questions were added.")
            return

        for question_data in questions:
            question = QuizQuestion(**question_data)
            db.add(question)

        db.commit()

        print(f"Successfully added {len(questions)} questions.")

    except Exception as e:
        db.rollback()
        print(f"Error adding questions: {e}")

    finally:
        db.close()


if __name__ == "__main__":
    seed_questions()