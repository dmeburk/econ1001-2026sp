library(tidyverse)

# 1. Load data
responses <- read_csv("Midterm_2_Multiple_Choice_Part_student_responses.csv")
mapping <- read_csv("version_order.csv")

# 2. Reshape mapping to a lookup table
# Assuming 'version_a' is the canonical ID
mapping_long <- mapping %>%
  pivot_longer(cols = everything(), names_to = "Version_Name", values_to = "Question_Number") %>%
  mutate(
    Version = toupper(str_sub(Version_Name, -1)), # Extract 'A', 'B', etc.
    Canonical_ID = rep(1:21, each = 5)            # Assign canonical ID based on rows
  )

# 3. Reshape student responses
responses_long <- responses %>%
  filter(Status == "Graded") %>%
  select(`First Name`, `Last Name`, `Student ID`, Version, contains("Score")) %>%
  pivot_longer(cols = contains("Score"), names_to = "Q_Col", values_to = "Score") %>%
  mutate(Question_Number = as.numeric(str_extract(Q_Col, "\\d+")))

# 4. Join and Harmonize
harmonized <- responses_long %>%
  left_join(mapping_long, by = c("Version", "Question_Number"))

# 5. Create the wide-format gradebook
final_gradebook <- harmonized %>%
  select(`First Name`, `Last Name`, `Student ID`, Version, Canonical_ID, Score) %>%
  pivot_wider(names_from = Canonical_ID, values_from = Score, names_prefix = "Canonical_Q")

write_csv(final_gradebook, "harmonized_student_scores.csv")