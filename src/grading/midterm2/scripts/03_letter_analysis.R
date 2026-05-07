library(tidyverse)

IN_CURVED  <- "grading/midterm2/build/midterm2_curved.rds"
scores_curved <- read_rds(IN_CURVED)

curved_letters <- scores_curved %>%
  mutate(
    midterm2_letter = case_when(
      is.na(midterm2_curved) ~ NA_character_,
      
      midterm2_curved >= 97 ~ "A+",
      midterm2_curved >= 93 ~ "A",
      midterm2_curved >= 90 ~ "A-",
      midterm2_curved >= 87 ~ "B+",
      midterm2_curved >= 83 ~ "B",
      midterm2_curved >= 80 ~ "B-",
      midterm2_curved >= 77 ~ "C+",
      midterm2_curved >= 73 ~ "C",
      midterm2_curved >= 70 ~ "C-",
      midterm2_curved >= 67 ~ "D+",
      midterm2_curved >= 63 ~ "D",
      midterm2_curved >= 60 ~ "D-",
      TRUE ~ "F"
    ),
    midterm2_letter = factor(
      midterm2_letter,
      levels = c("A+","A","A-","B+","B","B-","C+","C","C-","D+","D","D-","F"),
      ordered = TRUE
    )
  )



curved_letters %>%
  count(midterm2_letter, sort = TRUE) %>%
  arrange(midterm2_letter) %>% 
  mutate(
    pct = n / sum(n) * 100,
    cum_n = cumsum(n),
    cum_pct   = cumsum(pct)
  )

