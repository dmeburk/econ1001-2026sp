## ============================================================
## COURSE GRADING PIPELINE — ECON 1001 (SPRING 2026)
## ============================================================
## Run order:
##   1. Final exam pipeline      (final-exam/scripts/run_pipeline.R)
##   2. Pre-final grades         (course/scripts/01_prep_pre_final_grades.R)
##   3. Course score             (course/scripts/02_compute_course_score.R)
##   4. Write outputs            (course/scripts/03_write_outputs.R)
##   5. Senior preliminary rpt   (course/scripts/04_senior_preliminary_report.R)
##   6. Course internal report   (course/scripts/05_render_report.R)
##
## Key files to update between runs:
##   - src/grading/final-exam/inputs/Final_Exam_FR_scores.csv  (re-download from Gradescope)
##   - CANVAS_FILE in 01_prep_pre_final_grades.R and 03_write_outputs.R (re-download Canvas)
##   - TARGET_MEDIAN in final-exam/scripts/03_combine_and_curve.R
## ============================================================

library(here)

source(file.path(here(), "src/grading/final-exam/scripts/run_pipeline.R"))
source(file.path(here(), "src/grading/course/scripts/01_prep_pre_final_grades.R"))
source(file.path(here(), "src/grading/course/scripts/02_compute_course_score.R"))
source(file.path(here(), "src/grading/course/scripts/03_write_outputs.R"))
source(file.path(here(), "src/grading/course/scripts/04_senior_preliminary_report.R"))
source(file.path(here(), "src/grading/course/scripts/05_render_report.R"))

message("\n✓ Course pipeline complete.")
