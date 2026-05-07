# Final Exam Publishing Pipeline

## Commands

```bash
# Iterate on MC questions (src/mc-master.md)
bash scripts/draft.sh mc A --pdf

# Iterate on FR question (src/fr-questions.tex, src/fr_params.csv)
bash scripts/draft.sh fr A --pdf

# Build all five versions → outputs/
bash scripts/publish_exam.sh
```

`draft.sh` accepts a version letter (A–E, defaults to A) and an optional `--pdf` flag.
Without `--pdf` it stops at the assembled `.tex` file.

FR mode produces a standalone FR-only PDF — no MC — for inspecting the question
in isolation. Run `draft.sh mc A` at least once before using FR mode.

---

## Source files (`src/`)

| File | What it is |
|---|---|
| `mc-master.md` | MC question bank with correct answers |
| `mc_version_order.csv` | Question order for each version (A–E) |
| `fr-questions.tex` | FR question text with `[[PLACEHOLDERS]]` |
| `fr_params.csv` | Version-specific equation values |
| `exam-template.tex` | LaTeX document skeleton |
| `fr-standalone-template.tex` | Minimal LaTeX skeleton for FR-only preview |
| `back-page.tex` | Back page content |

---

## Pipeline stages

Run automatically by `publish_exam.sh` and `draft.sh`.

| Script | What it does |
|---|---|
| `extract_mc_key.py` | Extracts the canonical answer key from `mc-master.md` |
| `canonicalize_mc.py` | Cleans MC questions, extracts tables → `build/mc/` |
| `shuffle_mc.py` | Reorders and shuffles choices for each version → `build/mc/` |
| `build_fr_tex.py` | Substitutes parameters into FR template → `build/fr/` |
| `build_exam_tex.py` | Assembles full exam `.tex` from MC + FR + template → `build/tex/` |

---

## Build directory (`build/`)

```
build/
├── mc/           processed MC markdown, tables, answer keys
├── fr/           versioned FR .tex snippets
├── tex/          assembled exam .tex files
└── pdf/          compiled PDFs (+ latexmk artifacts)
```

---

## Outputs (`outputs/`)

```
outputs/
├── final-exam-A.pdf  …  final-exam-E.pdf
└── mc_answer_key.csv
```
