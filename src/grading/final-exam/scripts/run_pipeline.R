## ============================================================
## FINAL EXAM GRADING PIPELINE — ECON 1001 (SPRING 2026)
## ============================================================
## Run order:
##   1. Load MC scores           (01_load_mc.R)
##   2. Load FR scores           (02_load_fr.R)
##   3. Combine and curve        (03_combine_and_curve.R)
##   4. Render grading note      (06_render_grading_note.R)
##   5. Render internal report   (07_render_internal_report.R)
##
## Output: build/final_exam_curved.rds
##         outputs/reports/econ1001-final-exam-grading-note.pdf
##         outputs/reports/econ1001-final-exam-internal-note.pdf
##
## Key files to update between runs:
##   - inputs/Final_Exam_FR_scores.csv  (re-download from Gradescope as grading progresses)
##   - TARGET_MEDIAN in 03_combine_and_curve.R  (recalibrate once full class is graded)
## ============================================================

library(here)

source(file.path(here(), "src/grading/final-exam/scripts/01_load_mc.R"))
source(file.path(here(), "src/grading/final-exam/scripts/02_load_fr.R"))
source(file.path(here(), "src/grading/final-exam/scripts/03_combine_and_curve.R"))
source(file.path(here(), "src/grading/final-exam/scripts/06_render_grading_note.R"))
source(file.path(here(), "src/grading/final-exam/scripts/07_render_internal_report.R"))

message("\n✓ Final exam pipeline complete.")
