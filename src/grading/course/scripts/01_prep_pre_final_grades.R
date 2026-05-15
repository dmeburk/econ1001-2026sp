## ============================================================
## PREP PRE-FINAL GRADES — ECON 1001 (SPRING 2026)
## ============================================================
## Loads all non-final-exam components from Canvas gradebook:
##   PS average (drop 2 lowest, PS01–PS09, PS02 A+B combined)
##   Podcast grade (graded value; NA if ungraded)
##   Midterm 1 and 2 curved scores
##
## Weights (confirm against syllabus):
##   PS 10%  |  Podcast 5%  |  MT1 20%  |  MT2 25%  |  Final 40%
## ============================================================

library(tidyverse)
library(janitor)

ROOT         <- here::here()
CANVAS_FILE  <- file.path(ROOT, "src/grading/course/inputs/2026-05-15T0850_Grades-ECON-1001-01.csv")
OUTPUT       <- file.path(ROOT, "src/grading/course/build/pre_final_grades.rds")

PODCAST_MAX   <- 10   # cap: scores above this (e.g., 12) are floored to 10
PS_DROP_N     <- 2

# ── LOAD ──────────────────────────────────────────────────────────────────────
gb <- read_csv(CANVAS_FILE, show_col_types = FALSE) %>%
  clean_names() %>%
  filter(!is.na(sis_user_id))

# ── MIDTERM SCORES ─────────────────────────────────────────────────────────────
# Use Canvas official curved scores as source of truth
gb <- gb %>%
  mutate(
    midterm1 = parse_number(midterm_1_curved_score_1345941),
    midterm2 = parse_number(midterm_2_curved_score_1355117)
  )

# ── PODCAST ───────────────────────────────────────────────────────────────────
# Cap at PODCAST_MAX; NA if ungraded
gb <- gb %>%
  mutate(
    podcast_raw = parse_number(podcast_submission_submit_here_1365978),
    podcast     = if_else(!is.na(podcast_raw), pmin(podcast_raw, PODCAST_MAX), NA_real_)
  )

# AD HOC ADJUSTMENTS: manually assigned podcast scores
# jl3431 (Jessica Lee): score assigned individually (reason not recorded)
# The following 15 students: bumped from 10 → 12 (reason: excellent podcasts, judged by graders)
EXCELLENT_PODCAST_SIDS <- c(
  "js5604",  # Shen, Joyce        (Lukas B)
  "jku3",    # Urbanowicz, John   (Lukas B)
  "eas426",  # Shelton, Erin      (Ethan)
  "fkb8",    # Brenan, Finn       (Ethan)
  "gg850",   # Gao, Garrett       (Shlok, Group 33)
  "ls1772",  # Schwarz, Lorelei   (Shlok, Group 33)
  "ak2594",  # Kutsuzawa, Anan    (Nicolo, Group 12)
  "zz658",   # Zwart, Zoya        (Nicolo, Group 12)
  "ma2570",  # Adams, Maggie      (Saachi, Group 29)
  "jl3390",  # Lin, Johnny        (Saachi, Group 29)
  "mcm539",  # McGill, Maddie     (Saachi, Group 29)
  "cf981",   # Fenton, Claire     (Diana)
  "mq148",   # Quinterno, Marina  (Nate)
  "ps1436",  # Schanzenbach, Peter(Nate)
  "aks212",  # Smetana, Alex      (Caleb)
  "amd459",  # excellent podcast
  "lkm92",   # excellent podcast
  "ls1739"   # excellent podcast
)
gb <- gb %>%
  mutate(
    podcast = if_else(sis_user_id == "jl3431",  10, podcast),  # Lee, Jessica: individually assigned
    podcast = if_else(sis_user_id == "ejt71",   10, podcast),  # Thornton, Edward → same as Lytle, Dylan
    podcast = if_else(sis_user_id == "fb652",   10, podcast),  # Barry, Fatoumata → same as Ford, Rin
    podcast = if_else(sis_user_id == "mes478",  10, podcast),  # Santiago, Miranda → same as Chen, Julia
    podcast = if_else(sis_user_id %in% EXCELLENT_PODCAST_SIDS, podcast + 2, podcast)
  )

# AD HOC ADJUSTMENT: students with no podcast submission → score 0
# Flagged as unsubmitted for tracking in grading report.
gb <- gb %>%
  mutate(
    podcast_unsubmitted = is.na(podcast),
    podcast             = if_else(is.na(podcast), 0, podcast)
  )

# ── PS COLUMNS ────────────────────────────────────────────────────────────────
# Include: PS01, PS02 (A+B combined), PS03–PS09
# Exclude: PS00 math review credit, podcast, aggregate columns
PS_INCLUDE_PATTERN <- "^problem_set_(0[1-9]|[1-9])"
PS_EXCLUDE_PATTERN <- "problem_set_00|podcast|average|outdated"

all_ps_cols <- names(gb)[grepl("^problem_set", names(gb))]
ps_cols     <- all_ps_cols[
  grepl(PS_INCLUDE_PATTERN, all_ps_cols) &
    !grepl(PS_EXCLUDE_PATTERN, all_ps_cols)
]

gb <- gb %>% mutate(across(all_of(ps_cols), parse_number))

# Combine PS02 Part A (max 9) + Part B (max 1) into PS02 (max 10)
ps02a <- ps_cols[grepl("02_part_a", ps_cols)]
ps02b <- ps_cols[grepl("02_part_b", ps_cols)]
if (length(ps02a) == 1 && length(ps02b) == 1) {
  gb <- gb %>%
    mutate(ps02_combined = .data[[ps02a]] + .data[[ps02b]])
  ps_cols <- c(setdiff(ps_cols, c(ps02a, ps02b)), "ps02_combined")
}

cat("PS columns used in average (n =", length(ps_cols), "):\n")
cat(paste(" ", ps_cols, collapse = "\n"), "\n\n")

# ── PS AVERAGE (drop N lowest) ────────────────────────────────────────────────
gb <- gb %>%
  rowwise() %>%
  mutate(
    psavg = {
      scores <- c_across(all_of(ps_cols))
      scores <- scores[!is.na(scores)]
      if (length(scores) <= PS_DROP_N) NA_real_
      else round(mean(sort(scores)[-(1:PS_DROP_N)]), 2)
    }
  ) %>%
  ungroup()

# ── ASSEMBLE OUTPUT ───────────────────────────────────────────────────────────
pre_final <- gb %>%
  select(
    student, sis_user_id, sis_login_id,
    midterm1, midterm2,
    podcast_raw, podcast, podcast_unsubmitted,
    all_of(ps_cols), psavg
  )

# ── SUMMARY ───────────────────────────────────────────────────────────────────
cat("Pre-final grades (n =", nrow(pre_final), "):\n")
cat("\nPS average:\n"); print(summary(pre_final$psavg))
cat("\nMidterm 1:\n");  print(summary(pre_final$midterm1))
cat("\nMidterm 2:\n");  print(summary(pre_final$midterm2))
cat("\nPodcast:\n"); print(table(pre_final$podcast, useNA = "always"))

# ── SENIORS ───────────────────────────────────────────────────────────────────
SENIORS <- c("Melese", "Prasad", "Pavlonnis", "Glisk", "Bissell", "Jacquand")
seniors <- pre_final %>%
  filter(grepl(paste(SENIORS, collapse = "|"), student)) %>%
  select(student, psavg, podcast, midterm1, midterm2)

cat("\n── Seniors ──────────────────────────────────────────────\n")
print(seniors)

saveRDS(pre_final, OUTPUT)
message("\nSaved: ", OUTPUT)
