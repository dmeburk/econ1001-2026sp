## ============================================================
## COMPUTE COURSE SCORE — ECON 1001 (SPRING 2026)
## ============================================================
## Components and weights:
##   PS average (drop 2 lowest)   10%
##   Podcast                       5%
##   Midterm 1 (curved)           20%
##   Midterm 2 (curved)           25%
##   Final exam (curved)          40%
##
## Scheme 2 (best midterm only):
##   PS average                   10%
##   Podcast                       5%
##   Best midterm                 35%
##   Final exam                   50%
##
## Student receives the better of the two schemes.
##
## Inputs: course/build/pre_final_grades.rds
##         final-exam/build/final_exam_curved.rds
## Output: course/build/course_scores.rds
##         course/outputs/ECON1001_Spring2026_CourseScore_Shadow.csv
## ============================================================

library(tidyverse)

ROOT          <- here::here()
PRE_FINAL     <- file.path(ROOT, "src/grading/course/build/pre_final_grades.rds")
FINAL_EXAM    <- file.path(ROOT, "src/grading/final-exam/build/final_exam_curved.rds")
OUTPUT_RDS    <- file.path(ROOT, "src/grading/course/build/course_scores.rds")
OUTPUT_SHADOW <- file.path(ROOT, "src/grading/course/outputs/ECON1001_Spring2026_CourseScore_Shadow.csv")

# ── WEIGHTS ───────────────────────────────────────────────────────────────────
W1 <- c(ps = 0.10, podcast = 0.05, midterm1 = 0.20, midterm2 = 0.25, final = 0.40)
W2 <- c(ps = 0.10, podcast = 0.05, best_mt  = 0.35, final    = 0.50)
stopifnot(abs(sum(W1) - 1) < 1e-8, abs(sum(W2) - 1) < 1e-8)

# ── GRADE POINT CUTOFFS ───────────────────────────────────────────────────────
score_to_gp <- function(score) {
  case_when(
    is.na(score)    ~ NA_real_,
    score > 92.2    ~ 4.00,
    score > 89.3    ~ 3.67,
    score > 86.3    ~ 3.33,
    score > 82.3    ~ 3.00,
    score > 79.3    ~ 2.67,
    score > 76.3    ~ 2.33,
    score > 72.3    ~ 2.00,
    score > 69.3    ~ 1.67,
    score > 66.3    ~ 1.33,
    score > 62.3    ~ 1.00,
    TRUE            ~ 0.00
  )
}

# ── LOAD INPUTS ───────────────────────────────────────────────────────────────
pre   <- readRDS(PRE_FINAL)
final <- readRDS(FINAL_EXAM)

course <- pre %>%
  left_join(final %>% select(sis_user_id, curved_score) %>%
              rename(final_exam = curved_score), by = "sis_user_id") %>%
  mutate(
    ps_component      = psavg / 10 * 100,
    podcast_component = podcast / 10 * 100,
    midterm_avg       = (midterm1 + midterm2) / 2,
    best_mt           = pmax(midterm1, midterm2, na.rm = TRUE),

    course_score_s1 =
      W1["ps"]       * ps_component +
      W1["podcast"]  * podcast_component +
      W1["midterm1"] * midterm1 +
      W1["midterm2"] * midterm2 +
      W1["final"]    * final_exam,

    course_score_s2 =
      W2["ps"]      * ps_component +
      W2["podcast"] * podcast_component +
      W2["best_mt"] * best_mt +
      W2["final"]   * final_exam,

    course_score = pmax(course_score_s1, course_score_s2, na.rm = TRUE),
    course_score = round(pmin(pmax(course_score, 0), 100), 1),

    gp         = score_to_gp(course_score),
    final_gp   = score_to_gp(final_exam),

    # Bump rule: if final exam GP > course GP and final ≥ midterm avg + 10
    adjusted_gp = if_else(
      !is.na(midterm1) & !is.na(midterm2) &
        !is.na(final_exam) &
        final_gp > gp &
        final_exam >= midterm_avg + 10,
      final_gp,
      gp
    )
  )

# ── SUMMARY ───────────────────────────────────────────────────────────────────
has_final <- course %>% filter(!is.na(final_exam))
cat("Students with full course score:", nrow(has_final), "\n")
cat("\nCourse score summary:\n")
print(summary(has_final$course_score))
cat("\nGP distribution:\n")
print(table(has_final$adjusted_gp, useNA = "always"))

# ── SENIORS ───────────────────────────────────────────────────────────────────
SENIOR_SIDS <- c("smm475", "cp1229", "ip281", "wag41", "smb436", "tlj64")
seniors_out <- course %>%
  filter(sis_user_id %in% SENIOR_SIDS) %>%
  select(student, sis_user_id, psavg, podcast, midterm1, midterm2,
         final_exam, course_score, gp, adjusted_gp, course_score_s1, course_score_s2)

cat("\n── Senior course scores ──────────────────────────────────\n")
print(seniors_out)

# ── SAVE ──────────────────────────────────────────────────────────────────────
saveRDS(course, OUTPUT_RDS)

course %>%
  select(student, sis_user_id, psavg, podcast, midterm1, midterm2,
         final_exam, course_score_s1, course_score_s2, course_score, gp, adjusted_gp) %>%
  write_csv(OUTPUT_SHADOW)

message("Shadow file saved: ", OUTPUT_SHADOW)
