## ============================================================
## COMBINE + CURVE FINAL EXAM — ECON 1001 (SPRING 2026)
## ============================================================
## Exam: 27 MC × 4 pts + 6 FR × 4 pts = 132 pts total
## Raw score = 4 * mc_score (out of 27) + fr_score (out of 24)
##
## Input:  build/final_exam_mc_clean.rds
##         build/final_exam_fr_clean.rds
## Output: build/final_exam_curved.rds
## ============================================================

library(tidyverse)
library(janitor)

ROOT    <- here::here()
MC_FILE <- file.path(ROOT, "src/grading/final-exam/build/final_exam_mc_clean.rds")
FR_FILE <- file.path(ROOT, "src/grading/final-exam/build/final_exam_fr_clean.rds")
OUTPUT  <- file.path(ROOT, "src/grading/final-exam/build/final_exam_curved.rds")

EXAM_MAX <- 132   # 4*27 + 24

# ── CURVE PARAMETERS ─────────────────────────────────────────────────────────
# Affine curve: curved_score = A + B * raw_score
# Cap: curved_score ≤ raw_pct + 0.25 * raw_pct  (same cap as Fall 2025)
# Cap at 100.
#
# PRELIMINARY = TRUE: curving with partial FR data.
# Recalibrate once full class FR is graded.
#
# Two-point calibration: anchor the target median AND the target max.
# B and A are then uniquely determined — no arbitrary slope needed.
#   B = (TARGET_MAX - TARGET_MEDIAN) / (raw_max - raw_median)
#   A = TARGET_MEDIAN - B * raw_median
PRELIMINARY   <- FALSE
TARGET_MEDIAN <- 84.0   # ← what should the median student score?
TARGET_MAX    <- 100.0  # ← what should the top student score? (set <100 to leave headroom)

# ─────────────────────────────────────────────────────────────────────────────

mc_clean <- readRDS(MC_FILE)
fr_clean <- readRDS(FR_FILE)

# ── AD HOC MC SCORE ADJUSTMENTS ──────────────────────────────────────────────
# rjf80 (Filipe, Rylan): claimed his bubble sheet was shifted by 5 — he started
# answering problem 6 in row 1. Accepted his story for rows 1–22 (credited as
# answers to positions 6–27); rows 23–27 ignored (he could not account for
# them); positions 1–5 receive no credit. Corrected MC correct = 13/27.
mc_clean <- mc_clean %>%
  mutate(mc_score = if_else(sis_user_id == "rjf80", 13L, mc_score))

# ── AD HOC FR SCORE ADJUSTMENTS ──────────────────────────────────────────────
# ccz10 (Zehner, Catherine): +4 raw points on final exam (fr_score 20 → 24)
fr_clean <- fr_clean %>%
  mutate(fr_score = if_else(sis_user_id == "ccz10", fr_score + 4L, fr_score))

exam <- mc_clean %>%
  left_join(fr_clean, by = "sis_user_id")

# Students with fully graded MC + FR
exam_curve <- exam %>%
  filter(mc_status == "Graded", fr_status == "Graded")

# Everyone else (missing / ungraded / makeup)
exam_pending <- exam %>%
  anti_join(exam_curve, by = "sis_user_id")

cat("Students with both MC + FR graded:", nrow(exam_curve), "\n")
cat("Students pending:", nrow(exam_pending), "\n")
if (nrow(exam_pending) > 0) {
  cat("Pending breakdown:\n")
  print(table(paste(exam_pending$mc_status, "/", exam_pending$fr_status)))
}

# Raw score and percentage
exam_curve <- exam_curve %>%
  mutate(
    raw_score = 4 * mc_score + fr_score,
    raw_pct   = round(raw_score / EXAM_MAX * 100, 1)
  )

# Fit A and B from two anchors: (raw_median → TARGET_MEDIAN) and (raw_max → TARGET_MAX)
raw_median <- median(exam_curve$raw_score)
raw_max    <- max(exam_curve$raw_score)

B <- (TARGET_MAX - TARGET_MEDIAN) / (raw_max - raw_median)
A <- TARGET_MEDIAN - B * raw_median

cat("\nTwo-point curve fit:\n")
cat("  raw_median =", raw_median, "→ curved =", TARGET_MEDIAN, "\n")
cat("  raw_max    =", raw_max,    "→ curved =", TARGET_MAX,    "\n")
cat("  B =", round(B, 4), " | A =", round(A, 4), "\n")
cat("  Formula: curved =", round(A, 2), "+", round(B, 4), "× raw_score\n\n")

# Apply curve
exam_curve <- exam_curve %>%
  mutate(
    curved_score = A + B * raw_score,
    curved_score = pmin(curved_score, raw_pct + 0.25 * raw_pct),  # cap rule
    curved_score = pmin(curved_score, 100),
    curved_score = pmax(curved_score, 0),
    curved_score = round(curved_score, 1)
  )

cat("Curved score summary (n =", nrow(exam_curve), "):\n")
print(summary(exam_curve$curved_score))

if (PRELIMINARY) {
  cat("\n*** PRELIMINARY: based on", nrow(exam_curve),
      "graded students. Recalibrate TARGET_MEDIAN and B once full class is graded.\n")
}

# ── SAVE INTERMEDIATE RDS ────────────────────────────────────────────────────
out <- exam_curve %>%
  select(sis_user_id, mc_score, fr_score, raw_score, raw_pct, curved_score)

saveRDS(out, OUTPUT)
message("Saved: ", OUTPUT)
