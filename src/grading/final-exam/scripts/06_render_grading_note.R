  ## Render final exam grading note → PDF
  
  library(rmarkdown)
  library(here)
  
  rmd_file <- here("src/grading/final-exam/scripts/05_grading_note.Rmd")
  out_dir  <- here("src/grading/final-exam/outputs/reports")
  
  render(rmd_file,
         output_file = "econ1001-final-exam-grading-note.pdf",
         output_dir  = out_dir)
  
  message("Rendered: ", file.path(out_dir, "econ1001-final-exam-grading-note.pdf"))
  
