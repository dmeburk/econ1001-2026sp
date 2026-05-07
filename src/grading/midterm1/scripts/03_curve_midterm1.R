#!/usr/bin/env Rscript

library(tidyverse)
library(janitor)
library(ggplot2)
library(scales)
library(glue)

ensure_dir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  stopifnot(dir.exists(path))
  invisible(path)
}

# ------------------------------------------------------------
# Inputs / outputs
# ------------------------------------------------------------
IN_RAW_MC      <- "_internal/kitchen/grading/midterm1/cooking/mc_raw.rds"
IN_RAW_FR     <- "_internal/kitchen/grading/midterm1/cooking/fr_raw.rds"
IN_BTC_BONUS <- "_internal/kitchen/grading/midterm1/cooking/btc_bonus.rds"

OUT_CURVED  <- "_internal/kitchen/grading/midterm1/cooking/midterm1_curved.rds"
OUT_FIG_RAW <- "_internal/kitchen/grading/midterm1/finished/summary/midterm1_raw_hist.png"
OUT_FIG_CUR <- "_internal/kitchen/grading/midterm1/finished/summary/midterm1_curved_hist.png"
OUT_STATS_RAW <- "_internal/kitchen/grading/midterm1/finished/summary/midterm1_raw_stats.csv"
OUT_STATS_CUR <- "_internal/kitchen/grading/midterm1/finished/summary/midterm1_curved_stats.csv"

# Ensure output dirs exist (inputs should already exist)
ensure_dir(dirname(OUT_CURVED))
ensure_dir(dirname(OUT_FIG_RAW))
ensure_dir(dirname(OUT_FIG_CUR))
ensure_dir(dirname(OUT_STATS_RAW))
ensure_dir(dirname(OUT_STATS_CUR))

stopifnot(file.exists(IN_RAW_MC))
stopifnot(file.exists(IN_RAW_FR))

# ------------------------------------------------------------
# Curve policy
# ------------------------------------------------------------
RAW_MAX       <- 112
TARGET_MEDIAN <- 85

CAP_FLOOR <- TRUE
MIN_SCORE <- 0
MAX_SCORE <- 100

# ------------------------------------------------------------
# Load + clean
# Expect: sis_user_id, midterm1_raw
# ------------------------------------------------------------
mc_scores <- read_rds(IN_RAW_MC)
fr_scores <- read_rds(IN_RAW_FR)
btc_bonus <- read_rds(IN_BTC_BONUS) # adjustment given for the best answer on bitcoin problem

scores <- full_join(
  mc_scores,
  fr_scores,
  by = "sis_user_id"
) %>% 
  left_join(btc_bonus, by = "sis_user_id") %>%
  mutate(
    mc_raw   = as.numeric(mc_raw),
    fr_raw   = as.numeric(fr_raw),
    mc_raw   = replace_na(mc_raw, 0),
    fr_raw   = replace_na(fr_raw, 0),
    raw = 4*mc_raw + fr_raw + 2*bonus,
  ) %>%
  filter(raw != 0)

# Optional: quick audit
audit <- scores %>%
  summarise(
    n = n(),
    n_missing_mc = sum(is.na(mc_raw)),
    n_missing_fr = sum(is.na(fr_raw)),
    n_zero_mc    = sum(!is.na(mc_raw) & mc_raw == 0),
    n_zero_fr    = sum(!is.na(fr_raw) & fr_raw == 0),
    n_zero_any   = sum((!is.na(mc_raw) & mc_raw == 0) | (!is.na(fr_raw) & fr_raw == 0))
  )
audit
zeros <- scores %>%
  filter((!is.na(mc_raw) & mc_raw == 0) | (!is.na(fr_raw) & fr_raw == 0)) %>%
  select(sis_user_id, version, mc_raw, fr_raw, raw)
zeros
if (any(scores$raw > RAW_MAX, na.rm = TRUE)) {
  bad <- scores %>% filter(raw > RAW_MAX) %>% slice_head(n = 10)
  stop(glue(
    "Found raw scores > RAW_MAX ({RAW_MAX}). First few offending rows:\n",
    paste(capture.output(print(bad)), collapse = "\n")
  ))
}

# Add pct + z
trim_p <- 0.05
raw_cut <- quantile(scores$raw, trim_p, na.rm = TRUE)
mu_trim <- scores %>%
  filter(!is.na(raw), raw >= raw_cut) %>%
  summarize(mu = mean(raw), sig = sd(raw)) %>%
  as.list()

scores <- scores %>%
  mutate(
    pct = round(raw / RAW_MAX * 100, 1),
    z   = (raw - mean(raw, na.rm = TRUE)) /
      sd(raw, na.rm = TRUE),
    z_adj = (raw - mu_trim$mu) / mu_trim$sig
  )

# ------------------------------------------------------------
# Summary stats (raw)
# ------------------------------------------------------------
raw_stats <- scores %>%
  summarise(
    n         = n(),
    mean_raw  = mean(raw, na.rm = TRUE),
    mean_pct  = mean(pct, na.rm = TRUE),
    mean_mc   = mean(mc_raw, na.rm = TRUE),
    mean_fr   = mean(fr_raw, na.rm = TRUE),
    sd_raw    = sd(raw, na.rm = TRUE),
    min_raw   = min(raw, na.rm = TRUE),
    p10_raw   = quantile(raw, 0.10, na.rm = TRUE),
    p25_raw   = quantile(raw, 0.25, na.rm = TRUE),
    med_raw   = median(raw, na.rm = TRUE),
    p75_raw   = quantile(raw, 0.75, na.rm = TRUE),
    p90_raw   = quantile(raw, 0.90, na.rm = TRUE),
    max_raw   = max(raw, na.rm = TRUE),
    n_max     = sum(raw == RAW_MAX, na.rm = TRUE)
  )

scores %>%
  summarise(n_108_112 = sum(raw >= 108 & raw < 112, na.rm = TRUE))
cat("\n=== Midterm 1 RAW summary ===\n")
print(raw_stats)
write_csv(raw_stats, OUT_STATS_RAW)

# Histogram diagnostic: use binwidth=1 for integer scores

p_raw <- scores %>%
  mutate(raw_for_hist = if_else(raw == 112, raw - .01, raw)) %>%
  ggplot(aes(x = raw_for_hist)) +
  geom_histogram(binwidth = 4, boundary = 0, color = "white", closed = "left") +
  geom_vline(xintercept = raw_stats$med_raw, linewidth = 0.8, linetype = "dashed") +
  annotate(
    "text",
    x = raw_stats$med_raw,
    y = Inf,
    label = "Median",
    vjust = 1.2,
    hjust = -0.1
  ) +
  scale_x_continuous(
    breaks = seq(24, RAW_MAX, 4),
    limits = c(24, RAW_MAX + 0.5)
  ) +
  labs(
    title = "Midterm 1 — Raw score distribution",
    x = "Raw score",
    y = "Count"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1))

p_raw

ggsave(OUT_FIG_RAW, p_raw, width = 7, height = 4, dpi = 200)


# ------------------------------------------------------------
# Curve 
# ------------------------------------------------------------
# Affine curve anchoring max + median ----
med_raw <- raw_stats$med_raw
if (isTRUE(all.equal(med_raw, RAW_MAX))) {
  stop("Median equals RAW_MAX; cannot anchor both median and max.")
}

# b <- (100 - TARGET_MEDIAN) / (RAW_MAX - med_raw)
# a <- 100 - b * RAW_MAX
# Fixed curve before any corrections:
a <- 30
b <- 0.625

curve_note <- glue("Affine: curved = {round(a, 4)} + {round(b, 4)} × raw (anchors: max→100, median→{TARGET_MEDIAN})")
scores_curved <- scores %>%
  mutate(
    midterm1_curved = a + b * raw,
    midterm1_curved = if (CAP_FLOOR) pmin(MAX_SCORE, pmax(MIN_SCORE, midterm1_curved)) else midterm1_curved
  )

# a = 30
# b = 0.625
# ------------------------------------------------------------
# Summary stats (curved)
# ------------------------------------------------------------
curved_stats <- scores_curved %>%
  summarise(
    n              = n(),
    mean           = mean(midterm1_curved, na.rm = TRUE),
    sd             = sd(midterm1_curved, na.rm = TRUE),
    min            = min(midterm1_curved, na.rm = TRUE),
    p10            = quantile(midterm1_curved, 0.10, na.rm = TRUE),
    p25            = quantile(midterm1_curved, 0.25, na.rm = TRUE),
    median         = median(midterm1_curved, na.rm = TRUE),
    p75            = quantile(midterm1_curved, 0.75, na.rm = TRUE),
    p90            = quantile(midterm1_curved, 0.90, na.rm = TRUE),
    max            = max(midterm1_curved, na.rm = TRUE),
    max_at_raw_max = max(midterm1_curved[raw == RAW_MAX], na.rm = TRUE)
  )

cat("\n=== Midterm 1 CURVED summary ===\n")
cat(glue("{curve_note}\n"))
print(curved_stats)
write_csv(curved_stats, OUT_STATS_CUR)

# Curved histogram
med_cur <- median(scores_curved$midterm1_curved, na.rm = TRUE)
p_cur <- scores_curved %>%
  ggplot(aes(x = midterm1_curved)) +
  geom_histogram(
    binwidth = 2,
    boundary = 0,
    closed = "left",
    color = "white"
  ) +
  geom_vline(xintercept = med_cur, linewidth = 0.8, linetype = "dashed") +
  annotate(
    "text",
    x = med_cur,
    y = Inf,
    label = "Median",
    vjust = 1.2,
    hjust = -0.1
  ) +
  scale_x_continuous(
    breaks = seq(50, 100, 10),
    limits = c(50, 100)
  ) +
  labs(
    title = "Midterm 1 — Curved Score Distribution",
    #subtitle = curve_note,
    x = "Curved Score",
    y = "Count"
  ) +
  theme_minimal(base_size = 12) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1))

p_cur
ggsave(OUT_FIG_CUR, p_cur, width = 7, height = 4, dpi = 200)

# ------------------------------------------------------------
# Save
# ------------------------------------------------------------
write_rds(scores_curved, OUT_CURVED)
cat(glue("\nWrote: {OUT_CURVED}\n"))
cat(glue("Wrote: {OUT_FIG_RAW}\n"))
cat(glue("Wrote: {OUT_FIG_CUR}\n"))
cat(glue("Wrote: {OUT_STATS_RAW}\n"))
cat(glue("Wrote: {OUT_STATS_CUR}\n"))
