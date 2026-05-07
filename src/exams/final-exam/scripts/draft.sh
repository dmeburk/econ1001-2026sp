#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/draft.sh [mc|fr] [VERSION] [--pdf]
#
#   mc   Iterate on MC questions (src/mc-master.md)
#        Runs the full MC pipeline for one version.
#
#   fr   Iterate on the FR question (src/fr-questions.tex, src/fr_params.csv)
#        Produces a standalone FR-only document for one version.
#        Note: run 'draft.sh mc A' at least once before using fr mode.
#
#   VERSION  A–E, defaults to A
#   --pdf    compile to PDF (otherwise stops at .tex)

cd "$(dirname "$0")/.."

if [ $# -eq 0 ]; then
  echo "Usage: draft.sh [mc|fr] [VERSION] [--pdf]"
  exit 1
fi

MODE="$1"
VERSION="A"
PDF=false

for arg in "${@:2}"; do
  case "$arg" in
    --pdf) PDF=true ;;
    *)     VERSION="$arg" ;;
  esac
done

case "$MODE" in
  mc)
    echo "▶ MC draft — Version $VERSION"
    python3 scripts/extract_mc_key.py
    python3 scripts/canonicalize_mc.py
    python3 scripts/shuffle_mc.py --seed 42 --versions "$VERSION"
    python3 scripts/build_exam_tex.py "$VERSION" --no-fr
    TEX_FILE="mc_${VERSION}_draft.tex"
    ;;
  fr)
    echo "▶ FR draft — Version $VERSION"
    python3 scripts/build_fr_tex.py
    python3 - <<PYEOF
from pathlib import Path
fr      = Path("build/fr/fr_${VERSION}.tex").read_text(encoding="utf-8")
tmpl    = Path("src/fr-standalone-template.tex").read_text(encoding="utf-8")
out     = tmpl.replace("FR_VERSION_PLACEHOLDER", "${VERSION}").replace("FR_CONTENT_PLACEHOLDER", fr.strip())
Path("build/tex").mkdir(parents=True, exist_ok=True)
Path("build/tex/fr_${VERSION}_draft.tex").write_text(out, encoding="utf-8")
print("✅ Created LaTeX: build/tex/fr_${VERSION}_draft.tex")
PYEOF
    TEX_FILE="fr_${VERSION}_draft.tex"
    ;;
  *)
    echo "Usage: draft.sh [mc|fr] [VERSION] [--pdf]"
    exit 1
    ;;
esac

if [ "$PDF" = true ]; then
  mkdir -p build/pdf/.build
  cd build/tex
  latexmk -pdf -silent -output-directory="../pdf/.build" "$TEX_FILE"
  cp "../pdf/.build/${TEX_FILE%.tex}.pdf" "../pdf/${TEX_FILE%.tex}.pdf"
  cd ../..
  echo ""
  echo "✅ Done: build/pdf/${TEX_FILE%.tex}.pdf"
else
  echo ""
  echo "✅ Done: build/tex/$TEX_FILE"
fi
