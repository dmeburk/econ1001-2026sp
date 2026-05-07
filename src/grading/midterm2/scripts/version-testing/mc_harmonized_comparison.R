library(tidyverse)
library(broom)
# 1. Load data
responses <- read_csv("grading/midterm2/inputs/Midterm_2_Multiple_Choice_Part_student_responses.csv") %>%
  filter(!is.na(`Student ID`)) # Keep only rows with an ID
mapping <- read_csv("exams/midterm2/inputs/version_order.csv")


responses_subset <- responses %>% filter(Status == "Graded") %>%
  select(`Student ID`, `Version`, contains("Question") & ends_with("Score"))

# 2. Reshape mapping to a lookup table
# Assuming 'version_a' is the canonical ID
mapping_long <- mapping %>%
  pivot_longer(cols = everything(), names_to = "Version_Name", values_to = "Canonical_ID") %>%
  mutate(
    Version = toupper(str_sub(Version_Name, -1)), # Extract 'A', 'B', etc.
    Question_Number = rep(1:21, each = 5)            
  )

# 3. Reshape student responses
responses_long <- responses_subset %>%
  select(`Student ID`, Version, contains("Score")) %>%
  pivot_longer(cols = contains("Score"), names_to = "Q_Col", values_to = "Score") %>%
  mutate(Question_Number = as.numeric(str_extract(Q_Col, "\\d+")))

# 4. Join and Harmonize
harmonized <- responses_long %>%
  left_join(mapping_long, by = c("Version", "Question_Number"))

# 5. Create the wide-format gradebook
final_gradebook <- harmonized %>%
  select(`Student ID`, Version, Canonical_ID, Score) %>%
  pivot_wider(names_from = Canonical_ID, values_from = Score, names_prefix = "Canonical_Q")

final_gradebook_wide <- final_gradebook %>% 
  mutate(Total_Score = rowSums(across(starts_with("Canonical_Q")), na.rm = TRUE)) %>%
  group_by(Version) %>% 
  summarize(across(c(starts_with("Canonical_Q"),Total_Score), \(x) mean(x, na.rm = TRUE)))



# 6. Prepare data for testing
# We'll use the 'harmonized' long data we already built
test_data <- harmonized %>%
  # Ensure we have the Total_Score per student joined back in
  left_join(
    final_gradebook %>% 
      mutate(Total_Score = rowSums(across(starts_with("Canonical_Q")), na.rm = TRUE)) %>%
      select(`Student ID`, Total_Score),
    by = "Student ID"
  )

# 7. Run T-Tests: Each version vs. The Rest of the Class
# We loop through each Version and each Question (plus Total_Score)
version_list <- c("A", "B", "C", "D", "E")
problem_list <- c(1:21, "Total_Score")

fairness_tests <- expand_grid(Ver = version_list, Prob = problem_list) %>%
  mutate(results = map2(Ver, Prob, function(v, p) {
    
    # Define our two groups for this specific problem
    group_this_version <- test_data %>% filter(Version == v, Canonical_ID == p) %>% pull(Score)
    if(p == "Total_Score") {
      # For total score, we just need one value per student
      group_this_version <- test_data %>% filter(Version == v) %>% distinct(`Student ID`, Total_Score) %>% pull(Total_Score)
      group_others <- test_data %>% filter(Version != v) %>% distinct(`Student ID`, Total_Score) %>% pull(Total_Score)
    } else {
      group_others <- test_data %>% filter(Version != v, Canonical_ID == p) %>% pull(Score)
    }
    
    # Perform t-test
    if(length(group_this_version) > 1) {
      t.test(group_this_version, group_others) %>% tidy()
    } else {
      NULL
    }
  })) %>%
  unnest(results) %>%
  select(Version = Ver, Problem = Prob, estimate, p_value = p.value)

# 8. View Significant Outliers (p < 0.05)
significant_diffs <- fairness_tests %>% filter(p_value < 0.05)



            