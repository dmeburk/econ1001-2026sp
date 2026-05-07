#!/usr/bin/env python3
import argparse, csv, random, re
from pathlib import Path
from dataclasses import dataclass
from typing import Dict, List, Tuple

# ---------------------------------------------------------
# ANCHOR PATHING
# ---------------------------------------------------------
# Anchors the script to the project root (midterm2/)
BASE_DIR = Path(__file__).resolve().parent.parent
INPUTS_DIR = BASE_DIR / "src"
BUILD_DIR = BASE_DIR / "build"

# ---------------------------------------------------------
# REGEX & DATASTRUCTURES
# ---------------------------------------------------------
QHEADER_RE = re.compile(r"^##\s+Question\s+(\d+)\s*$", re.IGNORECASE)
OPT_RE = re.compile(r"^-\s*([a-z])\.\s*(.*)$", re.IGNORECASE)

@dataclass
class Question:
    qnum: int
    stem_lines: List[str]
    options: List[Tuple[str, str]]

# ---------------------------------------------------------
# HELPER FUNCTIONS (The missing pieces)
# ---------------------------------------------------------

def split_canonical(md_text: str) -> Tuple[str, List[str]]:
    """Splits the canonical markdown into a header and individual question blocks."""
    blocks = re.split(r"(?=^##\s+Question\s+\d+\s*$)", md_text, flags=re.M | re.I)
    return blocks[0].strip(), blocks[1:]

def parse_question_block(block: str) -> Question:
    """Parses a single question block into a Question dataclass."""
    lines = [ln.rstrip() for ln in block.strip().splitlines()]
    m = QHEADER_RE.match(lines[0])
    if not m:
        raise ValueError(f"Could not parse header: {lines[0]}")
    
    qnum = int(m.group(1))
    # Find where options start
    try:
        opt_start = next(i for i, ln in enumerate(lines[1:], 1) if OPT_RE.match(ln.strip()))
    except StopIteration:
        raise ValueError(f"No options found for Question {qnum}")

    stem_lines = lines[1:opt_start]
    options = []
    for ln in [l.strip() for l in lines[opt_start:] if l.strip()]:
        m_opt = OPT_RE.match(ln)
        if m_opt: 
            options.append((m_opt.group(1).lower(), m_opt.group(2).strip()))
            
    return Question(qnum=qnum, stem_lines=stem_lines, options=options)

def load_master_key(path: Path) -> Dict[int, str]:
    """Loads the canonical answer key from CSV."""
    key = {}
    with path.open(newline="", encoding="utf-8") as f:
        rows = [row for row in csv.reader(f) if row and row[0].strip()]
    for i, row in enumerate(rows, start=1):
        key[i] = row[0].strip().lower()
    return key

def shuffle_question(q: Question, correct_letter: str, rng: random.Random):
    """Randomizes the order of choices while tracking the correct answer."""
    shuffled = q.options[:]
    rng.shuffle(shuffled)
    mapping = {old: chr(ord("a")+i) for i, (old, txt) in enumerate(shuffled)}
    new_opts = [(mapping[old], txt) for old, txt in shuffled]
    new_opts.sort()
    return Question(q.qnum, q.stem_lines, new_opts), mapping[correct_letter]

def render_question(display_num: int, q: Question) -> str:
    """Formats the Question dataclass back into Markdown."""
    out = [f"## Question {display_num}", ""]
    out.extend(q.stem_lines)
    out.append("")
    for letter, text in q.options:
        out.append(f"- {letter}. {text}")
    out.append("")
    return "\n".join(out)

# ---------------------------------------------------------
# MAIN PIPELINE
# ---------------------------------------------------------

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--versions", nargs="+", default=["A", "B", "C", "D", "E"])
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--dry-run", action="store_true", help="Parse and report without writing files")
    args = ap.parse_args()

    # Paths anchored to the Gold Standard structure
    canonical_path = BUILD_DIR / "mc" / "canonical.md"
    master_key_path = BUILD_DIR / "mc" / "keys" / "canonical_key.csv"
    version_order_path = INPUTS_DIR / "mc_version_order.csv"
    shuffled_dir = BUILD_DIR / "mc"
    keys_dir = BUILD_DIR / "mc" / "keys"

    if not canonical_path.exists():
        print(f"❌ Error: Missing {canonical_path}")
        return

    # Load content and key
    md_text = canonical_path.read_text(encoding="utf-8")
    header_text, blocks = split_canonical(md_text)
    q_by_num = {q.qnum: q for q in [parse_question_block(b) for b in blocks]}
    master_key = load_master_key(master_key_path)

    # Process version ordering
    with version_order_path.open(newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    version_orders = {}
    for col in (rows[0].keys() if rows else []):
        key = col.strip().upper().replace("VERSION_", "").replace("VERSION", "").strip()
        version_orders[key] = [int(row[col]) for row in rows if row[col].strip()]

    answer_table = {}
    for v in args.versions:
        rng = random.Random(f"{args.seed}-{v}")
        order = version_orders[v]
        out_lines = [header_text, ""] if header_text else []
        version_key = []

        for display_i, qnum in enumerate(order, start=1):
            q = q_by_num[qnum]

            if v == "A":
                # Version A is the unshuffled control
                new_q = q
                new_correct = master_key[qnum]
            else:
                # Scramble for other versions
                new_q, new_correct = shuffle_question(q, master_key[qnum], rng)

            answer_table.setdefault(display_i, {})[v] = new_correct.upper()
            version_key.append(new_correct.upper())
            out_lines.append(render_question(display_i, new_q))

        if not args.dry_run:
            shuffled_dir.mkdir(parents=True, exist_ok=True)
            keys_dir.mkdir(parents=True, exist_ok=True)
            (shuffled_dir / f"mc_{v}.md").write_text("\n".join(out_lines).rstrip() + "\n", encoding="utf-8")
            (keys_dir / f"key_{v}.csv").write_text("\n".join(version_key) + "\n", encoding="utf-8")
            print(f"✅ Prepared version {v}")

    # Generate the consolidated key for Scantron/LMS
    if not args.dry_run:
        output_master_key = keys_dir / "final_answer_key.csv"
        with output_master_key.open("w", newline="", encoding="utf-8") as f:
            w = csv.writer(f)
            w.writerow(["Problem"] + [f"Version {v}" for v in args.versions])
            for i in sorted(answer_table.keys()):
                row = [i]
                for v in args.versions:
                    row.append(answer_table[i].get(v, ""))
                w.writerow(row)
        
        print(f"🗝️  Master Answer Key created: {output_master_key}")

if __name__ == "__main__":
    main()