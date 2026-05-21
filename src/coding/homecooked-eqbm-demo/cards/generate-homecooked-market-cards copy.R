# ============================================================
# Generate printable market role cards (12 per page)
# ============================================================

library(tidyverse)
library(stringr)

# ---- Paths ----
template_path <- "cards/templates/cards-template-4x3.tex"
output_path   <- "cards/generated/homecooked-market-cards.tex"

# ---- Layout ----
cards_per_row  <- 3
rows_per_page  <- 4
cards_per_page <- cards_per_row * rows_per_page  # 12

# ---- Helper: escape LaTeX special characters ----
escape_latex <- function(x) {
  x %>%
    str_replace_all("\\\\", "\\\\textbackslash{}") %>%
    str_replace_all("([%&#_$])", "\\\\\\1") %>%
    str_replace_all("\\{", "\\\\{") %>%
    str_replace_all("\\}", "\\\\}")
}

# ---- Load data ----
homecooking_raw <- read_csv(
  "data/raw/homecooked-data-2026-01-21.csv",
  show_col_types = FALSE
)

cards <- homecooking_raw %>%
  rename(
    name  = `What is your name or nickname?`,
    role  = `Are you a demander or a supplier?`,
    price = `What's your price? (If you are demander, what is the most you would pay for a homecooked meal; If you are a supplier, what's the least you would charge for a homecooked meal.) (Please put just a number--no $$$)`
  ) %>%
  mutate(
    price = parse_number(price),
    price = pmax(0, price),
    role  = str_to_lower(role),
    role_label = if_else(
      role == "demander",
      "Buyer (WTP)",
      "Seller (WTA)"
    ),
    name = escape_latex(name)
  ) %>%
  select(name, role_label, price) %>%
  drop_na()

# ---- Build \card{...} strings ----
card_cmds <- cards %>%
  mutate(
    card = sprintf(
      "\\card{%s}{%s}{%s}",
      name,
      role_label,
      price
    )
  ) %>%
  pull(card)

# ---- Group into rows of 3 ----
card_rows <- split(card_cmds, ceiling(seq_along(card_cmds) / cards_per_row))

row_cmds <- map_chr(card_rows, function(row) {
  # pad last row if needed
  while (length(row) < cards_per_row) row <- c(row, "")
  sprintf(
    "\\cardrow{%s}{%s}{%s}",
    row[[1]], row[[2]], row[[3]]
  )
})

# ---- Insert page breaks every 4 rows ----
row_cmds <- map2_chr(
  row_cmds,
  seq_along(row_cmds),
  ~ if (.y %% rows_per_page == 0) paste0(.x, "\n\\newpage") else .x
)

# ---- Read template ----
template <- readLines(template_path, warn = FALSE)

start_idx <- which(str_detect(template, "BEGIN CARDS"))
end_idx   <- which(str_detect(template, "END CARDS"))

if (length(start_idx) != 1 || length(end_idx) != 1) {
  stop("BEGIN CARDS / END CARDS markers not found or not unique.")
}

# ---- Assemble final TeX ----
final_tex <- c(
  template[1:start_idx],
  row_cmds,
  template[end_idx:length(template)]
)

# ---- Write output ----
writeLines(final_tex, output_path)

message("cards.tex written successfully.")