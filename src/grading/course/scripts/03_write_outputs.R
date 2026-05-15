## ============================================================
## WRITE OUTPUTS — ECON 1001 (SPRING 2026)
## ============================================================
## Writes:
##   1. Registrar template (Excel) with Final Grade filled in
##   2. Seniors-only registrar CSV for immediate submission
##   3. Canvas upload CSV (final exam curved/raw scores + PS average)
## ============================================================

library(tidyverse)
library(readxl)
library(writexl)

ROOT             <- here::here()
COURSE_RDS       <- file.path(ROOT, "src/grading/course/build/course_scores.rds")
FINAL_EXAM_RDS   <- file.path(ROOT, "src/grading/final-exam/build/final_exam_curved.rds")
CANVAS_FILE      <- file.path(ROOT, "src/grading/course/inputs/2026-05-15T0850_Grades-ECON-1001-01.csv")
REGISTRAR_TMPL   <- file.path(ROOT, "src/grading/course/inputs/202610_Economics_1001_01_Template.xlsx")
OUTPUT_REGISTRAR <- file.path(ROOT, "src/grading/course/outputs/202610_Economics_1001_01_Filled.xlsx")
OUTPUT_SENIORS   <- file.path(ROOT, "src/grading/course/outputs/seniors_grades.csv")
OUTPUT_CANVAS    <- file.path(ROOT, "src/grading/course/outputs/ECON1001_Spring2026_CanvasUpload.csv")

SENIOR_SIDS <- c("smm475", "cp1229", "ip281", "wag41", "smb436", "tlj64")

# Grade-point → letter-grade mapping
gp_to_letter <- function(gp) {
  case_when(
    gp == 4.00 ~ "A",
    gp == 3.67 ~ "A-",
    gp == 3.33 ~ "B+",
    gp == 3.00 ~ "B",
    gp == 2.67 ~ "B-",
    gp == 2.33 ~ "C+",
    gp == 2.00 ~ "C",
    gp == 1.67 ~ "C-",
    gp == 1.33 ~ "D+",
    gp == 1.00 ~ "D",
    gp == 0.00 ~ "F",
    TRUE        ~ NA_character_
  )
}

# ── LOAD COURSE SCORES ────────────────────────────────────────────────────────
course <- readRDS(COURSE_RDS) %>%
  mutate(letter_grade = gp_to_letter(adjusted_gp))

# ── LOAD REGISTRAR TEMPLATE ───────────────────────────────────────────────────
tmpl <- read_excel(REGISTRAR_TMPL)

# Fill in Final Grade by matching on student name.
# The registrar uses G-numbers as Student ID which don't align with Canvas
# SIS login IDs, so we join on cleaned full name instead.
# Step 1: exact match on cleaned name (Last, First [Middle])
# Step 2: fallback match on "Last, FirstWord" for students with middle names
course_grades <- course %>%
  transmute(
    name_exact  = tolower(trimws(student)),
    name_short  = tolower(sub("^(\\S+,\\s+\\S+).*", "\\1", trimws(student))),
    grade_exact = letter_grade,
    grade_short = letter_grade
  )

registrar <- tmpl %>%
  mutate(
    name_exact = tolower(trimws(gsub("[.]", "", `Full Name`))),
    name_short = tolower(sub("^(\\S+,\\s+\\S+).*", "\\1", trimws(gsub("[.]", "", `Full Name`))))
  ) %>%
  left_join(course_grades %>% select(name_exact, grade_exact), by = "name_exact") %>%
  left_join(course_grades %>% select(name_short, grade_short), by = "name_short") %>%
  mutate(`Final Grade` = coalesce(`Final Grade`, grade_exact, grade_short)) %>%
  select(-name_exact, -name_short, -grade_exact, -grade_short)

n_filled <- sum(!is.na(registrar$`Final Grade`))
message("Registrar: Final Grade filled for ", n_filled, " of ", nrow(registrar), " students.")

# ── SENIORS-ONLY REPORT ───────────────────────────────────────────────────────
seniors_out <- course %>%
  filter(sis_user_id %in% SENIOR_SIDS) %>%
  transmute(
    Student      = student,
    SIS_ID       = sis_user_id,
    PS_avg       = psavg,
    Podcast      = podcast,
    Midterm1     = midterm1,
    Midterm2     = midterm2,
    Final_exam   = final_exam,
    Course_S1    = round(course_score_s1, 1),
    Course_S2    = round(course_score_s2, 1),
    Course_score = course_score,
    GP           = adjusted_gp,
    Letter       = letter_grade
  ) %>%
  arrange(desc(Course_score))

cat("Senior grades:\n")
print(as.data.frame(seniors_out))

write_csv(seniors_out, OUTPUT_SENIORS)
message("Senior grades saved: ", OUTPUT_SENIORS)

# ── WRITE FILLED REGISTRAR EXCEL ──────────────────────────────────────────────
# writexl writes a fresh file (no in-place editing); formatting from template is not preserved
write_xlsx(registrar, OUTPUT_REGISTRAR)
message("Registrar Excel saved: ", OUTPUT_REGISTRAR)

# ── CANVAS UPLOAD CSV ─────────────────────────────────────────────────────────
# Pull the 7 Canvas identifier columns, then append final exam and PS scores.
canvas_ids <- read_csv(CANVAS_FILE, show_col_types = FALSE) %>%
  filter(!is.na(`SIS User ID`)) %>%
  select(1:7)

final_exam_scores <- readRDS(FINAL_EXAM_RDS) %>%
  transmute(
    `SIS User ID`  = sis_user_id,
    `final-curved` = curved_score,
    `final-raw`    = raw_score
  )

psavg_scores <- course %>%
  transmute(
    `SIS User ID` = sis_user_id,
    `psavg`       = psavg
  )

# Podcast scores: leave blank for unsubmitted students so they can still deliver
podcast_scores <- course %>%
  transmute(
    `SIS User ID` = sis_user_id,
    `podcast`     = if_else(podcast_unsubmitted, NA_real_, podcast)
  )

# Final grade point — informational column for students while registrar processes
letter_grades <- course %>%
  transmute(
    `SIS User ID` = sis_user_id,
    `gpa`         = adjusted_gp
  )

canvas_upload <- canvas_ids %>%
  left_join(final_exam_scores, by = "SIS User ID") %>%
  left_join(psavg_scores,      by = "SIS User ID") %>%
  left_join(podcast_scores,    by = "SIS User ID") %>%
  left_join(letter_grades,     by = "SIS User ID")

# Canvas-safe write (no trailing blank line)
write.table(canvas_upload, OUTPUT_CANVAS, sep = ",", row.names = FALSE,
            col.names = TRUE, quote = TRUE, fileEncoding = "UTF-8", eol = "\r\n")
lines <- readLines(OUTPUT_CANVAS, warn = FALSE)
while (length(lines) > 0 && lines[length(lines)] == "") lines <- lines[-length(lines)]
writeLines(lines, OUTPUT_CANVAS)

message("Canvas upload saved: ", OUTPUT_CANVAS)
