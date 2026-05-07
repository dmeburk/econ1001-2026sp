library(tidyverse)

IN_CURVED  <- "grading/midterm2/build/midterm2_curved.rds"
scores_curved <- read_rds(IN_CURVED)


df <- scores_curved %>%
  mutate(
    version = factor(version, levels = sort(unique(version))),
    mc_raw  = as.numeric(mc_raw),
    fr_raw  = as.numeric(fr_raw)
  ) %>%
  filter(!is.na(version))

summ_by_version <- df %>%
  group_by(version) %>%
  summarise(
    n = n(),
    mc_mean = mean(mc_raw, na.rm = TRUE),
    mc_sd   = sd(mc_raw, na.rm = TRUE),
    mc_med  = median(mc_raw, na.rm = TRUE),
    mc_p10  = quantile(mc_raw, 0.10, na.rm = TRUE),
    mc_p25  = quantile(mc_raw, 0.25, na.rm = TRUE),
    mc_p75  = quantile(mc_raw, 0.75, na.rm = TRUE),
    mc_p90  = quantile(mc_raw, 0.90, na.rm = TRUE),
    
    fr_mean = mean(fr_raw, na.rm = TRUE),
    fr_sd   = sd(fr_raw, na.rm = TRUE),
    fr_med  = median(fr_raw, na.rm = TRUE),
    fr_p10  = quantile(fr_raw, 0.10, na.rm = TRUE),
    fr_p25  = quantile(fr_raw, 0.25, na.rm = TRUE),
    fr_p75  = quantile(fr_raw, 0.75, na.rm = TRUE),
    fr_p90  = quantile(fr_raw, 0.90, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(version)

summ_by_version


# Optional: differences vs overall mean (handy for “is a version harder?”)
overall_mc <- mean(df$mc_raw, na.rm = TRUE)
overall_fr <- mean(df$fr_raw, na.rm = TRUE)

summ_diffs <- summ_by_version %>%
  transmute(
    version, n,
    mc_mean, mc_diff = mc_mean - overall_mc,
    fr_mean, fr_diff = fr_mean - overall_fr
  )

summ_diffs

# ---- 2) visuals (quick sanity checks) ----
df_long <- df %>%
  select(version, mc_raw, fr_raw) %>%
  pivot_longer(c(mc_raw, fr_raw), names_to = "component", values_to = "score")

ggplot(df_long, aes(x = version, y = score)) +
  geom_boxplot() +
  facet_wrap(~ component, scales = "free_y") +
  labs(title = "Scores by version", x = "Version", y = "Score")

ggplot(df_long, aes(x = score)) +
  geom_density() +
  facet_grid(component ~ version, scales = "free_x") +
  labs(title = "Score densities by version", x = "Score", y = "Density")

# ---- 3) inference (ANOVA + robust check) ----
# MC
fit_mc <- lm(mc_raw ~ version, data = df)
anova_mc <- anova(fit_mc)
kw_mc <- kruskal.test(mc_raw ~ version, data = df)

# FR
fit_fr <- lm(fr_raw ~ version, data = df)
anova_fr <- anova(fit_fr)
kw_fr <- kruskal.test(fr_raw ~ version, data = df)

list(
  anova_mc = anova_mc,
  kruskal_mc = kw_mc,
  anova_fr = anova_fr,
  kruskal_fr = kw_fr
)

# ---- 4) optional: pairwise comparisons if you see signal ----
# (Tukey on ANOVA; Wilcoxon on ranks)
tukey_mc <- TukeyHSD(aov(mc_raw ~ version, data = df))
tukey_fr <- TukeyHSD(aov(fr_raw ~ version, data = df))

tukey_mc
tukey_fr

pairwise_wilcox_mc <- pairwise.wilcox.test(df$mc_raw, df$version, p.adjust.method = "BH")
pairwise_wilcox_fr <- pairwise.wilcox.test(df$fr_raw, df$version, p.adjust.method = "BH")

pairwise_wilcox_mc
pairwise_wilcox_fr
