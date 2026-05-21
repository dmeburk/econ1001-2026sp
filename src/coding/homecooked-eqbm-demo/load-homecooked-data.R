# R/load-homecooked-data.R
library(tidyverse)

load_homecooked_data <- function(path = "data/raw/homecooked-data-2026-01-21.csv") {
  
  read_csv(path, show_col_types = FALSE) %>%
    rename(
      name  = `What is your name or nickname?`,
      role  = `Are you a demander or a supplier?`,
      price = `What's your price? (If you are demander, what is the most you would pay for a homecooked meal; If you are a supplier, what's the least you would charge for a homecooked meal.) (Please put just a number--no $$$)`
    ) %>%
    mutate(
      price = parse_number(price),
      price = pmax(0, price),
      role  = str_to_lower(role)
    ) %>%
    drop_na(name, role, price)
}


# R/load-homecooked-data.R
library(tidyverse)

load_homecooked_data <- function(
    path = "data/raw/homecooked-data-2026-01-21.csv",
    target_n = NULL,
    seed = 1001
) {
  
  base <- read_csv(path, show_col_types = FALSE) %>%
    rename(
      name  = `What is your name or nickname?`,
      role  = `Are you a demander or a supplier?`,
      price = `What's your price? (If you are demander, what is the most you would pay for a homecooked meal; If you are a supplier, what's the least you would charge for a homecooked meal.) (Please put just a number--no $$$)`
    ) %>%
    mutate(
      price = parse_number(price),
      price = pmax(0, price),
      role  = str_to_lower(role)
    ) %>%
    drop_na(name, role, price)
  
  if (is.null(target_n) || nrow(base) >= target_n) {
    return(base)
  }
  
  set.seed(seed)
  
  n_extra <- target_n - nrow(base)
  
  extras <- base %>%
    slice_sample(n = n_extra, replace = TRUE) %>%
    mutate(
      name = paste0(name, " Jr.")
    )
  
  bind_rows(base, extras)
}