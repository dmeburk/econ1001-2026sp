import re
import subprocess
from pathlib import Path
import sys

def refactor_solutions(input_path):
    input_file = Path(input_path)
    if not input_file.exists():
        print(f"Error: {input_path} not found.")
        return

    # --- SETUP PATHING ---
    base_dir = input_file.parent 
    build_dir = base_dir / "build"
    output_dir = base_dir / "outputs"
    scripts_dir = Path(__file__).parent
    
    build_dir.mkdir(parents=True, exist_ok=True)
    output_dir.mkdir(parents=True, exist_ok=True)

    content = input_file.read_text(encoding="utf-8")
    version_blocks = re.split(r'## Version ([A-E]).*', content, flags=re.IGNORECASE)
    
    data = {}
    part_titles = {} 
    questions_found = []
    
    for i in range(1, len(version_blocks), 2):
        ver = version_blocks[i].upper()
        ver_content = version_blocks[i+1].strip()
        q_blocks = re.split(r'### Question (\d+):?[^\n]*', ver_content)
        
        for j in range(1, len(q_blocks), 2):
            q_num = q_blocks[j]
            q_content = q_blocks[j+1]
            if q_num not in questions_found:
                questions_found.append(q_num)
            
            # Split only on lettered parts (a., b., c.)
            parts = re.split(r'\n([a-z])\.\s+\*\*([^*]+?)\*\*:?\s*', '\n' + q_content.strip())
            
            for k in range(1, len(parts), 3):
                if k + 2 < len(parts):
                    p_letter = parts[k].lower()
                    p_title = parts[k+1].strip()
                    if p_title.endswith(':'): p_title = p_title[:-1] 
                    p_body = parts[k+2].strip()
                    
                    # Convert $$ to inline $ and escape currency
                    p_body = p_body.replace('$$', '$')
                    p_body = re.sub(r'(?<!\\)\$(\d+)', r'\\\$\1', p_body)
                    
                    data[(ver, q_num, p_letter)] = p_body
                    if (q_num, p_letter) not in part_titles:
                        part_titles[(q_num, p_letter)] = p_title

    # --- GENERATE: By-Problem Markdown ---
    by_prob = [
        "---",
        "title: \"Midterm 2 Free Response Solutions (By Problem)\"",
        "geometry: margin=1in",
        "header-includes: |",
        "  \\usepackage{newpxtext,newpxmath}",
        "---",
        "",
        "# Free Response Solutions (By Problem)", 
        ""
    ]
    for q in questions_found:
        by_prob.append(f"## Question {q}")
        q_parts = sorted({k[2] for k in data.keys() if k[1] == q})
        for p_letter in q_parts:
            p_title = part_titles.get((q, p_letter), "Solution")
            by_prob.append(f"### Part ({p_letter}): {p_title}")
            for v in ['A', 'B', 'C', 'D', 'E']:
                if (v, q, p_letter) in data:
                    by_prob.append(f"#### Version {v}\n{data[(v, q, p_letter)]}\n")
            by_prob.append("***\n")

    # --- GENERATE: Source Tagged Markdown ---
    source_truth = ["<" + "!-- SOLUTIONS_FR_KEYS_START --" + ">", ""]
    for v in ['A', 'B', 'C', 'D', 'E']:
        source_truth.append(f"## VERSION {v}\n")
        for q in questions_found:
            q_parts = sorted({k[2] for k in data.keys() if k[1] == q})
            for p_letter in q_parts:
                if (v, q, p_letter) in data:
                    tag = f"<{'!'}-- [ver:{v}][p:{q}][{p_letter}] --{'>'}"
                    source_truth.append(f"{tag}\n{p_letter}. **{part_titles[(q, p_letter)]}:** {data[(v, q, p_letter)]}\n")
        source_truth.append("***\n")
    source_truth.append("<" + "!-- SOLUTIONS_FR_KEYS_END --" + ">")

    # --- WRITE INTERMEDIATE FILES TO BUILD ---
    (build_dir / "fr-solutions-by-problem.md").write_text("\n".join(by_prob), encoding="utf-8")
    (build_dir / "fr-solutions-source.md").write_text("\n".join(source_truth), encoding="utf-8")
    

if __name__ == "__main__":
    default_path = "midterm2/solutions/fr_solutions.md"
    filename = sys.argv[1] if len(sys.argv) > 1 else default_path
    refactor_solutions(filename)