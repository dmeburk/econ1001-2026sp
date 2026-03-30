#!/usr/bin/env bash
set -euo pipefail

# --- CONFIG ---
VERSIONS=(A B C D E)
SEED=42

# 1. PREP
echo "👨‍🍳 Cleaning the Kitchen..."
mkdir -p build/canonical build/keys build/shuffled build/cooking build/finished output
rm -f build/cooking/* build/finished/* build/shuffled/*

# 2. RUN PIPELINE
echo "▶ Extracting & Canonicalizing..."
python3 scripts/mc-finalized-to-canonical-key.py
python3 scripts/mc-finalized-to-canonical.py

echo "▶ Generating FR..."
python3 scripts/generate_fr.py

echo "▶ Shuffling..."
python3 scripts/shuffle-canonical-mc.py --seed $SEED --versions "${VERSIONS[@]}"

echo "▶ Building LaTeX..."
for v in "${VERSIONS[@]}"; do
  python3 scripts/build-mc-tex.py "$v"
done

# 3. OVEN
echo "▶ Baking PDFs..."
cd build/cooking
for v in "${VERSIONS[@]}"; do
  echo "  • Baking Version $v..."
  latexmk -pdf -silent -output-directory="../finished" "mc_${v}.tex"
done
cd ../..

# 4. SERVE
echo "▶ Serving final products to ./output..."

# Move the PDFs
for v in "${VERSIONS[@]}"; do
  cp "build/finished/mc_$v.pdf" "output/Midterm2_Version_$v.pdf"
done

# Move the Master Key
if [ -f "build/keys/final_answer_key.csv" ]; then
  cp "build/keys/final_answer_key.csv" "output/Midterm2_MASTER_KEY.csv"
  echo "✅ Master Answer Key served."
fi

echo "🎉 Done! Check the ./output folder."