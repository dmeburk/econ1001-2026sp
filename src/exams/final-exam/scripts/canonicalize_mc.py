#!/usr/bin/env python3
import re, sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
input_file  = BASE_DIR / "src" / "mc-master.md"
output_file = BASE_DIR / "build" / "mc" / "canonical.md"
tables_file = BASE_DIR / "build" / "mc" / "tables.md"

def is_metadata_line(line: str) -> bool:
    return line.strip().startswith("**") and ":" in line

def extract_tables(lines):
    """
    Pre-pass: pull <!-- TABLE:N --> ... <!-- /TABLE --> blocks out of the
    line list. Replaces each block with a single '*(see Table N)*' line.
    Replaces <!-- TABLE_REF:N --> with '*(see Table N)*'.
    Returns (cleaned_lines, {num: [table_lines]}).
    """
    tables = {}
    out = []
    i = 0
    while i < len(lines):
        m_start = re.match(r'^\s*<!--\s*TABLE:(\d+)\s*-->\s*$', lines[i])
        if m_start:
            num = int(m_start.group(1))
            table_lines = []
            i += 1
            while i < len(lines) and not re.match(r'^\s*<!--\s*/TABLE\s*-->\s*$', lines[i]):
                table_lines.append(lines[i].rstrip())
                i += 1
            tables[num] = [l for l in table_lines if l.strip()]
        else:
            m_ref = re.match(r'^\s*<!--\s*TABLE_REF:(\d+)\s*-->\s*$', lines[i])
            if m_ref:
                out.append(f'*(see Table {m_ref.group(1)})*')
            else:
                out.append(lines[i])
        i += 1
    return out, tables

def main():
    output_file.parent.mkdir(parents=True, exist_ok=True)

    if not input_file.exists():
        print(f"❌ Missing source file: {input_file}")
        sys.exit(1)

    lines = input_file.read_text(encoding="utf-8").splitlines()

    # Pre-pass: extract TABLE blocks before normal parsing
    lines, tables = extract_tables(lines)

    if tables:
        tbl_out = []
        for num in sorted(tables.keys()):
            tbl_out += [f"## Table {num}", ""] + tables[num] + [""]
        tables_file.write_text("\n".join(tbl_out), encoding="utf-8")
        print(f"✅ Extracted {len(tables)} table(s) -> build/mc/tables.md")
    elif tables_file.exists():
        tables_file.unlink()

    # Normal parsing (unchanged)
    questions, current = [], None

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
    print(f"✅ Created: build/mc/canonical.md")

if __name__ == "__main__":
    main()
