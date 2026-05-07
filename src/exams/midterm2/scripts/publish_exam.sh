#!/usr/bin/env bash
set -euo pipefail

# --- THE PATHING FIX ---
# Ensures the script always runs from the midterm2/ root directory,
# regardless of where you call it from in the terminal.
cd "$(dirname "$0")/.."

# --- CONFIG ---
VERSIONS=(A B C D E)
SEED=42

# 1. PREP
echo "👨‍🍳 Cleaning the Kitchen..."
# Standardized folder names: 'outputs' instead of 'output'
mkdir -p build/canonical build/keys build/shuffled build/cooking build/finished outputs
rm -f build/cooking/* build/finished/* build/shuffled/*

# Fetch figures from the Creative Zone (source/figures/)
# and machinery from the Machinery Zone (inputs/)
cp source/figures/* build/cooking/ 2>/dev/null || true
cp inputs/*.cls build/cooking/ 2>/dev/null || true
cp inputs/*.sty build/cooking/ 2>/dev/null || true

# 2. RUN PIPELINE
# Updated to use the new snake_case script names
echo "▶ Extracting & Canonicalizing..."
python3 scripts/process_mc_key.py
python3 scripts/process_mc_data.py

echo "▶ Generating FR Snippets..."
python3 scripts/build_fr_tex.py

echo "▶ Shuffling MC Versions..."
# Updated script name for consistency
python3 scripts/shuffle_mc.py --seed $SEED --versions "${VERSIONS[@]}"

echo "▶ Building LaTeX Source..."
# Marries the shuffled MC and generated FR into the master template
for v in "${VERSIONS[@]}"; do
  python3 scripts/build_mc_tex.py "$v"
done

# 3. OVEN
echo "▶ Baking PDFs..."
cd build/cooking
for v in "${VERSIONS[@]}"; do
  echo "  • Baking Version $v..."
  # Compiles the .tex files using the exam document class
  latexmk -pdf -silent -output-directory="../finished" "mc_${v}.tex"
done
cd ../..

# 4. SERVE
echo "▶ Serving final products to ./outputs..."

# Move the finalized PDFs to the outputs directory
for v in "${VERSIONS[@]}"; do
  cp "build/finished/mc_$v.pdf" "outputs/Midterm2_Version_$v.pdf"
done

# Move the Master Scantron Key
if [ -f "build/keys/final_answer_key.csv" ]; then
  cp "build/keys/final_answer_key.csv" "outputs/Midterm2_MASTER_KEY.csv"
  echo "✅ Master Answer Key served."
fi

echo "🎉 Done! Check the ./outputs folder."