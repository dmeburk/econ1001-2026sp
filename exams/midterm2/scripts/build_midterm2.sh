#!/usr/bin/env bash

# ------------------------------------------------------------
# THE EXECUTIVE CHEF: Exam Pipeline (ECON-1001 S26 Edition)
# ------------------------------------------------------------

set -euo pipefail

# --- CONFIGURATION ---
EXAM_SLUG="midterm2"
SEMESTER="S26"
SEED=42
VERSIONS=(A B C D E)

# RESOLVE PATHS
# Script lives in _internal/automation/, so we go up two levels to root
REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

# The Garage
SCRIPTS_DIR="$REPO_ROOT/_internal/automation/exams"
KITCHEN_DIR="$REPO_ROOT/_internal/kitchen/exams/$EXAM_SLUG"
RECORDS_DIR="$REPO_ROOT/_internal/records/$SEMESTER/exams/$EXAM_SLUG"

# The Desk
SRC_DIR="$REPO_ROOT/econ1001-desk/exams/$EXAM_SLUG"

# The Storefront
PUBLISHED_DIR="$REPO_ROOT/published/exams"

echo "👨‍🍳 Starting the Kitchen for: $EXAM_SLUG ($SEMESTER)"

# Ensure directories exist
mkdir -p "$KITCHEN_DIR/cooking" "$KITCHEN_DIR/finished"
mkdir -p "$RECORDS_DIR/source_snapshot" "$RECORDS_DIR/versions"
mkdir -p "$PUBLISHED_DIR"

# ------------------------------------------------------------
# 1. PREP & ARCHIVE SOURCE
# ------------------------------------------------------------
echo "▶ Archiving current source from Desk..."
# We snapshot the .md files before we mess with them
cp "$SRC_DIR"/*.md "$RECORDS_DIR/source_snapshot/"

echo "▶ Extracting Master Key..."
python3 "$SCRIPTS_DIR/mc-finalized-to-canonical-key.py" "$EXAM_SLUG"

echo "▶ Cleaning Markdown (Canonicalizing)..."
python3 "$SCRIPTS_DIR/mc-finalized-to-canonical.py" "$EXAM_SLUG"

# ------------------------------------------------------------
# 2. SOUS-CHEF: SHUFFLING & PLATING
# ------------------------------------------------------------
echo "▶ Shuffling versions (Seed: $SEED)..."
python3 "$SCRIPTS_DIR/shuffle-canonical-mc.py" "$EXAM_SLUG" \
  --versions "${VERSIONS[@]}" \
  --seed "$SEED"

echo "▶ Generating Randomized Free Response Files..."
python3 "$SCRIPTS_DIR/generate-fr-tex.py" "$EXAM_SLUG"

echo "▶ Generating LaTeX source..."
for v in "${VERSIONS[@]}"; do
  echo "  • Plating Version $v"
  python3 "$SCRIPTS_DIR/build-mc-tex.py" "$EXAM_SLUG" "$v"
done

# ------------------------------------------------------------
# 3. THE OVEN: COMPILING PDFS
# ------------------------------------------------------------
echo "▶ Compiling PDFs (Oven Temp: High)..."
cd "$KITCHEN_DIR/cooking"

for v in "${VERSIONS[@]}"; do
  echo "  • Baking mc_$v.pdf"
  latexmk -pdf \
    -interaction=nonstopmode \
    -silent \
    -output-directory="../finished" \
    "mc_${v}.tex"
done

cd "$REPO_ROOT"

# ------------------------------------------------------------
# 4. THE SERVING WINDOW: PUBLISHING & ARCHIVING
# ------------------------------------------------------------
echo "▶ Finalizing Answer Sheets & Serving..."

# Build the Answer Sheet (Using assets from the internal garage)
BUBBLE="$REPO_ROOT/_internal/automation/assets/bubble-sheet.pdf"
FRPAGE="$SRC_DIR/free-response-answer-page.pdf"
OUT_AS="$KITCHEN_DIR/finished/${EXAM_SLUG}_answer_sheet.pdf"

if [[ -f "$BUBBLE" && -f "$FRPAGE" ]]; then
  pdfunite "$BUBBLE" "$FRPAGE" "$OUT_AS"
  cp "$OUT_AS" "$PUBLISHED_DIR/"
  cp "$OUT_AS" "$RECORDS_DIR/versions/"
  echo "  ✅ Answer sheet served."
fi

# TRIPLE-SAVE: Kitchen -> Published -> Records
for v in "${VERSIONS[@]}"; do
  # 1. Move from Kitchen to Published (Storefront)
  cp "$KITCHEN_DIR/finished/mc_$v.pdf" "$PUBLISHED_DIR/${EXAM_SLUG}_version_${v}.pdf"
  
  # 2. Move from Kitchen to Records (The Vault)
  cp "$KITCHEN_DIR/finished/mc_$v.pdf" "$RECORDS_DIR/versions/${EXAM_SLUG}_version_${v}.pdf"
  
  echo "  🚀 Served & Archived: Version $v"
done

echo "🎉 Midterm 2 complete. Master copy saved in Records/$SEMESTER."