# ============================================================
# ECON-1001 — Grading Pipeline
#
# Script: ps0-credit.R
#
# Purpose:
#   - Create credit / no-credit grade for Problem Set 0
#   - Does NOT modify original PS0 scores
#
# Inputs:
#   - data/clean/gradebook_raw.rds
#
# Outputs:
#   - outputs/ps0-credit-upload.csv
#
# Notes:
#   - Canvas upload requires first 7 columns unchanged
#   - NA values leave grades blank in Canvas
#
# Last updated: 2026-01-18
# ============================================================

library(tidyverse)

# ----------------------------
# CONFIG
# ----------------------------
RAW_RDS <- "_internal/kitchen/grading/common/finished/gradebook_raw.rds"
OUT_CSV <- "_internal/kitchen/grading/ps0/ps0-credit-upload.csv"

PS0_COL <- "Problem Set 0: Math Review (1331836)"
NEW_ASSIGNMENT_NAME <- "PS0 Credit (Math Review)"

# ----------------------------
# LOAD FROZEN GRADEBOOK
# ----------------------------
gb <- readRDS(RAW_RDS)

# ----------------------------
# CANVAS ID COLUMNS
# (first 7 columns, unchanged)
# ----------------------------
canvas_required_cols <- gb %>% select(1:7)
# ----------------------------
# COMPUTE PS0 CREDIT
# ----------------------------
ps0_credit <- gb %>%
  transmute(
    credit = if_else(
      `Problem Set 0: Math Review (1331836)` > 0,
      1,
      NA_real_,
      missing = NA_real_
    )
  )


# ----------------------------
# BUILD CANVAS UPLOAD
# ----------------------------
canvas_upload <- bind_cols(canvas_required_cols, ps0_credit) %>%
  rename(!!NEW_ASSIGNMENT_NAME := credit)

# ----------------------------
# WRITE CSV
# ----------------------------
write_csv(canvas_upload, OUT_CSV)

# Remove trailing blank lines (Canvas quirk)
lines <- readLines(OUT_CSV, warn = FALSE)
while (length(lines) > 0 && lines[length(lines)] == "") {
  lines <- lines[-length(lines)]
}
writeLines(lines, OUT_CSV)

message("Canvas upload file written to: ", OUT_CSV)