## ============================================================
## MC ITEM ANALYSIS — ECON 1001 FINAL EXAM (SPRING 2026)
## ============================================================
## Canonicalizes student responses across all versions using the
## version order mapping, then computes per-problem class stats.
##
## Input:  inputs/Final_Exam_MC_student_responses.csv
##         src/exams/final-exam/src/mc_version_order.csv
## Output: build/mc_item_analysis.rds
##         outputs/mc_item_analysis.csv
## ============================================================

library(tidyverse)

ROOT         <- here::here()
RESPONSES    <- file.path(ROOT, "src/grading/final-exam/inputs/Final_Exam_MC_student_responses.csv")
VERSION_ORDER<- file.path(ROOT, "src/exams/final-exam/src/mc_version_order.csv")
OUTPUT_RDS   <- file.path(ROOT, "src/grading/final-exam/build/mc_item_analysis.rds")
OUTPUT_CSV   <- file.path(ROOT, "src/grading/final-exam/outputs/mc_item_analysis.csv")

# ── LOAD STUDENT RESPONSES ────────────────────────────────────────────────────
raw <- read_csv(RESPONSES, show_col_types = FALSE) %>%
  filter(!is.na(`Student ID`), Status == "Graded")

cat("Students loaded:", nrow(raw), "\n")
cat("Versions present:", paste(sort(unique(raw$Version)), collapse = ", "), "\n\n")

# Pivot to long: one row per (student, position)
responses_long <- raw %>%
  select(sis_user_id = `Student ID`, version = Version,
         matches("^Question \\d+ (Score|Student Response|Correct Response)")) %>%
  pivot_longer(
    cols = matches("^Question \\d+"),
    names_to = c("position", ".value"),
    names_pattern = "Question (\\d+) (Score|Student Response\\(s\\)|Correct Response)"
  ) %>%
  rename(student_response = `Student Response(s)`,
         correct_response = `Correct Response`) %>%
  mutate(position = as.integer(position),
         correct  = Score == 1)

# ── LOAD VERSION ORDER ────────────────────────────────────────────────────────
# Row i = exam position i; value = canonical problem number for that version
version_order <- read_csv(VERSION_ORDER, show_col_types = FALSE) %>%
  mutate(position = row_number()) %>%
  pivot_longer(-position, names_to = "version_col", values_to = "canonical_problem") %>%
  mutate(version = str_to_upper(str_remove(version_col, "version_"))) %>%
  select(version, position, canonical_problem)

cat("Version order mapping loaded:\n")
print(count(version_order, version))
cat("\n")

# ── JOIN: map each response to its canonical problem ─────────────────────────
responses_canonical <- responses_long %>%
  left_join(version_order, by = c("version", "position"))

stopifnot(!any(is.na(responses_canonical$canonical_problem)))

# ── ITEM-LEVEL STATS ─────────────────────────────────────────────────────────
item_stats <- responses_canonical %>%
  group_by(canonical_problem) %>%
  summarise(
    n           = n(),
    n_correct   = sum(correct, na.rm = TRUE),
    pct_correct = round(n_correct / n * 100, 1),
    .groups     = "drop"
  ) %>%
  arrange(canonical_problem)

cat("Item difficulty (% correct by canonical problem):\n")
print(item_stats, n = 27)

# ── SAVE ─────────────────────────────────────────────────────────────────────
saveRDS(responses_canonical, OUTPUT_RDS)
write_csv(item_stats, OUTPUT_CSV)
message("\nSaved: ", OUTPUT_RDS)
message("Saved: ", OUTPUT_CSV)
