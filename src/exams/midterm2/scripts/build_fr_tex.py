#!/usr/bin/env python3

import csv
from pathlib import Path

def main():
    # --- ANCHOR PATHING ---
    # Path(__file__) is midterm2/scripts/build_fr_tex.py
    # .parent is midterm2/scripts/
    # .parent.parent is midterm2/ (The project root)
    BASE_DIR = Path(__file__).resolve().parent.parent
    
    # Inputs are in the 'inputs' folder
    # Updated to snake_case to match the machinery standard
    template_file = BASE_DIR / "inputs" / "fr_template.tex"
    params_file = BASE_DIR / "inputs" / "fr_params.csv"
    
    # Output goes to 'build' for the next step in the pipeline
    build_dir = BASE_DIR / "build"
    build_dir.mkdir(exist_ok=True)

    # --- VALIDATION ---
    if not template_file.exists():
        print(f"❌ Error: Missing template at {template_file}")
        return
    if not params_file.exists():
        print(f"❌ Error: Missing params at {params_file}")
        return

    # --- PROCESSING ---
    template_text = template_file.read_text(encoding="utf-8")

    with open(params_file, mode='r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            # Ensure your CSV column is named 'version' (A, B, C...)
            version = row.get('version', 'Unknown').upper()
            content = template_text
            
            # Replace every key from the CSV (e.g., [[BOB_B]])
            for key, value in row.items():
                if key.lower() == 'version': 
                    continue
                # Placeholder format: [[KEY]]
                placeholder = f"[[{key.upper()}]]"
                content = content.replace(placeholder, str(value))
            
            # Save to build/ folder for the LaTeX baker to find
            out_file = build_dir / f"fr_{version}.tex"
            out_file.write_text(content.strip() + "\n", encoding="utf-8")
            print(f"✅ Generated: build/{out_file.name}")

if __name__ == "__main__":
    main()