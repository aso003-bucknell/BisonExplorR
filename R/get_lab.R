#' Copy an in-lab R script into your project
#'
#' In-lab exercises ship with BisonExplorR as plain R scripts. They live inside
#' the installed package, which is read-only, so this function copies one into
#' your current Posit Cloud project where you can open, edit, and run it with a
#' partner.
#'
#' Call `get_lab()` with no arguments to see which labs are available.
#'
#' @param lab Name of the lab script, without the `.R` extension
#'   (e.g. `"wrangle-visualize"`). If `NULL`, the available labs are listed.
#' @param overwrite Replace an existing copy in your project? Defaults to
#'   `FALSE` so you never lose work you've already done.
#'
#' @return (Invisibly) the path to the copied file, or the vector of available
#'   lab names when `lab = NULL`.
#' @export
#'
#' @examples
#' \dontrun{
#' get_lab()                       # list available labs
#' get_lab("wrangle-visualize")    # copy one into your project
#' }
get_lab <- function(lab = NULL, overwrite = FALSE) {

  lab_dir <- system.file("labs", package = "BisonExplorR")
  available <- sub("\\.R$", "", list.files(lab_dir, pattern = "\\.R$"))

  if (length(available) == 0) {
    stop("No lab scripts found in the package. ",
         "Is BisonExplorR installed with its inst/labs/ folder?",
         call. = FALSE)
  }

  # No lab named -> show what's available and stop here.
  if (is.null(lab)) {
    message("Available labs:\n  ", paste(available, collapse = "\n  "),
            "\n\nCopy one into your project with, for example:\n  ",
            "get_lab(\"", available[1], "\")")
    return(invisible(available))
  }

  lab <- sub("\\.R$", "", lab)

  if (!lab %in% available) {
    stop("There is no lab called \"", lab, "\".\nAvailable labs: ",
         paste(available, collapse = ", "), call. = FALSE)
  }

  src  <- file.path(lab_dir, paste0(lab, ".R"))
  dest <- file.path(getwd(), paste0(lab, ".R"))

  if (file.exists(dest) && !overwrite) {
    stop(basename(dest), " is already in your project.\n",
         "If you want to start over with a fresh copy, run:\n  ",
         "get_lab(\"", lab, "\", overwrite = TRUE)", call. = FALSE)
  }

  ok <- file.copy(src, dest, overwrite = overwrite)
  if (!ok) {
    stop("Could not copy the file. Check that you have write access to ",
         getwd(), call. = FALSE)
  }

  message("Copied ", basename(dest), " into your project. ",
          "Look for it in the Files pane.")

  # If we're in RStudio / Posit Cloud, open it in the editor.
  if (requireNamespace("rstudioapi", quietly = TRUE) &&
      rstudioapi::isAvailable()) {
    rstudioapi::navigateToFile(dest)
  }

  invisible(dest)
}
