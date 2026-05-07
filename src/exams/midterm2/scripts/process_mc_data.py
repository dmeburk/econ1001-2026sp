#!/usr/bin/env python3
import re, sys
from pathlib import Path

# --- THE PATHING FIX ---
# Anchors to the project root (midterm2/) regardless of where you run it.
BASE_DIR = Path(__file__).resolve().parent.parent

# Input is now pulled from the 'source' folder
input_file = BASE_DIR / "source" / "mc-finalized.md"

# Output stays in 'build' for the next step in the pipeline
output_file = BASE_DIR / "build" / "canonical" / "mc-canonical.md"

def is_metadata_line(line: str) -> bool:
    # Keeps your original logic for ignoring metadata like **Correct answer:**
    return line.strip().startswith("**") and ":" in line

def main():
    # Ensure the directory exists before writing
    output_file.parent.mkdir(parents=True, exist_ok=True)
    
    if not input_file.exists():
        print(f"❌ Missing source file: {input_file}")
        sys.exit(1)

    lines = input_file.read_text(encoding="utf-8").splitlines()
    questions, current = [], None

    # --- YOUR ORIGINAL PARSING LOGIC (UNCHANGED) ---
    for line in lines:
        if re.match(r"^##\s+Q\d+", line, re.I):
            if current: questions.append(current)
            qnum_match = re.search(r"\d+", line)
            qnum = int(qnum_match.group()) if qnum_match else 0
            current = {"qnum": qnum, "prompt": [], "choices": []}
            continue

        if current is None or is_metadata_line(line):
            continue

        m = re.match(r"^([A-Z])\)\s+(.*)$", line.strip())
        if m:
            current["choices"].append((m.group(1).lower(), m.group(2).strip()))
        elif line.strip() or current["prompt"]:
            current["prompt"].append(line.rstrip())

    if current: questions.append(current)
    questions.sort(key=lambda q: q["qnum"])

    out = []
    for i, q in enumerate(questions, start=1):
        out.extend([f"## Question {i}", "", *q["prompt"], ""])
        for letter, text in q["choices"]:
            out.append(f"- {letter}. {text}")
        out.extend(["", "---", ""])

    output_file.write_text("\n".join(out), encoding="utf-8")
    print(f"✅ Created: build/canonical/mc-canonical.md")

if __name__ == "__main__":
    main()