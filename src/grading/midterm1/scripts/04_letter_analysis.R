library(tidyverse)

IN_CURVED  <- "_internal/kitchen/grading/midterm1/cooking/midterm1_curved.rds"
scores_curved <- read_rds(IN_CURVED)

curved_letters <- scores_curved %>%
  mutate(
    midterm1_letter = case_when(
      is.na(midterm1_curved) ~ NA_character_,
      
      midterm1_curved >= 97 ~ "A+",
      midterm1_curved >= 93 ~ "A",
      midterm1_curved >= 90 ~ "A-",
      midterm1_curved >= 87 ~ "B+",
      midterm1_curved >= 83 ~ "B",
      midterm1_curved >= 80 ~ "B-",
      midterm1_curved >= 77 ~ "C+",
      midterm1_curved >= 73 ~ "C",
      midterm1_curved >= 70 ~ "C-",
      midterm1_curved >= 67 ~ "D+",
      midterm1_curved >= 63 ~ "D",
      midterm1_curved >= 60 ~ "D-",
      TRUE ~ "F"
    ),
    midterm1_letter = factor(
      midterm1_letter,
      levels = c("A+","A","A-","B+","B","B-","C+","C","C-","D+","D","D-","F"),
      ordered = TRUE
    )
  )



curved_letters %>%
  count(midterm1_letter, sort = TRUE) %>%
  arrange(midterm1_letter) %>% 
  mutate(
    pct = n / sum(n) * 100,
    cum_n = cumsum(n),
    cum_pct   = cumsum(pct)
  )

