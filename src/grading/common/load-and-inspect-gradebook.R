# ============================================================
# ECON-1001 — Grading Pipeline (Garage Edition)
#
# Script: 01-load-and-inspect-gradebook.R
# Location: _internal/automation/01-load-and-inspect-gradebook.R
# ============================================================

library(tidyverse)
library(here) # Best practice for RProj path management

# --- 1. SET PATHS RELATIVE TO ROOT ---
# Since this script lives in _internal/automation/, we go up two levels
# to get to the project root where .Rproj lives.
base_path <- here()

raw_path       <- file.path(base_path, "src/grading/common/data/raw")
processed_path <- file.path(base_path, "src/grading/common/data/canonical")

# Ensure the processed/canonical directory exists
if (!dir.exists(processed_path)) dir.create(processed_path, recursive = TRUE)

# --- 2. LOAD RAW CANVAS GRADEBOOK ---
# Note: Ensure the filename matches your latest export
raw_file <- file.path(raw_path, "econ-1001-canvas-gradebook-2026-05-11.csv")

gradebook_raw <- read_csv(raw_file, show_col_types = FALSE)

# --- 3. INSPECT STRUCTURE ---
glimpse(gradebook_raw)
print(colnames(gradebook_raw))

# --- 4. SAVE CANONICAL COPY ---
# We store the RDS in 'processed' (or 'canonical') inside Records
saveRDS(
  gradebook_raw,
  file.path(processed_path, "gradebook_raw.rds")
)

message("✅ Raw gradebook successfully archived to: ", processed_path)