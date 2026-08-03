#' Copy a practice exam's datasets into your project
#'
#' The practice R exams are written against a small set of CSV files. Those
#' files ship inside the installed package, which is read-only, so this function
#' copies them into your current Posit Cloud project where `read.csv()` can find
#' them with a bare filename — exactly as it will on exam day.
#'
#' Call `get_practice_exam()` with no arguments to see which practice exams are
#' available.
#'
#' @param exam Name of the practice exam, e.g. `"exam1"` or `"exam2"`. If
#'   `NULL`, the available practice exams are listed.
#' @param overwrite Replace copies already in your project? Defaults to `FALSE`
#'   so a second call never wipes out work in progress.
#'
#' @return (Invisibly) a character vector of the paths copied, or the vector of
#'   available exam names when `exam = NULL`.
#' @export
#'
#' @details
#' Only **practice** exam datasets are distributed this way. Real exam
#' documents, answer keys, and their CSVs are instructor-controlled and are
#' deliberately absent from the package — anything under `inst/` is readable by
#' any student through [system.file()], so that boundary is enforced by
#' placement rather than by convention.
#'
#' @seealso [get_lab()] for in-lab partner scripts.
#'
#' @examples
#' \dontrun{
#' get_practice_exam()         # list available practice exams
#' get_practice_exam("exam2")  # copy exam 2's datasets into your project
#' }
get_practice_exam <- function(exam = NULL, overwrite = FALSE) {

  root <- system.file("practice-exams", package = "BisonExplorR")

  available <- if (nzchar(root)) {
    sort(list.dirs(root, full.names = FALSE, recursive = FALSE))
  } else {
    character(0)
  }

  if (length(available) == 0) {
    stop("No practice exams found in the package.\n",
         "Is BisonExplorR installed with its inst/practice-exams/ folder?",
         call. = FALSE)
  }

  # No exam named -> show what's available and stop here.
  if (is.null(exam)) {
    message("Available practice exams:\n  ",
            paste(available, collapse = "\n  "),
            "\n\nCopy one's datasets into your project with, for example:\n  ",
            "get_practice_exam(\"", available[1], "\")")
    return(invisible(available))
  }

  if (!exam %in% available) {
    stop("There is no practice exam called \"", exam, "\".\n",
         "Available practice exams: ", paste(available, collapse = ", "),
         call. = FALSE)
  }

  src_dir <- file.path(root, exam)
  files   <- list.files(src_dir, pattern = "\\.csv$", full.names = TRUE)

  if (length(files) == 0) {
    stop("Practice exam \"", exam, "\" has no datasets to copy.", call. = FALSE)
  }

  dest <- file.path(getwd(), basename(files))

  # Check every destination BEFORE copying any, so a collision never leaves
  # the project half-populated.
  clash <- dest[file.exists(dest)]
  if (length(clash) > 0 && !overwrite) {
    stop(paste(basename(clash), collapse = ", "),
         if (length(clash) == 1) " is" else " are",
         " already in your project.\n",
         "If you want fresh copies, run:\n  ",
         "get_practice_exam(\"", exam, "\", overwrite = TRUE)", call. = FALSE)
  }

  ok <- file.copy(files, dest, overwrite = overwrite)
  if (!all(ok)) {
    stop("Could not copy ", sum(!ok), " of ", length(ok), " files. ",
         "Check that you have write access to ", getwd(), call. = FALSE)
  }

  message("Copied ", length(dest), " dataset",
          if (length(dest) == 1) "" else "s",
          " for ", exam, " into your project:\n  ",
          paste(basename(dest), collapse = "\n  "),
          "\n\nLoad one with, for example:\n  ",
          "d <- read.csv(\"", basename(dest)[1], "\")")

  invisible(dest)
}
