import sys
import csv
from pathlib import Path

# Script is in midterm2_standalone/scripts/, so EXAM_DIR is midterm2_standalone/
EXAM_DIR = Path(__file__).resolve().parent.parent
TEMPLATE_FILE = EXAM_DIR / "fr-template.tex"
PARAMS_FILE = EXAM_DIR / "fr-params.csv"
BUILD_DIR = EXAM_DIR / "build"

def main():
    BUILD_DIR.mkdir(exist_ok=True)
    if not TEMPLATE_FILE.exists():
        print(f"Missing {TEMPLATE_FILE}")
        return

    template_text = TEMPLATE_FILE.read_text(encoding="utf-8")

    with open(PARAMS_FILE, mode='r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            version = row['version']
            content = template_text
            for key, value in row.items():
                if key == 'version': continue
                content = content.replace(f"[[{key.upper()}]]", str(value))
            
            out_file = BUILD_DIR / f"fr_{version}.tex"
            out_file.write_text(content.strip() + "\n", encoding="utf-8")
            print(f"✅ Generated build/fr_{version}.tex")

if __name__ == "__main__":
    main()