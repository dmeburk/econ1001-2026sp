library(tidyverse)
library(readxl)
library(janitor)

ensure_dir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  stopifnot(dir.exists(path))
  invisible(path)
}

MC_FILE <- "grading/midterm2/inputs/Midterm_2_Multiple_Choice_Part_Version_Set_Scores/Midterm_2_Multiple_Choice_Part_Version_Set_Scores.csv"
FR_FILE <- "grading/midterm2/inputs/Midterm_2_Free_Response_Part_scores.csv"
MC_OUT_RDS     <- "grading/midterm2/build/mc_raw.rds"
FR_OUT_RDS     <- "grading/midterm2/build/fr_raw.rds"

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


## Temporary Blocklist
# # missing FR scores for these students (JL wrote on separate paper)
# blocklist <- c("jl3431")
# # Filter out these students from the final upload logic
# fr_scores <- fr_scores %>%
#   filter(!(sis_user_id %in% blocklist))
# mc_scores <- mc_scores %>%
#   filter(!(sis_user_id %in% blocklist))



write_rds(mc_scores, MC_OUT_RDS)
write_rds(fr_scores, FR_OUT_RDS)


cat("Wrote: ", MC_OUT_RDS, "\n", sep = "")
cat("Wrote: ", FR_OUT_RDS, "\n", sep = "")