#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

SOURCE_MD="src/fr-solutions.md"
OUTPUT_DIR="outputs"

mkdir -p "$OUTPUT_DIR"

echo "Generating solutions PDF..."
pandoc "$SOURCE_MD" \
    -o "$OUTPUT_DIR/final-exam-solutions.pdf" \
    --pdf-engine=pdflatex \
    -V geometry:margin=1in \
    -V colorlinks=true \
    -V linkcolor=blue \
    --toc

echo "✅ Done: $OUTPUT_DIR/final-exam-solutions.pdf"
