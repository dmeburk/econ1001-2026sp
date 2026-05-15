## ============================================================
## SENIOR PRELIMINARY GRADE REPORT — ECON 1001 (SPRING 2026)
## ============================================================
## Shows all grade components for each graduating senior,
## with final exam curved score contextualized against the
## current class distribution (graded-so-far subset).
## Saves a CSV snapshot for comparison after final grades run.
## ============================================================

library(tidyverse)

ROOT       <- here::here()
COURSE_RDS <- file.path(ROOT, "src/grading/course/build/course_scores.rds")
FE_RDS     <- file.path(ROOT, "src/grading/final-exam/build/final_exam_curved.rds")
OUTPUT     <- file.path(ROOT, "src/grading/course/outputs/seniors_preliminary_report.csv")

SENIOR_SIDS <- c("smm475", "cp1229", "ip281", "wag41", "smb436", "tlj64")

gp_to_letter <- function(gp) {
  case_when(
    gp == 4.00 ~ "A",   gp == 3.67 ~ "A-",  gp == 3.33 ~ "B+",
    gp == 3.00 ~ "B",   gp == 2.67 ~ "B-",  gp == 2.33 ~ "C+",
    gp == 2.00 ~ "C",   gp == 1.67 ~ "C-",  gp == 1.33 ~ "D+",
    gp == 1.00 ~ "D",   gp == 0.00 ~ "F",   TRUE        ~ NA_character_
  )
}

# ── CLASS FINAL EXAM CONTEXT ──────────────────────────────────────────────────
fe <- readRDS(FE_RDS)
fe_n        <- nrow(fe)
fe_mean     <- round(mean(fe$curved_score), 1)
fe_median   <- round(median(fe$curved_score), 1)
fe_sd       <- round(sd(fe$curved_score), 1)

# ── SENIOR DATA ───────────────────────────────────────────────────────────────
course <- readRDS(COURSE_RDS)

report <- course %>%
  filter(sis_user_id %in% SENIOR_SIDS) %>%
  left_join(fe %>% select(sis_user_id, raw_score, raw_pct), by = "sis_user_id") %>%
  mutate(
    podcast_note    = if_else(is.na(podcast_raw), "proxy (10)", as.character(podcast_raw)),
    fe_vs_class_avg = round(final_exam - fe_mean, 1),
    fe_percentile   = round(100 * percent_rank(
      c(fe$curved_score, final_exam)   # rank within the graded pool
    )[match(sis_user_id, c(fe$sis_user_id, sis_user_id))]),
    letter          = gp_to_letter(adjusted_gp),
    snapshot_date   = Sys.Date()
  ) %>%
  transmute(
    Student          = student,
    SIS_ID           = sis_user_id,
    PS_avg           = psavg,
    Podcast          = podcast,
    Podcast_note     = podcast_note,
    Midterm1_curved  = midterm1,
    Midterm2_curved  = midterm2,
    Final_raw        = raw_score,
    Final_raw_pct    = raw_pct,
    Final_curved     = final_exam,
    Final_vs_cls_avg = fe_vs_class_avg,
    Course_score     = course_score,
    Scheme_used      = if_else(course_score_s2 >= course_score_s1, "S2 (best-MT)", "S1 (both-MT)"),
    GP               = adjusted_gp,
    Letter           = letter,
    Snapshot_date    = snapshot_date
  ) %>%
  arrange(desc(Course_score))

# ── PRINT ─────────────────────────────────────────────────────────────────────
cat(sprintf(
  "\n── Senior Preliminary Grade Report (%s) ──────────────────────────────\n",
  Sys.Date()
))
cat(sprintf(
  "Final exam context: n=%d graded | mean=%.1f | median=%.1f | SD=%.1f\n\n",
  fe_n, fe_mean, fe_median, fe_sd
))

report %>%
  select(Student, PS_avg, Podcast, Midterm1_curved, Midterm2_curved,
         Final_curved, Final_vs_cls_avg, Course_score, Letter) %>%
  as.data.frame() %>%
  print()

cat("\nNotes:\n")
cat("  Final_vs_cls_avg: senior's curved final relative to class mean (", fe_mean, ")\n")
cat("  Podcast_note: 'proxy (10)' = not yet graded; actual grade used otherwise\n")
cat("  Preliminary: curve based on", fe_n, "graded students. Will shift when full class is curved.\n")

# ── SAVE ──────────────────────────────────────────────────────────────────────
write_csv(report, OUTPUT)
message("\nSaved: ", OUTPUT)
