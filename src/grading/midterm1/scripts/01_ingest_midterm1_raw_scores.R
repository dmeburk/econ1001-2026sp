library(tidyverse)
library(readxl)
library(janitor)

ensure_dir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  stopifnot(dir.exists(path))
  invisible(path)
}

MC_FILE <- "_internal/records/grading/midterm1/Midterm_1_Multiple_Choice_Part_Version_Set_Scores/Midterm_1_Multiple_Choice_Part_Version_Set_Scores.csv"
FR_FILE <- "_internal/records/grading/midterm1/Midterm_1_Free_Response_Part_scores.csv"
MC_OUT_RDS     <- "_internal/kitchen/grading/midterm1/cooking/mc_raw.rds"
FR_OUT_RDS     <- "_internal/kitchen/grading/midterm1/cooking/fr_raw.rds"

# Ensure output directory exists
ensure_dir(dirname(MC_OUT_RDS))
ensure_dir(dirname(FR_OUT_RDS))

mc_scores <- read_csv(MC_FILE) %>%
  clean_names() %>%
  select(sid, total_score, version) %>%
  transmute(
    sis_user_id  = str_trim(sid),
    mc_raw = parse_number(as.character(total_score)),
    version
  ) %>%
  filter(!is.na(sis_user_id))

fr_scores <- read_csv(FR_FILE) %>%
  clean_names() %>%
  select(sid, total_score) %>%
  transmute(
    sis_user_id  = str_trim(sid),
    fr_raw = parse_number(as.character(total_score))
  ) %>%
  filter(!is.na(sis_user_id))

# Sanity checks
mc_scores %>% count(sis_user_id) %>% filter(n > 1)
mc_scores %>% summarise(n = n(), missing = sum(is.na(mc_raw)))
fr_scores %>% count(sis_user_id) %>% filter(n > 1)
fr_scores %>% summarise(n = n(), missing = sum(is.na(fr_raw)))

write_rds(mc_scores, MC_OUT_RDS)
write_rds(fr_scores, FR_OUT_RDS)

cat("Wrote: ", MC_OUT_RDS, "\n", sep = "")
cat("Wrote: ", FR_OUT_RDS, "\n", sep = "")