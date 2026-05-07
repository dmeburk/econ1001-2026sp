library(tidyverse)
library(officer)
library(flextable)
library(here)
library(readr)

ROOT <- here::here()

IN_CURVED <- file.path(ROOT, "_internal/kitchen/grading/midterm1/cooking/midterm1_curved.rds")
FIG_RAW   <- file.path(ROOT, "_internal/kitchen/grading/midterm1/finished/summary/midterm1_raw_hist.png")
FIG_CUR   <- file.path(ROOT, "_internal/kitchen/grading/midterm1/finished/summary/midterm1_curved_hist.png")
OUT_DOCX  <- file.path(ROOT, "_internal/kitchen/grading/midterm1/finished/reports/ECON1001_midterm1_grading_report_RAW.docx")

RAW_MAX <- 112

scores <- read_rds(IN_CURVED) %>%
  mutate(
    midterm1_raw    = as.numeric(raw),
    midterm1_curved = as.numeric(midterm1_curved)
  ) %>%
  filter(!is.na(midterm1_raw), !is.na(midterm1_curved))

make_stats_tbl <- function(x, raw_max = NULL, digits = 1) {
  
  n_obs <- sum(!is.na(x))
  
  stats <- c(
    n_obs,
    mean(x, na.rm = TRUE),
    sd(x, na.rm = TRUE),
    min(x, na.rm = TRUE),
    quantile(x, 0.10, na.rm = TRUE),
    quantile(x, 0.25, na.rm = TRUE),
    median(x, na.rm = TRUE),
    quantile(x, 0.75, na.rm = TRUE),
    quantile(x, 0.90, na.rm = TRUE),
    max(x, na.rm = TRUE)
  )
  
  labels <- c(
    "N",
    "Mean",
    "Standard deviation",
    "Minimum",
    "10th percentile",
    "25th percentile",
    "Median (50th percentile)",
    "75th percentile",
    "90th percentile",
    "Maximum"
  )
  
  if (!is.null(raw_max)) {
    stats  <- c(stats, sum(x == raw_max, na.rm = TRUE))
    labels <- c(labels, "Number of perfect scores")
  }
  
  tbl <- tibble(
    Statistic = labels,
    Value = stats
  ) %>%
    mutate(
      Value = if_else(
        Statistic %in% c("N", "Number of perfect scores"),
        as.character(as.integer(Value)),
        formatC(Value, format = "f", digits = digits)
      )
    )
  
  flextable::flextable(tbl) %>%
    flextable::autofit() %>%
    flextable::align(align = "left", part = "all")
}

raw_ft <- make_stats_tbl(scores$midterm1_raw, raw_max = RAW_MAX)
adj_ft <- make_stats_tbl(scores$midterm1_curved)

doc <- read_docx() %>%
  body_add_par("ECON 2110 — Midterm 1 Grading Note", style = "heading 1") %>%
  body_add_par("Spring 2026", style = "Normal") %>%
  body_add_par("", style = "Normal") %>%
  
  # ---- Note text (top) ----
body_add_par(
  "Midterm 1 had 112 total possible points. In Canvas, you will see your Midterm 1 — Raw Score (out of 112) and your Midterm 1 — Curved Score (out of 100). I will use your curved score when computing your course grade.",
  style = "Normal"
) %>%
  body_add_par(
    "You can interpret the curved score on the usual 0–100 scale. (I do not assign letter grades until the end of the course, but as a rough guide: 93+ ≈ A, 90–93 ≈ A-, 87–90 ≈ B+, and so on.)",
    style = "Normal"
  ) %>%
  # body_add_par(
  #   "For Midterm 1, your adjusted score is simply your raw score expressed as a percent:",
  #   style = "Normal"
  # ) %>%
  # body_add_par(
  #   "Adjusted = 100 × (Raw / 88).",
  #   style = "Normal"
  # ) %>%
  # body_add_par(
  #   "I did not apply an additional curve because the distribution of raw scores was already quite high.",
  #   style = "Normal"
  # ) %>%
  body_add_par("", style = "Normal") %>%
  
  # ---- Rest of your document ----
body_add_par("Raw Scores (out of 112): Summary Statistics", style = "heading 2") %>%
  body_add_flextable(raw_ft) %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("Raw Score Distribution", style = "heading 2") %>%
  body_add_img(src = FIG_RAW, width = 6.5, height = 3.7) %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("Curved Scores (out of 100): Summary Statistics", style = "heading 2") %>%
  body_add_flextable(adj_ft) %>%
  body_add_par("", style = "Normal") %>%
  body_add_par("Curved Score Distribution", style = "heading 2") %>%
  body_add_img(src = FIG_CUR, width = 6.5, height = 3.7)

dir.create(dirname(OUT_DOCX), recursive = TRUE, showWarnings = FALSE)
print(doc, target = OUT_DOCX)
cat("Wrote: ", OUT_DOCX, "\n", sep = "")