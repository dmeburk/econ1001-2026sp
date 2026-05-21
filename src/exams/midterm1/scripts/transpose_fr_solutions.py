#!/usr/bin/env python3
"""
Transpose FR solution keys from "by version" to "by part".

Input (canonical) conventions:
- Version header:
    # Version A  <!-- [ver:A] -->
- Problem header:
    ## Problem 22  <!-- [ver:A][p:22] -->   (any heading level 2-6 is fine)
- Subparts are bullet lines with tags:
    - **(a)** Intercepts  <!-- [ver:A][p:22][a] -->
    - **(b)** ...         <!-- [ver:A][p:22][b][key:eq] -->

Output:
- # Problem 22
  - ## 22(a)
    - ### Version A
  - ## 22(b)
    - ### Version A
  ...

No LaTeX pagebreaks are inserted; handle page breaks at PDF-build time (Pandoc Lua filter).
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple

VER_RE = re.compile(r"\[ver:?\s*([A-Z])\]", re.IGNORECASE)
P_RE = re.compile(r"\[p:(\d+)\]", re.IGNORECASE)
SUBPART_RE = re.compile(r"\[(?:p:\d+)\]\[([a-z])\]", re.IGNORECASE)  # [p:22][b]
TAG_LINE_RE = re.compile(r"<!--\s*(\[[^\]]+\](?:\[[^\]]+\])*)\s*-->")

VERSION_HEADER_RE = re.compile(
    r"^\s*#\s+Version\s+([A-Z])\b.*<!--.*\[(?:ver:?\s*[A-Z])\].*-->",
    re.IGNORECASE,
)

PROBLEM_HEADER_RE = re.compile(
    r"^\s*#{2,6}\s+Problem\s+(\d+)\b.*<!--.*\[(?:ver:?\s*[A-Z])\]\[(?:p:\d+)\].*-->",
    re.IGNORECASE,
)

# Subpart bullet (your current style)
SUBPART_BULLET_RE = re.compile(
    r"^\s*-\s*\*\*\([a-z]\)\*\*.*<!--.*\[(?:ver:?\s*[A-Z])\]\[(?:p:\d+)\]\[[a-z]\].*-->",
    re.IGNORECASE,
)

# Optional fallback if you ever convert subparts to headings
SUBPART_HEADING_RE = re.compile(
    r"^\s*#{2,6}.*<!--.*\[(?:ver:?\s*[A-Z])\]\[(?:p:\d+)\]\[[a-z]\].*-->",
    re.IGNORECASE,
)

@dataclass(frozen=True)
class BlockKey:
    problem: int
    subpart: str  # 'a', 'b', ...
    version: str  # 'A', 'B', ...

def extract_tags(line: str) -> Tuple[Optional[str], Optional[int], Optional[str]]:
    m = TAG_LINE_RE.search(line)
    if not m:
        return (None, None, None)
    tags = m.group(1)

    ver = VER_RE.search(tags)
    prob = P_RE.search(tags)
    sub = SUBPART_RE.search(tags)

    v = ver.group(1).upper() if ver else None
    p = int(prob.group(1)) if prob else None
    s = sub.group(1).lower() if sub else None
    return (v, p, s)

def is_subpart_start(line: str) -> bool:
    return bool(SUBPART_BULLET_RE.match(line) or SUBPART_HEADING_RE.match(line))

def clean_visible_text(line: str) -> str:
    """
    For bullets like '- **(a)** Intercepts <!-- ... -->', return '(a) Intercepts'.
    For headings, return heading text. Strips tags.
    """
    s = line.rstrip("\n")
    s = re.sub(r"\s*<!--.*?-->\s*", "", s).strip()
    s = re.sub(r"^\s*-\s*", "", s)
    s = re.sub(r"^\s*#{1,6}\s*", "", s)
    s = re.sub(r"\*\*\((?P<sp>[a-z])\)\*\*", r"(\g<sp>)", s, flags=re.IGNORECASE)
    return s.strip()

def main() -> int:
    if len(sys.argv) != 3:
        print(
            "Usage: transpose-fr-solutions-by-part.py <input_by_version.md> <output_by_part.md>",
            file=sys.stderr,
        )
        return 2

    in_path = Path(sys.argv[1]).expanduser()
    out_path = Path(sys.argv[2]).expanduser()

    text = in_path.read_text(encoding="utf-8")
    lines = text.splitlines(keepends=True)

    # Preserve everything before the first Version header as "front matter"/preamble.
    first_ver_idx: Optional[int] = None
    for i, ln in enumerate(lines):
        if VERSION_HEADER_RE.match(ln):
            first_ver_idx = i
            break

    front = lines[:first_ver_idx] if first_ver_idx is not None else []
    body = lines[first_ver_idx:] if first_ver_idx is not None else lines

    blocks: Dict[BlockKey, List[str]] = {}
    current_version: Optional[str] = None
    current_problem: Optional[int] = None

    i = 0
    while i < len(body):
        ln = body[i]

        mv = VERSION_HEADER_RE.match(ln)
        if mv:
            current_version = mv.group(1).upper()
            current_problem = None
            i += 1
            continue

        mp = PROBLEM_HEADER_RE.match(ln)
        if mp:
            current_problem = int(mp.group(1))
            i += 1
            continue

        if is_subpart_start(ln):
            v, p, s = extract_tags(ln)
            v = v or current_version
            p = p or current_problem

            if v is None or p is None or s is None:
                i += 1
                continue

            start = i
            j = i + 1
            while j < len(body):
                if (
                    VERSION_HEADER_RE.match(body[j])
                    or PROBLEM_HEADER_RE.match(body[j])
                    or is_subpart_start(body[j])
                ):
                    break
                j += 1

            key = BlockKey(problem=p, subpart=s, version=v)
            blocks[key] = body[start:j]
            i = j
            continue

        i += 1

    if not blocks:
        print(
            "No subpart blocks found. Expected tagged subparts like:\n"
            "  - **(b)** ... <!-- [ver:A][p:22][b] -->\n",
            file=sys.stderr,
        )
        return 1

    problems = sorted({k.problem for k in blocks.keys()})
    versions = sorted({k.version for k in blocks.keys()})

    out: List[str] = []
    out.extend(front)
    if out and not out[-1].endswith("\n"):
        out[-1] += "\n"

    for p in problems:
        out.append(f"\n# Problem {p}\n\n")

        subparts = sorted({k.subpart for k in blocks.keys() if k.problem == p})
        for s in subparts:
            out.append(f"## {p}({s})\n\n")

            for v in versions:
                key = BlockKey(problem=p, subpart=s, version=v)
                if key not in blocks:
                    continue

                out.append(f"### Version {v}\n\n")

                block_lines = blocks[key]
                label = clean_visible_text(block_lines[0])
                if label:
                    out.append(f"**{label}**\n\n")

                out.extend(block_lines[1:])

                if out and not out[-1].endswith("\n"):
                    out.append("\n")
                out.append("\n")

    out_path.write_text("".join(out), encoding="utf-8")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())