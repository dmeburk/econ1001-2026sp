#!/usr/bin/env bash
set -euo pipefail

# --- THE PATHING FIX ---
# Ensures the script always runs from the midterm2/ root directory,
# regardless of where you call it from in the terminal.
cd "$(dirname "$0")/.."

# 1. Define Paths (Relative to project root)
# Updated to match the new 'Gold Standard' folder structure
PYTHON_SCRIPT="scripts/refactor_fr_solutions.py"
SOURCE_MD="src/fr-solutions.md"
BUILD_MD="build/fr-solutions-by-problem.md"
OUTPUT_DIR="outputs"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# 2. Run the Python Refactor
echo "🐍 Step 1: Running Python refactor..."
# This script reorganizes your FR answers from 'By Version' to 'By Problem'.
python3 "$PYTHON_SCRIPT"

# 3. Compile "By Problem" PDF
echo "🎨 Step 2: Generating 'By Problem' PDF..."
# Uses the intermediate Markdown file generated in the build folder.
pandoc "$BUILD_MD" \
    -o "$OUTPUT_DIR/midterm2-FR-solutions-by-problem.pdf" \
    --pdf-engine=pdflatex \
    -V colorlinks=true \
    -V linkcolor=blue \
    --toc

# 4. Compile "By Version" PDF
echo "🎨 Step 3: Generating 'By Version' PDF..."
# Compiles the original source file located in the source/ folder.
pandoc "$SOURCE_MD" \
    -o "$OUTPUT_DIR/midterm2-FR-solutionsby-version.pdf" \
    --pdf-engine=pdflatex \
    -V geometry:margin=1in \
    -V colorlinks=true \
    -V linkcolor=blue \
    -V header-includes='\usepackage{newpxtext,newpxmath}' \
    -V title="Midterm 2 Free Response Solutions (By Version)" \
    --toc

echo "-------------------------------------------------------"
echo "✅ SUCCESS: All PDFs updated in ./$OUTPUT_DIR"