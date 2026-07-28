#' Copy a practice exam's datasets into your project
#'
#' Practice exam datasets ship with BisonExplorR. They live inside the installed
#' package, which is read-only, so this function copies them into your current
#' Posit Cloud project where your code can read them.
#'
#' This deliberately mirrors how the real exam works. On exam day the CSVs are
#' already sitting in your project folder, so your code reads them by bare
#' filename:
#'
#' \preformatted{
#' turtles <- read.csv("turtle_growth.csv")
#' }
#'
#' Practising with \code{system.file()} instead would mean rehearsing a call you
#' will not use on exam day, so this function puts the files where the exam
#' expects them.
#'
#' Call \code{get_practice_exam()} with no arguments to see what is available.
#'
#' @param exam Name of the practice exam, e.g. \code{"exam2"}. If \code{NULL},
#'   the available practice exams are listed.
#' @param overwrite Replace files already in your project? Defaults to
#'   \code{FALSE} so you never clobber work in progress.
#'
#' @return (Invisibly) the paths of the copied files, or the vector of available
#'   practice exam names when \code{exam = NULL}.
#' @export
#'
#' @examples
#' \dontrun{
#' get_practice_exam()          # list available practice exams
#' get_practice_exam("exam2")   # copy exam 2's datasets into your project
#' }
get_practice_exam <- function(exam = NULL, overwrite = FALSE) {

  base_dir <- system.file("practice-exams", package = "BisonExplorR")

  if (!nzchar(base_dir) || !dir.exists(base_dir)) {
    stop("No practice exams found in the package. ",
         "Is BisonExplorR installed with its inst/practice-exams/ folder?",
         call. = FALSE)
  }

  available <- list.dirs(base_dir, full.names = FALSE, recursive = FALSE)
  available <- available[nzchar(available)]

  if (length(available) == 0) {
    stop("The practice-exams folder is empty. ",
         "Reinstall BisonExplorR, or ask your instructor.", call. = FALSE)
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
    stop("There is no practice exam called \"", exam, "\".\nAvailable: ",
         paste(available, collapse = ", "), call. = FALSE)
  }

  src_dir <- file.path(base_dir, exam)
  srcs    <- list.files(src_dir, pattern = "\\.csv$", full.names = TRUE)

  if (length(srcs) == 0) {
    stop("Practice exam \"", exam, "\" has no CSV files in the package.",
         call. = FALSE)
  }

  dests  <- file.path(getwd(), basename(srcs))
  exists <- file.exists(dests)

  # Refuse the whole copy rather than half of it -- a partial copy leaves the
  # student with some fresh files and some stale ones, which is worse than
  # either, and the failure would show up later as a confusing wrong answer.
  if (any(exists) && !overwrite) {
    stop("These files are already in your project:\n  ",
         paste(basename(dests[exists]), collapse = "\n  "),
         "\n\nIf you want to start over with fresh copies, run:\n  ",
         "get_practice_exam(\"", exam, "\", overwrite = TRUE)", call. = FALSE)
  }

  ok <- file.copy(srcs, dests, overwrite = overwrite)
  if (!all(ok)) {
    stop("Could not copy ", sum(!ok), " of ", length(ok),
         " files. Check that you have write access to ", getwd(),
         call. = FALSE)
  }

  message("Copied ", length(dests), " dataset",
          if (length(dests) == 1) "" else "s",
          " into your project:\n  ",
          paste(basename(dests), collapse = "\n  "),
          "\n\nRead them by filename, exactly as you will on exam day, e.g.\n  ",
          "dat <- read.csv(\"", basename(dests)[1], "\")")

  invisible(dests)
}
