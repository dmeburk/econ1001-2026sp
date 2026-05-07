#!/usr/bin/env python3

import re
import sys
from pathlib import Path

# Matches "## Q01" or "## Question 1"
QUESTION_HEADER = re.compile(
    r"^##\s+(?:Q|Question)\s*(\d+)\b",
    re.IGNORECASE
)

# Matches "**Correct answer:** C"
# Updated regex to catch the bold tags at the very end of the line
CORRECT_ANSWER = re.compile(
    r"^\*\*\s*Correct answer\s*:?\s*(?:\*\*)?\s*([A-Ea-e])\s*(?:\*\*)?\s*$",
    re.IGNORECASE
)

def main():
    # --- STANDARDIZED PATHING ---
    # Anchors to project root (midterm2/) regardless of where it is run
    BASE_DIR = Path(__file__).resolve().parent.parent
    BUILD_DIR = BASE_DIR / "build"
    
    # Redirected to look in 'source/' folder
    input_file = BASE_DIR / "src" / "mc-questions.md"
    
    output_dir = BUILD_DIR / "mc" / "keys"
    output_file = output_dir / "canonical_key.csv"

    if not input_file.exists():
        print(f"❌ Error: Missing {input_file}")
        sys.exit(1)

    lines = input_file.read_text(encoding="utf-8").splitlines()

    answers = []
    current_q = None
    found_answer_for_current = False

    # --- YOUR ORIGINAL LOGIC (UNCHANGED) ---
    def finalize_question(qnum: str | None):
        if qnum is None:
            return
        if not found_answer_for_current:
            raise ValueError(f"Question Q{qnum} is missing a '**Correct answer:** X' line.")

    for line in lines:
        m_q = QUESTION_HEADER.match(line.strip())
        if m_q:
            finalize_question(current_q)
            current_q = m_q.group(1)
            found_answer_for_current = False
            continue

        m_a = CORRECT_ANSWER.match(line.strip())
        if m_a and current_q is not None:
            if found_answer_for_current:
                raise ValueError(f"Question Q{current_q} has more than one correct-answer line.")
            answers.append(m_a.group(1).lower())
            found_answer_for_current = True

    finalize_question(current_q)

    if not answers:
        raise ValueError("No answers found. Check if your Markdown uses '**Correct answer:** X'.")

    output_dir.mkdir(parents=True, exist_ok=True)
    output_file.write_text("\n".join(answers) + "\n", encoding="utf-8")

    print(f"✅ Master Key extracted: {len(answers)} questions -> build/mc/keys/canonical_key.csv")

if __name__ == "__main__":
    main()