library(tidyverse)
library(readr)
library(stringr)
library(janitor)
library(broom)

MC_FILE <- "midterm1/raw/Midterm_1_Multiple_Choice_Part_Version_Set_Scores/Midterm_1_Multiple_Choice_Part_Version_Set_Scores.csv"
FR_FILE <- "midterm1/raw/Midterm_1_Free_Response_Part_scores.csv"

mc_scores <- read_csv(MC_FILE, show_col_types = FALSE) %>%
  clean_names() %>%
  select(sid, total_score, version) %>%
  transmute(
    sis_user_id = str_trim(as.character(sid)),
    mc_raw      = parse_number(as.character(total_score)),
    version     = factor(version)
  ) %>%
  filter(!is.na(sis_user_id))

fr_by_part <- read_csv(FR_FILE, show_col_types = FALSE) %>%
  clean_names() %>%
  rename(sis_user_id = sid) %>%
  select(sis_user_id, matches("^x\\d+_\\d+[a-z]_4_0_pts$")) %>%
  left_join(mc_scores, by = "sis_user_id")

fr_long <- fr_by_part %>%
  pivot_longer(
    cols = matches("^x\\d+_\\d+[a-z]_4_0_pts$"),
    names_to = "part_raw",
    values_to = "pts"
  ) %>%
  mutate(
    part = part_raw %>%
      str_replace("^x\\d+_", "") %>%
      str_replace("_4_0_pts$", ""),
    pts = as.numeric(pts)
  )

shares_by_version_part <- fr_long %>%
  filter(!is.na(pts)) %>%
  group_by(part, version) %>%
  summarise(
    n = n(),
    mean_pts  = mean(pts),
    share_4   = mean(pts == 4),
    share_ge2 = mean(pts >= 2),
    share_0   = mean(pts == 0),
    .groups = "drop"
  ) %>%
  arrange(part, version)

kw_by_part <- fr_long %>%
  filter(!is.na(pts)) %>%
  group_by(part) %>%
  summarise(p_value = kruskal.test(pts ~ version)$p.value, .groups = "drop") %>%
  mutate(p_adj = p.adjust(p_value, method = "BH")) %>%
  arrange(p_adj)

shares_by_version_part
kw_by_part



effect_sizes <- shares_by_version_part %>%
  filter(!is.na(version)) %>%
  group_by(part) %>%
  summarise(
    mean_min = min(mean_pts),
    mean_max = max(mean_pts),
    spread_pts = mean_max - mean_min,
    .groups = "drop"
  ) %>%
  arrange(desc(spread_pts))

effect_sizes
