#!/usr/bin/env bash
set -euo pipefail

# --- CONFIG ---
VERSIONS=(A B C D E)
SEED=42

# 1. SETUP
echo "👨‍🍳 Prepping Local Kitchen..."
mkdir -p build/canonical build/keys build/shuffled build/cooking build/finished output
rm -f build/cooking/* build/finished/* build/shuffled/*

# 2. RUN PIPELINE
echo "▶ Canonicalizing..."
python3 scripts/mc-finalized-to-canonical.py
python3 scripts/mc-finalized-to-canonical-key.py

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
echo "▶ Serving to Output..."
for v in "${VERSIONS[@]}"; do
  cp "build/finished/mc_$v.pdf" "output/Midterm2_Version_$v.pdf"
done

echo "🎉 Build Complete!"