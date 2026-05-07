library(tidyverse)
library(janitor)
library(ggplot2)
library(scales)
library(glue)

ensure_dir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  stopifnot(dir.exists(path))
  invisible(path)
}

# ------------------------------------------------------------
# Midterm 2 -> merge raw + curved into canvas template
# Then create a Canvas upload CSV.
# ------------------------------------------------------------

IN_TEMPLATE <- "grading/common/data/canonical/gradebook_raw.rds"
IN_CURVED   <- "grading/midterm2/build/midterm2_curved.rds"

OUT_MERGED        <- "grading/midterm2/build/canvas_template_with_midterm2.rds"
CANVAS_UPLOAD_FILE <- "grading/midterm2/outputs/midterm2_for_canvas.csv"

# Ensure output dirs exist
ensure_dir(dirname(OUT_MERGED))
ensure_dir(dirname(CANVAS_UPLOAD_FILE))

stopifnot(file.exists(IN_TEMPLATE))
stopifnot(file.exists(IN_CURVED))

# ------------------------------------------------------------
# Load template (keep as-is; DO NOT clean_names it)
# Expect: first 7 Canvas cols + sis_user_id column somewhere (often col 3 after clean_names pipeline)
# ------------------------------------------------------------
canvas_template <- read_rds(IN_TEMPLATE) 
stopifnot(!anyDuplicated(canvas_template$sis_user_id))

scores_curved <- read_rds(IN_CURVED)
scores_to_merge <- scores_curved %>% select(sis_user_id, raw, midterm2_curved)

merged <- canvas_template %>% clean_names() %>% 
  left_join(scores_to_merge, by = "sis_user_id") 

## Dropped Course
blocklist <- c("hdf11", "nag85", "mb3093", "sjn47")
# Filter out these students from the final upload logic
merged <- merged %>%
  filter(!(sis_user_id %in% blocklist))



write_rds(merged, OUT_MERGED)
cat(glue("Wrote: {OUT_MERGED}\n"))




# ------------------------------------------------------------
# Optional: quick audits
# ------------------------------------------------------------
n_missing_raw <- sum(is.na(merged$raw))
n_missing_cur <- sum(is.na(merged$midterm2_curved))

cat(glue("Missing raw scores:    {n_missing_raw}\n"))
cat(glue("Missing curved scores: {n_missing_cur}\n"))


# Manual rename 
canvas_upload <- merged %>%
  rename(
    Student          = 1,
    ID               = 2,
    `SIS User ID`    = 3,
    `SIS Login ID`   = 4,
    `Integration ID` = 5,
    `Root Account`   = 6,
    Section          = 7
  ) %>%
  select(1:7, 'raw', 'midterm2_curved')

# ----------------------------
# WRITE CANVAS UPLOAD FILE
# ----------------------------
write_csv(canvas_upload, CANVAS_UPLOAD_FILE)

# Remove trailing blank line (Canvas sometimes complains)
lines <- readLines(CANVAS_UPLOAD_FILE, warn = FALSE)
while (length(lines) > 0 && lines[length(lines)] == "") {
  lines <- lines[-length(lines)]
}
writeLines(lines, CANVAS_UPLOAD_FILE)

message("Canvas upload file written to:")
message(CANVAS_UPLOAD_FILE)
