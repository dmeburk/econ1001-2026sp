## ============================================================
## LOAD FINAL EXAM MC SCORES — ECON 1001 (SPRING 2026)
## ============================================================
## Input:  src/grading/final-exam/Final_Exam_MC_Version_Set_Scores.zip
## Output: src/grading/final-exam/build/final_exam_mc_clean.rds
## ============================================================

library(tidyverse)

ROOT    <- here::here()
MC_ZIP  <- file.path(ROOT, "src/grading/final-exam/inputs/Final_Exam_MC_Version_Set_Scores.zip")
MC_FILE <- "Final_Exam_MC_Version_Set_Scores.csv"
OUTPUT  <- file.path(ROOT, "src/grading/final-exam/build/final_exam_mc_clean.rds")

mc_raw <- read_csv(unz(MC_ZIP, MC_FILE), show_col_types = FALSE, na = c("", "NA", "N/A"))

# Drop Gradescope footer / unassigned rows: keep only rows with a real SID
mc_raw <- mc_raw %>% filter(!is.na(SID))

cat("MC students:", nrow(mc_raw), "\n")
cat("Status breakdown:\n"); print(table(mc_raw$Status, useNA = "always"))
cat("Score range:", min(mc_raw$`Total Score`, na.rm = TRUE), "–",
    max(mc_raw$`Total Score`, na.rm = TRUE), "/ 27\n")

mc_clean <- mc_raw %>%
  transmute(
    sis_user_id = SID,
    mc_score    = `Total Score`,   # raw count, out of 27
    mc_version  = Version,
    mc_status   = if_else(is.na(Status), "Not submitted", Status)
  )

stopifnot(!anyDuplicated(mc_clean$sis_user_id))

saveRDS(mc_clean, OUTPUT)
message("Saved: ", OUTPUT)
