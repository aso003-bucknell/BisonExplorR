#' Open the graded (credit-bearing) version of a tutorial
#'
#' Each module has two ways in. `learnr::run_tutorial()` opens a **practice**
#' copy inside Posit Cloud — unlimited, ungraded, and encouraged. This function
#' opens the **deployed** copy in a browser tab, which is the one that logs
#' attempts for credit.
#'
#' Call `launch_graded_tutorial()` with no arguments to list the modules.
#'
#' @section Instructor note — the URL map:
#' `graded_urls` below is the only thing that needs editing when tutorials are
#' (re)deployed. Any module left as `NA_character_` raises an informative error
#' rather than opening a broken tab, so a half-deployed course fails loudly at
#' the module that is missing instead of silently everywhere.
#'
#' The names of `graded_urls` are `tutorial_id` values (`"module5"`), **not**
#' folder names (`"05-groups"`). Those are separate namespaces; see the seed
#' document. Student-facing input is normalised so all three of `"module5"`,
#' `"05-groups"`, and `5` reach the same entry.
#'
#' @param module Which module to open, e.g. `"module5"`. Also accepts the
#'   folder-style name (`"05-groups"`) or a bare number (`5`). If `NULL`, the
#'   available modules are listed.
#'
#' @return (Invisibly) the URL opened, or the vector of module ids when
#'   `module = NULL`.
#' @export
#'
#' @examples
#' \dontrun{
#' launch_graded_tutorial()           # list the modules
#' launch_graded_tutorial("module1")  # open Module 1 for credit
#' }
launch_graded_tutorial <- function(module = NULL) {

  # ── EDIT HERE ON DEPLOY ────────────────────────────────────────────────────
  # Names are tutorial_id values. NEVER change a name: every row already logged
  # carries that string, and grade_module() matches it literally.
  graded_urls <- c(
    module1  = NA_character_,   # 01-intro-to-r
    module2  = NA_character_,   # 02-data-import
    module3  = NA_character_,   # 03-refresher
    module4  = NA_character_,   # 04-wrangle-visualize
    module5  = NA_character_,   # 05-groups
    module6  = NA_character_,   # 06-regression
    module7  = NA_character_,   # 07-two-way-anova
    module8  = NA_character_,   # 08-ancova
    module9  = NA_character_,   # 09-choosing-a-test
    module10 = NA_character_    # 10-joining-data
  )
  # ───────────────────────────────────────────────────────────────────────────

  # Folder names, for translating student input and for readable listings.
  folders <- c(
    module1  = "01-intro-to-r",
    module2  = "02-data-import",
    module3  = "03-refresher",
    module4  = "04-wrangle-visualize",
    module5  = "05-groups",
    module6  = "06-regression",
    module7  = "07-two-way-anova",
    module8  = "08-ancova",
    module9  = "09-choosing-a-test",
    module10 = "10-joining-data"
  )

  ids <- names(graded_urls)

  if (is.null(module)) {
    message("Graded tutorials:\n  ",
            paste0(ids, "  (", folders[ids], ")", collapse = "\n  "),
            "\n\nOpen one for credit with, for example:\n  ",
            "launch_graded_tutorial(\"", ids[1], "\")")
    return(invisible(ids))
  }

  # ── Normalise what the student typed ───────────────────────────────────────
  # Anxious students mistype this constantly, and an unhelpful error here is a
  # support email. Accept "module5", "Module 5", "05-groups", "5", 5.
  key <- tolower(trimws(as.character(module)[1]))
  key <- gsub("[[:space:]]+", "", key)

  if (grepl("^[0-9]+$", key)) {
    key <- paste0("module", as.integer(key))
  } else if (key %in% unname(folders)) {
    key <- names(folders)[match(key, folders)]
  }

  if (!key %in% ids) {
    stop("There is no graded tutorial called \"", module, "\".\n",
         "Valid names are: ", paste(ids, collapse = ", "), "\n",
         "Run launch_graded_tutorial() with no arguments to see the full list.",
         call. = FALSE)
  }

  url <- unname(graded_urls[[key]])

  if (is.na(url) || !nzchar(url)) {
    stop("The graded version of ", key, " has not been deployed yet.\n",
         "You can still practise it — that version is ungraded but identical:\n  ",
         "learnr::run_tutorial(\"", folders[[key]], "\", package = \"BisonExplorR\")\n",
         "If this module was assigned for credit, let your instructor know.",
         call. = FALSE)
  }

  message("Opening the graded version of ", key, " in your browser.\n",
          "Remember to enter your student ID at the top — without it your work ",
          "cannot be matched to you for credit.")

  utils::browseURL(url)
  invisible(url)
}
