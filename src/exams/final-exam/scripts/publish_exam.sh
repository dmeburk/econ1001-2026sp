#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

VERSIONS=(A B C D E)
SEED=42

# 1. PREP
echo "▶ Cleaning build artifacts..."
mkdir -p build/mc/keys build/fr build/tex build/pdf/.build outputs
rm -f build/mc/mc_*.md build/fr/* build/tex/* build/pdf/*.pdf

cp src/figures/* build/tex/ 2>/dev/null || true
cp src/*.cls build/tex/ 2>/dev/null || true
cp src/*.sty build/tex/ 2>/dev/null || true

# 2. PIPELINE
echo "▶ Extracting & canonicalizing..."
python3 scripts/extract_mc_key.py
python3 scripts/canonicalize_mc.py

echo "▶ Generating FR snippets..."
python3 scripts/build_fr_tex.py

echo "▶ Shuffling MC versions..."
python3 scripts/shuffle_mc.py --seed $SEED --versions "${VERSIONS[@]}"

echo "▶ Building LaTeX..."
for v in "${VERSIONS[@]}"; do
  python3 scripts/build_exam_tex.py "$v"
done

# 3. COMPILE
echo "▶ Compiling PDFs..."
mkdir -p build/pdf/.build
cd build/tex
for v in "${VERSIONS[@]}"; do
  echo "  • Version $v..."
  latexmk -pdf -silent -output-directory="../pdf/.build" "exam_${v}.tex"
  cp "../pdf/.build/exam_${v}.pdf" "../pdf/exam_${v}.pdf"
done
cd ../..

# 4. OUTPUT
echo "▶ Copying to outputs/..."
for v in "${VERSIONS[@]}"; do
  cp "build/pdf/exam_$v.pdf" "outputs/final-exam-$v.pdf"
done

if [ -f "build/mc/keys/final_answer_key.csv" ]; then
  cp "build/mc/keys/final_answer_key.csv" "outputs/mc_answer_key.csv"
  echo "✅ Master answer key saved."
fi

echo "🎉 Done! Check ./outputs/"
