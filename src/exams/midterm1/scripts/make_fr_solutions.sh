#!/usr/bin/env bash
set -euo pipefail

IN="inputs/solutions/fr-solutions-source.md"
BY_VERSION_PDF="outputs/fr-solutions-by-version.pdf"

# NEW: by-part markdown + pdf
BY_PART_MD="intermediates/fr-solutions-by-part.md"
BY_PART_PDF="outputs/fr-solutions-by-part.pdf"

TRANSPOSE="./transpose-fr-solutions-by-part.py"

# --- Build: by version ---
pandoc "$IN" \
  -o "$BY_VERSION_PDF" \
  --from markdown+tex_math_dollars \
  --pdf-engine=xelatex \
  --lua-filter=pagebreaks-by-version.lua \
  --template=fr-solutions.tex \
  -V title="Free Response Solution Keys (By Version)"
echo "Wrote: $BY_VERSION_PDF"

# --- Build: by part (md) ---
python3 "$TRANSPOSE" "$IN" "$BY_PART_MD"
echo "Wrote: $BY_PART_MD"

# --- Build: by part (pdf) ---
pandoc "$BY_PART_MD" \
  -o "$BY_PART_PDF" \
  --from markdown+tex_math_dollars \
  --pdf-engine=xelatex \
  --lua-filter=pagebreaks-by-part.lua \
  --template=fr-solutions.tex \
  -V title="Free Response Solution Keys (By Part)"
echo "Wrote: $BY_PART_PDF"