## ============================================================
## RUN MIDTERM 1 GRADING PIPELINE — ECON 2110
## Project root: econ2110/   (i.e., where your .Rproj lives)
## ============================================================

library(here)

message("Starting Midterm 1 grading pipeline (ECON 2110)...\n")

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
run_step("_internal/automation/grading/midterm1/01_ingest_midterm1_raw_scores.R")

# ---- 02: Curve / compute adjusted + summary figs ------------
run_step("grading/midterm1/scripts/02_curve_midterm1.R")

# ---- 03: Merge to Canvas upload CSV -------------------------
run_step("grading/midterm1/scripts/03_merge_midterm1_scores_to_canvas_template.R")

# ---- 04: Build Word grading note/report ---------------------
run_step("grading/midterm1/scripts/04_make_word_report.R")

message("\n✅ Midterm 1 pipeline complete.")