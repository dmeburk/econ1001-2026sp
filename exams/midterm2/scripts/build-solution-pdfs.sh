pandoc midterm2/solutions/build/fr-solutions-by-problem.md \
    -o midterm2/solutions/outputs/midterm2-FR-by-problem.pdf \
    --pdf-engine=pdflatex \
    -V colorlinks=true \
    -V linkcolor=blue \
    --toc


pandoc midterm2/solutions/fr_solutions.md \
    -o midterm2/solutions/outputs/midterm2-FR-by-version.pdf \
    --pdf-engine=pdflatex \
    -V geometry:margin=1in \
    -V colorlinks=true \
    -V linkcolor=blue \
    -V header-includes='\usepackage{newpxtext,newpxmath}' \
    -V title="Midterm 2 Free Response Solutions (By Version)" \
    --toc