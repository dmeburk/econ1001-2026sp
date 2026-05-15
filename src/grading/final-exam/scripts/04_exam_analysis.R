## ============================================================
## FINAL EXAM DESCRIPTIVE ANALYSIS — ECON 1001 (SPRING 2026)
## ============================================================
## Produces three analyses:
##   1. MC-only  (all students with MC graded)
##   2. FR-only  (students with FR graded — note: non-random sample)
##   3. Combined (students with both MC + FR graded)
## Highlights senior scores in each section.
## ============================================================

library(tidyverse)

ROOT    <- here::here()
MC_FILE <- file.path(ROOT, "src/grading/final-exam/build/final_exam_mc_clean.rds")
FR_FILE <- file.path(ROOT, "src/grading/final-exam/build/final_exam_fr_clean.rds")
FE_FILE <- file.path(ROOT, "src/grading/final-exam/build/final_exam_curved.rds")

EXAM_MAX   <- 132
MC_MAX     <- 27
FR_MAX     <- 24

SENIOR_SIDS <- c("smm475", "cp1229", "ip281", "wag41", "smb436", "tlj64")
SENIOR_NAMES <- c(
  smm475 = "Melese", cp1229 = "Prasad", ip281 = "Pavlonnis",
  wag41  = "Glisk",  smb436 = "Bissell", tlj64 = "Jacquand"
)

mc <- readRDS(MC_FILE)
fr <- readRDS(FR_FILE)
fe <- readRDS(FE_FILE)

# ── 1. MC-ONLY ────────────────────────────────────────────────────────────────
cat("=== 1. MC-ONLY ANALYSIS ===\n")
mc_graded <- mc %>% filter(mc_status == "Graded")
cat("N graded:", nrow(mc_graded), "/ 238 enrolled\n\n")

mc_stats <- mc_graded %>% summarise(
  min    = min(mc_score),
  q1     = quantile(mc_score, .25),
  median = median(mc_score),
  mean   = round(mean(mc_score), 1),
  q3     = quantile(mc_score, .75),
  max    = max(mc_score)
)
cat(sprintf("Score / %d:  min %g | Q1 %g | median %g | mean %g | Q3 %g | max %g\n",
            MC_MAX, mc_stats$min, mc_stats$q1, mc_stats$median,
            mc_stats$mean, mc_stats$q3, mc_stats$max))
cat(sprintf("As %%:        median %.1f%% | mean %.1f%%\n\n",
            mc_stats$median / MC_MAX * 100, mc_stats$mean / MC_MAX * 100))

cat("Senior MC scores:\n")
mc %>%
  filter(sis_user_id %in% SENIOR_SIDS) %>%
  mutate(name      = SENIOR_NAMES[sis_user_id],
         pct       = round(mc_score / MC_MAX * 100, 1),
         vs_median = round(mc_score - mc_stats$median, 1)) %>%
  select(name, mc_score, pct, vs_median, mc_version, mc_status) %>%
  arrange(desc(mc_score)) %>%
  print()

# ── 2. FR-ONLY ────────────────────────────────────────────────────────────────
cat("\n=== 2. FR-ONLY ANALYSIS ===\n")
fr_graded <- fr %>% filter(fr_status == "Graded")
cat("N graded:", nrow(fr_graded), "/ 238 enrolled")
cat("  *** Non-random sample — likely skews high ***\n\n")

fr_stats <- fr_graded %>% summarise(
  min    = min(fr_score),
  q1     = quantile(fr_score, .25),
  median = median(fr_score),
  mean   = round(mean(fr_score), 1),
  q3     = quantile(fr_score, .75),
  max    = max(fr_score)
)
cat(sprintf("Score / %d:  min %g | Q1 %g | median %g | mean %g | Q3 %g | max %g\n",
            FR_MAX, fr_stats$min, fr_stats$q1, fr_stats$median,
            fr_stats$mean, fr_stats$q3, fr_stats$max))
cat(sprintf("As %%:        median %.1f%% | mean %.1f%%\n\n",
            fr_stats$median / FR_MAX * 100, fr_stats$mean / FR_MAX * 100))

cat("Senior FR scores:\n")
fr %>%
  filter(sis_user_id %in% SENIOR_SIDS) %>%
  mutate(name      = SENIOR_NAMES[sis_user_id],
         pct       = round(fr_score / FR_MAX * 100, 1),
         vs_median = round(fr_score - fr_stats$median, 1)) %>%
  select(name, fr_score, pct, vs_median, fr_status) %>%
  arrange(desc(fr_score)) %>%
  print()

# ── 3. COMBINED ───────────────────────────────────────────────────────────────
cat("\n=== 3. COMBINED SCORE ANALYSIS (MC×4 + FR, max", EXAM_MAX, ") ===\n")
cat("N with both graded:", nrow(fe), "\n\n")

fe_stats <- fe %>% summarise(
  min    = min(raw_score),
  q1     = quantile(raw_score, .25),
  median = median(raw_score),
  mean   = round(mean(raw_score), 1),
  q3     = quantile(raw_score, .75),
  max    = max(raw_score)
)
cat(sprintf("Raw / %d:  min %g | Q1 %g | median %g | mean %g | Q3 %g | max %g\n",
            EXAM_MAX, fe_stats$min, fe_stats$q1, fe_stats$median,
            fe_stats$mean, fe_stats$q3, fe_stats$max))
cat(sprintf("As %%:      median %.1f%% | mean %.1f%%\n\n",
            fe_stats$median / EXAM_MAX * 100, fe_stats$mean / EXAM_MAX * 100))

cat("Top scores:\n")
fe %>%
  arrange(desc(raw_score)) %>%
  mutate(name = if_else(sis_user_id %in% SENIOR_SIDS,
                        paste0(SENIOR_NAMES[sis_user_id], " *"), sis_user_id),
         percentile = round(100 * percent_rank(raw_score))) %>%
  select(name, mc_score, fr_score, raw_score, raw_pct, curved_score, percentile) %>%
  head(10) %>%
  print()

cat("\nSenior combined scores:\n")
fe %>%
  filter(sis_user_id %in% SENIOR_SIDS) %>%
  mutate(name       = SENIOR_NAMES[sis_user_id],
         percentile = round(100 * percent_rank(raw_score)),
         vs_median  = round(raw_score - fe_stats$median, 1)) %>%
  select(name, mc_score, fr_score, raw_score, raw_pct, curved_score, percentile, vs_median) %>%
  arrange(desc(raw_score)) %>%
  print()
