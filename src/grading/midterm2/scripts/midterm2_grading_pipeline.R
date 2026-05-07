## ============================================================
## RUN Midterm 2 GRADING PIPELINE — ECON 1001
## Project root: econ1001/   (i.e., where your .Rproj lives)
## ============================================================

library(here)

message("Starting Midterm 2 grading pipeline (ECON 2110)...\n")

rm(list = ls())
gc()

ROOT <- here::here()

# Always run from project root for stable relative paths
setwd(ROOT)

run_step <- function(path) {
  if (!file.exists(path)) stop("Missing script: ", path, call. = FALSE)
  message("▶ ", basename(path), " ...")
  source(path, local = new.env())
}

# ---- 01: Ingest raw TA scores -------------------------------
run_step("grading/midterm2/scripts/01_ingest_midterm2_raw_scores.R")

# ---- 02: Curve / compute adjusted + summary figs ------------
run_step("grading/midterm2/scripts/02_curve_midterm2.R")

run_step("grading/midterm2/scripts/03_letter_analysis.R")

# ---- 04: Merge to Canvas upload CSV -------------------------
run_step("grading/midterm2/scripts/04_merge_midterm2_scores_to_canvas_template.R")

# ---- 05: Build Word grading note/report ---------------------
run_step("grading/midterm2/scripts/05_make_word_report.R")

message("\n✅ Midterm 2 pipeline complete.")
