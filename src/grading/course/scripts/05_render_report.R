## Render internal course grades report → PDF

library(rmarkdown)
library(here)

rmd_file <- here("src/grading/course/scripts/04_internal_report.Rmd")
out_dir  <- here("src/grading/course/outputs/reports")

render(rmd_file,
       output_file = "econ1001-course-grades-internal-note.pdf",
       output_dir  = out_dir)

message("Rendered: ", file.path(out_dir, "econ1001-course-grades-internal-note.pdf"))
