#!/bin/bash

###############################################################################
# PUBLISH SCRIPT: Midterm 2 Free Response Solutions
# 
# Usage: Run from 'midterm2/' directory: ./scripts/publish.sh
###############################################################################

# 1. Define Paths (Relative to midterm2/ folder)
PYTHON_SCRIPT="scripts/refactor-fr-solutions.py"
SOURCE_MD="solutions/fr_solutions.md"
BUILD_MD="solutions/build/fr-solutions-by-problem.md"
OUTPUT_DIR="solutions/outputs"

# 2. Run the Python Refactor
echo "🐍 Step 1: Running Python refactor..."
# We pass the relative path to the source file
python3 "$PYTHON_SCRIPT" "$SOURCE_MD"

# 3. Compile "By Problem" PDF
echo "🎨 Step 2: Generating 'By Problem' PDF..."
pandoc "$BUILD_MD" \
    -o "$OUTPUT_DIR/midterm2-FR-by-problem.pdf" \
    --pdf-engine=pdflatex \
    -V colorlinks=true \
    -V linkcolor=blue \
    --toc

# 4. Compile "By Version" PDF
echo "🎨 Step 3: Generating 'By Version' PDF..."
pandoc "$SOURCE_MD" \
    -o "$OUTPUT_DIR/midterm2-FR-by-version.pdf" \
    --pdf-engine=pdflatex \
    -V geometry:margin=1in \
    -V colorlinks=true \
    -V linkcolor=blue \
    -V header-includes='\usepackage{newpxtext,newpxmath}' \
    -V title="Midterm 2 Free Response Solutions (By Version)" \
    --toc

echo "-------------------------------------------------------"
echo "✅ SUCCESS: All PDFs updated in $OUTPUT_DIR"