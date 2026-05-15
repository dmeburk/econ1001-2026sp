## Render final exam internal grading note → PDF

library(rmarkdown)
library(here)

rmd_file <- here("src/grading/final-exam/scripts/04_internal_report.Rmd")
out_dir  <- here("src/grading/final-exam/outputs/reports")

render(rmd_file,
       output_file    = "econ1001-final-exam-internal-note.pdf",
       output_dir     = out_dir,
       knit_root_dir  = here())

message("Rendered: ", file.path(out_dir, "econ1001-final-exam-internal-note.pdf"))
