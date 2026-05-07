#!/usr/bin/env python3

import re
import sys
from pathlib import Path

# ---------------------------------------------------------
# SANITIZER
# ---------------------------------------------------------

def sanitize(text: str) -> str:
    # Only protect real LaTeX math: \( ... \) or unescaped $ ... $
    # Use negative lookbehind so that \$10 does NOT trigger the $ ... $ math pattern.
    math_pattern = r"(\\\(.+?\\\))|((?<!\\)\$.+?(?<!\\)\$)"
    parts = re.split(math_pattern, text)

    replacements = {
        "&": r"\&",
        "%": r"\%",
        "#": r"\#",
        "_": r"\_",
        "{": r"\{",
        "}": r"\}",
        "◊": r"\ensuremath{\diamond}",
        "♦": r"\ensuremath{\diamond}",
        "■": r"\ensuremath{\blacksquare}",
    }

    processed_parts = []
    for part in parts:
        if part is None:
            continue
        if part.startswith("\\(") or part.startswith("$"):
            processed_parts.append(part)
        else:
            for k, v in replacements.items():
                part = part.replace(k, v)
            part = re.sub(r"(?<!\\)\$", r"\\$", part)
            part = re.sub(r"\*\*(.+?)\*\*", r"\\textbf{\1}", part)
            part = re.sub(r"\*(?!\*)([^\n]+?)\*", r"\\emph{\1}", part)
            processed_parts.append(part)

    return "".join(processed_parts).strip()

# ---------------------------------------------------------
# TABLE CONVERSION
# ---------------------------------------------------------

def is_table_line(line: str) -> bool:
    return line.strip().startswith("|")

def is_table_separator(line: str) -> bool:
    cells = [c.strip() for c in line.strip().strip("|").split("|")]
    return bool(cells) and all(re.match(r"^[-: ]+$", c) for c in cells if c)

def convert_md_table(table_lines: list) -> str:
    header_row = None
    body_rows = []
    for line in table_lines:
        if is_table_separator(line):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if header_row is None:
            header_row = cells
        else:
            body_rows.append(cells)

    if not header_row:
        return ""

    col_count = max(len(header_row), max((len(r) for r in body_rows), default=0))
    col_spec = "l" * col_count

    out = [r"  \begin{center}\small", f"  \\begin{{tabular}}{{{col_spec}}}", r"  \toprule"]

    def cell(c):
        return f"\\makecell[c]{{{sanitize(c)}}}"

    padded_header = header_row + [""] * (col_count - len(header_row))
    out.append("  " + " & ".join(cell(c) for c in padded_header) + r" \\")
    out.append(r"  \midrule")

    for row in body_rows:
        padded = row + [""] * (col_count - len(row))
        out.append("  " + " & ".join(cell(c) for c in padded) + r" \\")

    out += [r"  \bottomrule", r"  \end{tabular}", r"  \end{center}"]
    return "\n".join(out)

# ---------------------------------------------------------
# TABLES SECTION BUILDER
# ---------------------------------------------------------

def build_tables_section(tables_file: Path) -> str:
    if not tables_file.exists():
        return ""

    text = tables_file.read_text(encoding="utf-8")
    # re.split with a capturing group returns [..., num, content, num, content, ...]
    parts = re.split(r"^##\s+Table\s+(\d+)\s*$", text, flags=re.MULTILINE)

    blocks = []
    i = 1
    while i + 1 < len(parts):
        num = parts[i].strip()
        content_lines = [ln for ln in parts[i + 1].splitlines() if ln.strip()]
        blocks.append((num, content_lines))
        i += 2

    if not blocks:
        return ""

    out = [r"\newpage", r"\section*{Tables}", ""]
    for i, (num, table_lines) in enumerate(blocks):
        if i > 0:
            out.append(r"\vspace{1em}")
        out.append(f"\\begin{{center}}\\textbf{{Table {num}}}\\end{{center}}")
        out.append(convert_md_table(table_lines))
        out.append("")

    return "\n".join(out)

# ---------------------------------------------------------
# QUESTION BUILDER
# ---------------------------------------------------------

def build_question_tex(stem_lines: list, choices: list) -> str:
    has_table = any(is_table_line(ln) for ln in stem_lines)
    choices_block = "  \\begin{choices}\n" + "\n".join(choices) + "\n  \\end{choices}"

    if not has_table:
        stem = sanitize(" ".join(ln for ln in stem_lines if ln.strip()))
        return f"  \\question{{{stem}}}\n{choices_block}\n"

    # For questions with embedded tables, emit \item directly so the table
    # can appear outside the \question{} macro argument.
    segments = []
    i = 0
    while i < len(stem_lines):
        ln = stem_lines[i]
        if is_table_line(ln):
            table_block = []
            while i < len(stem_lines) and is_table_line(stem_lines[i]):
                table_block.append(stem_lines[i])
                i += 1
            segments.append(("table", table_block))
        else:
            if ln.strip():
                segments.append(("text", ln.strip()))
            i += 1

    out = ["  \\Needspace{12\\baselineskip}", "  \\item"]
    for kind, data in segments:
        if kind == "text":
            out.append(f"  {sanitize(data)}")
        else:
            out.append(convert_md_table(data))
    out.append("  \\vspace{-0.3em}")
    out.append(choices_block)

    return "\n".join(out) + "\n"

# ---------------------------------------------------------
# MAIN
# ---------------------------------------------------------

def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("version")
    parser.add_argument("--no-fr", action="store_true", dest="no_fr",
                        help="Omit FR section (MC draft mode)")
    args = parser.parse_args()
    version = args.version.upper()

    BASE_DIR = Path(__file__).resolve().parent.parent
    INPUTS_DIR = BASE_DIR / "src"
    BUILD_DIR = BASE_DIR / "build"

    md_file = BUILD_DIR / "mc" / f"mc_{version}.md"
    if not md_file.exists():
        raise FileNotFoundError(f"❌ Markdown file not found: {md_file}")

    TABLES_FILE = BUILD_DIR / "mc" / "tables.md"
    tables_section = build_tables_section(TABLES_FILE)

    FR_FILE = BUILD_DIR / "fr" / f"fr_{version}.tex"
    if not args.no_fr and FR_FILE.exists():
        fr_section = (
            "% --- Free Response Section ---\n"
            "\\section*{Free Response}\n"
            "\\noindent\\emph{Write your response to the following questions on the back of the bubble sheet."
            " Show your work for partial credit. \\textbf{Box your final answer for each part.}}\n\n"
            "\\begin{questions}[resume]\n"
            f"  {FR_FILE.read_text(encoding='utf-8')}\n"
            "\\end{questions}"
        )
    else:
        fr_section = ""

    TEMPLATE = INPUTS_DIR / "exam-template.tex"
    if not TEMPLATE.exists():
        raise FileNotFoundError(f"❌ Missing LaTeX template: {TEMPLATE}")

    BACK_FILE = INPUTS_DIR / "back-page.tex"
    back_content = BACK_FILE.read_text(encoding="utf-8") if BACK_FILE.exists() else \
        "% (No back-page content found in src/)"

    out_dir = BUILD_DIR / "tex"
    out_dir.mkdir(parents=True, exist_ok=True)

    raw = md_file.read_text(encoding="utf-8")
    blocks = re.split(r"^##\s+Question\s+\d+\s*$", raw, flags=re.MULTILINE)[1:]

    questions_tex = []

    for block in blocks:
        lines = [ln.rstrip() for ln in block.strip().splitlines()]
        stem_lines = []
        choices = []

        for ln in lines:
            ln_stripped = ln.strip()
            if not ln_stripped or ln_stripped.startswith("<!--") or ln_stripped == "---":
                continue

            m = re.match(r"-\s*([a-dA-D])[.)]\s+(.*)", ln_stripped)
            if m:
                choices.append(r"    \item " + sanitize(m.group(2)))
            else:
                stem_lines.append(ln)

        if len(choices) != 4:
            continue

        questions_tex.append(build_question_tex(stem_lines, choices))

    if not questions_tex:
        raise RuntimeError("Parsed zero valid questions.")

    mc_content = "\n\n".join(questions_tex)

    template = TEMPLATE.read_text(encoding="utf-8")
    final_tex = (
        template
        .replace("VERSION_PLACEHOLDER", version)
        .replace("MC_CONTENT_PLACEHOLDER", mc_content)
        .replace("TABLES_SECTION_PLACEHOLDER", tables_section)
        .replace("FR_SECTION_PLACEHOLDER", fr_section)
        .replace("BACK_CONTENT_PLACEHOLDER", back_content)
    )

    out_name = f"mc_{version}_draft.tex" if args.no_fr else f"exam_{version}.tex"
    out_file = out_dir / out_name
    out_file.write_text(final_tex, encoding="utf-8")
    print(f"✅ Created LaTeX: build/tex/{out_name} ({len(questions_tex)} questions)")


if __name__ == "__main__":
    main()
