#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

SRC="src/response-back.tex"
BUBBLE="src/response-sheet/bubble_sheet.pdf"
OUTPUT_DIR="outputs"
BUILD_DIR="build/pdf/.build"

mkdir -p "$OUTPUT_DIR" "$BUILD_DIR"

echo "Compiling response back page..."
latexmk -pdf -silent -output-directory="$BUILD_DIR" "$SRC"
cp "$BUILD_DIR/response-back.pdf" build/pdf/response-back.pdf

echo "Merging front and back..."
pdfunite "$BUBBLE" build/pdf/response-back.pdf "$OUTPUT_DIR/response-sheet.pdf"

echo "✅ Done: $OUTPUT_DIR/response-sheet.pdf"
