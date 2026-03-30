#!/usr/bin/env python3

import sys
import csv
from pathlib import Path

def main():
    if len(sys.argv) != 2:
        print("Usage: python generate-fr-tex.py <exam_slug>")
        sys.exit(1)

    exam_name = sys.argv[1]
    repo_root = Path(__file__).resolve().parents[3]
    src_dir = repo_root / "econ1001-desk" / "exams" / exam_name

    template_file = src_dir / "fr-template.tex"
    params_file = src_dir / "fr-params.csv"

    if not template_file.exists() or not params_file.exists():
        print(f"Error: Missing template or params in {src_dir}")
        sys.exit(1)

    template_text = template_file.read_text(encoding="utf-8")

    with open(params_file, mode='r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            version = row['version']
            content = template_text
            
            # Replace every key from the CSV (e.g., [[BOB_B]])
            for key, value in row.items():
                if key == 'version': continue
                content = content.replace(f"[[{key.upper()}]]", value)
            
            out_file = src_dir / f"fr_{version}.tex"
            out_file.write_text(content.strip() + "\n", encoding="utf-8")
            print(f"✅ Processed Version {version} -> {out_file.name}")

if __name__ == "__main__":
    main()