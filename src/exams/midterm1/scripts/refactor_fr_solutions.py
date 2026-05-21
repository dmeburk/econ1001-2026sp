#!/usr/bin/env python3
"""
refactor-fr-solutions-by-problem.py

Transform the "by-version" FR solutions markdown into a "by-problem-part" view.

------------------------------------------------------------
WHAT IT DOES
------------------------------------------------------------
- Reads a markdown file containing one block delimited by:
    <!-- SOLUTIONS_FR_KEYS_START -->
    ...
    <!-- SOLUTIONS_FR_KEYS_END -->

- Inside that block, it expects solution chunks tagged in HTML comments like:
    <!-- [ver:A][p:22][a] -->
    <!-- [ver:B][p:23][b][key:alloc] -->

- It preserves the original chunk text verbatim, and rewrites the view as:
    Problem -> Part -> Version (only versions present)

------------------------------------------------------------
USAGE
------------------------------------------------------------

Recommended (exam-name mode; matches your pipeline style):
    python midterm1/tools/refactor-fr-solutions-by-problem.py midterm1

This assumes:
    midterm1/building/inputs/solutions/fr-solutions-source.md

and writes:
    midterm1/building/intermediates/solutions/fr-solutions-by-part.md

Path mode (explicit input file):
    python midterm1/tools/refactor-fr-solutions-by-problem.py \
      midterm1/building/inputs/solutions/fr-solutions-source.md

Optional output override:
    python midterm1/tools/refactor-fr-solutions-by-problem.py midterm1 \
      -o midterm1/building/outputs/fr-solutions-by-part.md

Dry run (parse + report only; no writes):
    python midterm1/tools/refactor-fr-solutions-by-problem.py midterm1 --dry-run

------------------------------------------------------------
NOTES
------------------------------------------------------------
- Assumes each (version, problem, part) appears at most once.
- Ignores [key:*] tags for grouping (they remain in the text).
"""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple


START = "<!-- SOLUTIONS_FR_KEYS_START -->"
END = "<!-- SOLUTIONS_FR_KEYS_END -->"

# Capture tags like [ver:A], [p:22], [a], [key:eq]
TAG_RE = re.compile(r"\[([^\]]+)\]")


@dataclass(frozen=True)
class Key:
    ver: str        # "A".."E"
    prob: str       # "22", "23", ...
    part: str       # "a", "b", ...
    # we ignore key:* tags for grouping; they stay in text


# ------------------------------------------------------------
# Path helpers
# ------------------------------------------------------------
def repo_root_from_this_file() -> Path:
    """
    If this script lives at:
      midterm1/tools/refactor-fr-solutions-by-problem.py
    then repo root is one level above midterm1.
    """
    # .../midterm1/tools/script.py -> parents[2] is repo root
    return Path(__file__).resolve().parents[2]


def default_input_for_exam(exam_name: str) -> Path:
    rr = repo_root_from_this_file()
    return rr / exam_name / "building" / "inputs" / "solutions" / "fr-solutions-source.md"


def default_output_for_exam(exam_name: str) -> Path:
    rr = repo_root_from_this_file()
    return rr / exam_name / "building" / "intermediates" / "solutions" / "fr-solutions-by-part.md"


def resolve_input(arg: str) -> Tuple[str, Path]:
    """
    If arg is an existing file path -> path mode.
    Else -> treat as exam_name.
    Returns (mode, path).
    """
    p = Path(arg)
    if p.exists() and p.is_file():
        return ("path", p.resolve())

    exam_name = arg
    inp = default_input_for_exam(exam_name)
    return ("exam", inp)


# ------------------------------------------------------------
# Block extraction + parsing
# ------------------------------------------------------------
def extract_block(text: str) -> str:
    i = text.find(START)
    j = text.find(END)
    if i == -1 or j == -1 or j <= i:
        raise ValueError("Could not find SOLUTIONS_FR_KEYS_START/END block.")
    return text[i : j + len(END)]


def parse_chunks(block: str) -> Dict[Key, str]:
    """
    Collect segments starting at lines that contain a full chunk identifier
    in tags: [ver:*][p:*][<letter>].

    Preserves chunk text verbatim (including the tag line).
    """
    lines = block.splitlines(keepends=True)

    cur_key: Optional[Key] = None
    cur_buf: List[str] = []
    chunks: Dict[Key, str] = {}

    def flush() -> None:
        nonlocal cur_key, cur_buf
        if cur_key is None:
            return
        text = "".join(cur_buf).rstrip() + "\n"
        if cur_key in chunks:
            raise ValueError(f"Duplicate chunk for {cur_key}")
        chunks[cur_key] = text
        cur_key = None
        cur_buf = []

    for ln in lines:
        if "<!--" in ln and "[" in ln and "]" in ln:
            tags = TAG_RE.findall(ln)

            found_ver = None
            found_prob = None
            found_part = None

            for t in tags:
                if t.lower().startswith("ver:"):
                    found_ver = t.split(":", 1)[1].strip().upper()
                elif t.lower().startswith("p:"):
                    found_prob = t.split(":", 1)[1].strip()
                elif re.fullmatch(r"[a-zA-Z]", t.strip()):
                    found_part = t.strip().lower()

            if found_ver and found_prob and found_part:
                flush()
                cur_key = Key(ver=found_ver, prob=found_prob, part=found_part)
                cur_buf.append(ln)
                continue

        if cur_key is not None:
            cur_buf.append(ln)

    flush()
    return chunks


def all_probs_parts(chunks: Dict[Key, str]) -> Tuple[List[str], List[str], List[str]]:
    probs = sorted({k.prob for k in chunks}, key=lambda x: int(x) if x.isdigit() else x)
    parts = sorted({k.part for k in chunks})
    vers = sorted({k.ver for k in chunks})
    return probs, parts, vers


def render_by_part(
    chunks: Dict[Key, str],
    title: str = "Free Response Solution Keys (by problem part)",
) -> str:
    probs, _, vers = all_probs_parts(chunks)

    out: List[str] = []
    out.append(START)
    out.append("")
    out.append(f"# {title}")
    out.append("")
    out.append("---")
    out.append("")

    for p in probs:
        out.append(f"## Problem {p}")
        out.append("")
        p_parts = sorted({k.part for k in chunks if k.prob == p})
        for part in p_parts:
            out.append(f"### ({part})")
            out.append("")
            for v in vers:
                k = Key(ver=v, prob=p, part=part)
                if k not in chunks:
                    continue
                out.append(f"#### Version {v}")
                out.append("")
                out.append(chunks[k].rstrip())
                out.append("")
            out.append("---")
            out.append("")
        out.append("")

    out.append(END)
    out.append("")
    return "\n".join(out)


# ------------------------------------------------------------
# Main
# ------------------------------------------------------------
def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "exam_or_input",
        help="Either an exam name (e.g., 'midterm1') or a path to the input markdown file.",
    )
    ap.add_argument("-o", "--output", type=Path, default=None)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    mode, input_path = resolve_input(args.exam_or_input)

    if mode == "exam":
        exam_name = args.exam_or_input
        default_out = default_output_for_exam(exam_name)
    else:
        # Path mode: default output adjacent to input, but in intermediates if it looks like your layout.
        default_out = input_path.with_name(input_path.stem + "-by-part.md")

    if not input_path.exists():
        raise FileNotFoundError(f"Missing input file: {input_path}")

    text = input_path.read_text(encoding="utf-8")
    block = extract_block(text)
    chunks = parse_chunks(block)

    probs, parts, vers = all_probs_parts(chunks)
    print("✅ Parsed chunks:")
    print(f"  input:    {input_path}")
    print(f"  versions: {vers}")
    print(f"  problems: {probs}")
    print(f"  parts:    {parts}")
    print(f"  total chunks: {len(chunks)}")

    out_text = render_by_part(chunks)

    if args.dry_run:
        print("\n🧪 DRY RUN — no output written")
        return

    out_path = args.output if args.output is not None else default_out
    out_path = out_path.resolve()
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(out_text, encoding="utf-8")
    print(f"\n📝 Wrote: {out_path}")


if __name__ == "__main__":
    main()