## ============================================================
## LOAD FINAL EXAM FR SCORES — ECON 1001 (SPRING 2026)
## ============================================================
## Input:  src/grading/final-exam/Final_Exam_FR_scores.csv
## Output: src/grading/final-exam/build/final_exam_fr_clean.rds
##
## FR assignment: 6 sub-parts (28a–28f), 4 pts each → max 24 pts
## ============================================================

library(tidyverse)

ROOT    <- here::here()
FR_FILE <- file.path(ROOT, "src/grading/final-exam/inputs/Final_Exam_FR_scores.csv")
OUTPUT  <- file.path(ROOT, "src/grading/final-exam/build/final_exam_fr_clean.rds")

fr_raw <- read_csv(FR_FILE, show_col_types = FALSE, na = c("", "NA", "N/A"))

# AD HOC ADJUSTMENT: submission 412782013 was graded as "unidentified student" (no SID).
# Confirmed to be jj1211, who has an MC score but no matched FR submission.
# jj1211 already has a placeholder "Missing" row in Gradescope; drop it in favor of this graded one.
fr_raw <- fr_raw %>%
  mutate(SID = if_else(`Submission ID` == 412782013 & is.na(SID), "jj1211", SID)) %>%
  arrange(SID, desc(Status == "Graded")) %>%
  distinct(SID, .keep_all = TRUE)

# Drop Gradescope footer / unidentified rows: keep only rows with a real SID
fr_raw <- fr_raw %>% filter(!is.na(SID))

cat("FR rows:", nrow(fr_raw), "\n")
cat("Status breakdown:\n"); print(table(fr_raw$Status, useNA = "always"))
cat("Max Points:", unique(fr_raw$`Max Points`), "\n")
cat("Score range:", min(fr_raw$`Total Score`, na.rm = TRUE), "–",
    max(fr_raw$`Total Score`, na.rm = TRUE), "/ 24\n")

fr_clean <- fr_raw %>%
  transmute(
    sis_user_id = SID,
    fr_score    = `Total Score`,  # out of 24
    fr_status   = Status
  )

stopifnot(!anyDuplicated(fr_clean$sis_user_id))

saveRDS(fr_clean, OUTPUT)
message("Saved: ", OUTPUT)
