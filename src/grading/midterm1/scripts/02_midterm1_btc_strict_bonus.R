library(tidyverse)
library(readr)
library(janitor)
library(stringr)

DIR_STRICT <- "_internal/records/grading/midterm1/MC_bitcoin_problem_strict"
BONUS_OUT_RDS     <- "_internal/kitchen/grading/midterm1/cooking/btc_bonus.rds"

btc_map <- tribble(
  ~version, ~qnum,
  "A", 4,
  "B", 21,
  "C", 17,
  "D", 13,
  "E", 9
)



find_csv_for_version <- function(dir, version) {
  hits <- list.files(
    dir,
    pattern = paste0("Version_", version, "_scores\\.csv$"),
    full.names = TRUE
  )
  if (length(hits) != 1) stop("Could not uniquely find CSV for version ", version, " in ", dir)
  hits[[1]]
}

# robustly identify the bitcoin column for a given qnum
find_btc_col <- function(df, qnum) {
  # typical header: "4: Question 4 (1.0 pts)"
  pat <- paste0("^\\s*", qnum, "\\s*:\\s*Question\\s*", qnum, "\\b")
  hits <- names(df)[str_detect(names(df), regex(pat, ignore_case = TRUE))]
  if (length(hits) != 1) {
    stop("Could not uniquely identify bitcoin column for qnum=", qnum,
         "\nMatched: ", paste(hits, collapse = ", "))
  }
  hits[[1]]
}

read_btc_strict <- function(dir, version, qnum) {
  f <- find_csv_for_version(dir, version)
  df <- read_csv(f, show_col_types = FALSE) %>% clean_names()
  
  # clean_names() will turn "4: Question 4 (1.0 pts)" into something like:
  # "x4_question_4_1_0_pts"  (varies a bit, but we detect pre-clean too below)
  
  # If you want to detect on original names, read without clean_names first;
  # easiest: detect before clean, then clean.
  df_raw <- read_csv(f, show_col_types = FALSE)
  btc_col_raw <- find_btc_col(df_raw, qnum)
  
  df_raw %>%
    clean_names() %>%
    # map the raw btc column name to its cleaned name
    rename(btc = !!janitor::make_clean_names(btc_col_raw)) %>%
    transmute(
      sis_user_id = str_trim(as.character(sid)),
      version = version,
      qnum = qnum,
      btc_strict = as.integer(parse_number(as.character(btc)))
    ) %>%
    filter(!is.na(sis_user_id), !is.na(btc_strict))  # keeps 0/1, drops NA
}

btc_strict_all <- pmap_dfr(
  btc_map,
  ~ read_btc_strict(DIR_STRICT, ..1, ..2)
)

# bonus list = strictly correct (1)
btc_bonus <- btc_strict_all %>%
  filter(btc_strict == 1) %>%
  distinct(sis_user_id)

btc_bonus_flags <- btc_strict_all %>%
  group_by(sis_user_id) %>%
  summarise(
    bonus = as.integer(any(btc_strict == 1)),
    .groups = "drop"
  ) %>%
  arrange(sis_user_id)

write_rds(btc_bonus_flags, BONUS_OUT_RDS)
