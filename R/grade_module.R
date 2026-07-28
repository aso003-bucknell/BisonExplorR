#' Grade a BisonExplorR tutorial module from logged responses
#'
#' Reads the CSV exported from the Google Sheet that the tutorials log to,
#' scores each student on **completion** and **correctness** for one module,
#' and writes a spreadsheet with one worksheet per section.
#'
#' Each tutorial exercise logs a row every time a student **Runs** or
#' **Submits** code. A Run has no grading feedback, so its `correct` value is
#' blank; a Submit records `TRUE`/`FALSE`. The two scores use that distinction:
#'
#' * **Completion** (default 5 pts): the fraction of the module's exercises for
#'   which the student made at least one real submission (a non-blank `correct`).
#' * **Correctness** (default 5 pts): the fraction of the module's exercises the
#'   student answered correctly at least once (any `TRUE`).
#'
#' @param responses Path to the exported responses CSV, or a data.frame.
#' @param module    The `tutorial_id` value to grade, e.g. `"module4"`.
#' @param roster    Optional. Path to a CSV (or a data.frame) linking students to
#'   sections. Needs a student-id column and a section column (see `roster_cols`).
#'   When supplied, every rostered student appears in the output even if they
#'   have no logged activity (they score 0), and output is split one sheet per
#'   section. Students in the log but not on the roster land on an `UNMATCHED`
#'   sheet.
#' @param exercises Optional. Either an integer count of exercises in the module,
#'   or a character vector of the expected exercise IDs. If `NULL`, the function
#'   uses the built-in `module_exercises` lookup, and if the module isn't there,
#'   falls back to the distinct exercise IDs seen in the data (with a warning).
#' @param completion_points,correctness_points Points each half is worth.
#' @param output Filename stem (or path) for the CSVs. One CSV is written per
#'   section, plus an `ALL` CSV and (if any) an `UNMATCHED` CSV. Any extension is
#'   ignored. If `NULL`, a stem is generated in the working directory.
#' @param roster_cols Named list giving the student-id and section column names
#'   in the roster, e.g. `list(student = "student_id", section = "section")`.
#'
#' @return (Invisibly) the full per-student grade data.frame. Also writes a file.
#' @export
grade_module <- function(responses,
                         module,
                         roster = NULL,
                         exercises = NULL,
                         completion_points = 5,
                         correctness_points = 5,
                         output = NULL,
                         roster_cols = list(student = "student_id",
                                            section = "section")) {

  ## ---- built-in module -> expected exercise IDs -------------------------
  ## Edit these to match each deployed tutorial. Confirm the counts before a
  ## grading run; a wrong denominator silently mis-scales every score.
  ## VERIFIED 2026-07-23 against the actual .Rmd chunk labels. Every entry
  ## below was confirmed by scanning each file for `exercise=TRUE` chunks that
  ## have a matching `-check` chunk. Do not edit from memory -- re-scan.
  ##
  ## NOTE ON LABEL STYLE: the 203-side modules (1, 2) use descriptive chunk
  ## labels; the 204-side modules use qN. grade_module() does not care -- it
  ## matches the logged `data$label` against these strings literally. The
  ## descriptive names also read better in the per-student output CSV
  ## ("dollar-exercise" says more to a co-instructor than "q8").
  module_exercises <- list(
    ## 9 exercises, descriptive labels. The three *-quiz-check chunks are
    ## question() blocks with no exercise chunk -- they emit question_submission,
    ## not exercise_result, so they cannot score and are correctly absent here.
    module1  = c("assign-exercise", "class-demo", "confirm-load",
                 "head-exercise", "str-exercise", "summary-exercise",
                 "str-review", "dollar-demo", "dollar-exercise"),

    ## 8 exercises, all with working -check chunks. Despite the "-quiz" names,
    ## these are exercise=TRUE code chunks and DO score. Grade or not is a
    ## policy call; the denominator is correct if you do.
    module2  = c("account-quiz", "section-link-quiz", "project-quiz",
                 "import-practice", "head-lab-data", "str-lab-data",
                 "summary-lab-data", "first-plot"),

    ## The six review-* chunks DO have graders, but are excluded by design --
    ## the 203 recap is formative. This means the M3 grade rests on 2 exercises.
    module3  = paste0("q", 7:8),
    module4  = paste0("q", 1:11),   # joins lifted to M10; regression line + ggsave added
    ## 8 items: 4 code exercises + 4 MC. The MC items score ONLY because
    ## 05-groups.Rmd registers a question_submission handler -- question()
    ## blocks emit that event, not exercise_result. Any module without
    ## that handler cannot grade its MC items no matter what is listed here.
    module5  = c(paste0("q", 1:4), paste0("mc", 1:4)),
    module6  = paste0("q", 1:5),    # continuous: linear regression
    module7  = paste0("q", 1:3),    # two factors: two-way ANOVA
    module8  = paste0("q", 1:4),   # q4 = plot_grid, ADDED 2026-07-28
    module9  = paste0("q", 1:3),    # capstone: choosing the right test
    module10 = paste0("q", 1:5)     # joining data
  )

  ## ---- read + normalize the response log --------------------------------
  resp <- if (is.data.frame(responses)) responses else
    utils::read.csv(responses, stringsAsFactors = FALSE, check.names = FALSE)

  find_col <- function(df, patterns) {
    nm <- names(df)
    for (p in patterns) {
      hit <- grep(p, nm, ignore.case = TRUE)
      if (length(hit)) return(nm[hit[1]])
    }
    NA_character_
  }
  ## Prefer a column literally named tutorial_id/exercise_id over the auto
  ## Google "Timestamp" etc. student pattern excludes "id" alone to avoid
  ## grabbing tutorial_id/exercise_id.
  col_student  <- find_col(resp, c("^student", "student.?id"))
  col_tutorial <- find_col(resp, c("^tutorial", "tutorial.?id", "^module"))
  col_exercise <- find_col(resp, c("^exercise", "exercise.?id", "label"))
  col_correct  <- find_col(resp, c("^correct", "correct"))

  miss <- c(student = col_student, tutorial = col_tutorial,
            exercise = col_exercise, correct = col_correct)
  if (anyNA(miss)) {
    stop("Could not auto-detect column(s): ",
         paste(names(miss)[is.na(miss)], collapse = ", "),
         ".\nColumns found: ", paste(names(resp), collapse = ", "),
         call. = FALSE)
  }

  norm_id <- function(x) tolower(trimws(as.character(x)))

  log <- data.frame(
    student  = norm_id(resp[[col_student]]),
    tutorial = trimws(as.character(resp[[col_tutorial]])),
    exercise = trimws(as.character(resp[[col_exercise]])),
    correct  = resp[[col_correct]],
    stringsAsFactors = FALSE
  )

  ## keep only this module
  log <- log[log$tutorial == module, , drop = FALSE]
  if (nrow(log) == 0)
    stop("No rows with tutorial_id == \"", module, "\".", call. = FALSE)

  ## parse `correct`: TRUE / FALSE / NA(=a Run, no grade)
  parse_correct <- function(x) {
    s <- tolower(trimws(as.character(x)))
    out <- rep(NA, length(s))
    out[s %in% c("true", "t", "1", "yes")]  <- TRUE
    out[s %in% c("false", "f", "0", "no")]  <- FALSE
    out  # blank/"na"/"unknown"/"" stay NA
  }
  log$correct <- parse_correct(log$correct)

  ## drop non-real ids
  bad_id <- log$student %in% c("", "unknown", "na")
  dropped_ids <- sum(bad_id)
  log <- log[!bad_id, , drop = FALSE]

  ## ---- determine the exercise denominator -------------------------------
  seen_ex <- sort(unique(log$exercise))
  if (is.null(exercises)) {
    if (!is.null(module_exercises[[module]])) {
      expected_ex <- module_exercises[[module]]
    } else {
      expected_ex <- seen_ex
      warning("Module \"", module, "\" not in the built-in lookup; using the ",
              length(expected_ex), " exercise IDs seen in the data as the ",
              "denominator. Pass `exercises=` to be explicit.", call. = FALSE)
    }
  } else if (is.numeric(exercises)) {
    ## integer count: build placeholder ids, score against observed engagement
    expected_ex <- NULL
    n_expected_override <- as.integer(exercises[1])
  } else {
    expected_ex <- as.character(exercises)
  }

  ## submissions only (correct is TRUE/FALSE) vs. any activity
  submitted <- log[!is.na(log$correct), , drop = FALSE]

  ## per-student, per-exercise rollups
  # attempted set: exercises with >=1 real submission
  att_tab <- unique(submitted[, c("student", "exercise")])
  # correct set: exercises with >=1 TRUE
  cor_tab <- unique(submitted[submitted$correct %in% TRUE,
                              c("student", "exercise")])

  ## restrict to expected exercises when we have an explicit set
  if (!is.null(expected_ex)) {
    att_tab <- att_tab[att_tab$exercise %in% expected_ex, , drop = FALSE]
    cor_tab <- cor_tab[cor_tab$exercise %in% expected_ex, , drop = FALSE]
    n_expected <- length(expected_ex)
  } else {
    n_expected <- n_expected_override
  }

  n_att <- tapply(att_tab$exercise, att_tab$student, length)
  n_cor <- tapply(cor_tab$exercise, cor_tab$student, length)

  ## ---- assemble the roster of students to score -------------------------
  if (!is.null(roster)) {
    ros <- if (is.data.frame(roster)) roster else
      utils::read.csv(roster, stringsAsFactors = FALSE, check.names = FALSE)
    rc_s <- find_col(ros, c(paste0("^", roster_cols$student, "$"),
                            "^student", "student.?id"))
    rc_sec <- find_col(ros, c(paste0("^", roster_cols$section, "$"),
                              "^section", "sect"))
    if (is.na(rc_s) || is.na(rc_sec))
      stop("Roster must have a student-id column and a section column.",
           call. = FALSE)
    students <- data.frame(student = norm_id(ros[[rc_s]]),
                           section = trimws(as.character(ros[[rc_sec]])),
                           stringsAsFactors = FALSE)
    students <- students[!duplicated(students$student), , drop = FALSE]
  } else {
    students <- data.frame(student = sort(unique(submitted$student)),
                           section = "(all)",
                           stringsAsFactors = FALSE)
  }

  ## also surface log students missing from the roster
  in_log <- sort(unique(submitted$student))
  unmatched <- setdiff(in_log, students$student)

  getn <- function(tab, id) { v <- tab[id]; if (is.na(v)) 0L else as.integer(v) }

  build_rows <- function(ids, section_label) {
    do.call(rbind, lapply(ids, function(id) {
      a <- getn(n_att, id); c <- getn(n_cor, id)
      comp <- round(a / n_expected * completion_points, 2)
      corr <- round(c / n_expected * correctness_points, 2)
      data.frame(student_id = id, section = section_label,
                 n_expected = n_expected, n_attempted = a, n_correct = c,
                 completion_score = comp, correctness_score = corr,
                 total_score = round(comp + corr, 2),
                 stringsAsFactors = FALSE)
    }))
  }

  grade_list <- lapply(split(students, students$section), function(df)
    build_rows(df$student, df$section[1]))
  grades <- do.call(rbind, grade_list)
  rownames(grades) <- NULL

  unmatched_df <- if (length(unmatched))
    build_rows(unmatched, "UNMATCHED") else NULL

  ## ---- write output (one CSV per section, + ALL, + UNMATCHED) -----------
  if (is.null(output))
    output <- paste0("grades_", module, "_", format(Sys.Date(), "%Y%m%d"))
  stem <- sub("\\.[A-Za-z0-9]+$", "", output)   # drop any extension

  ## Without a roster there are no real sections -- every student carries the
  ## placeholder section "(all)". Splitting on it would write a per-section
  ## file that is byte-identical to the ALL file (sanitised to "_-all-.csv"),
  ## so skip the split entirely in that case and write ALL only.
  sheets <- if (is.null(roster)) list() else split(grades, grades$section)
  sheets[["ALL"]] <- if (!is.null(unmatched_df))
    rbind(grades, unmatched_df) else grades
  if (!is.null(unmatched_df)) sheets[["UNMATCHED"]] <- unmatched_df

  wrote <- vapply(names(sheets), function(nm) {
    f <- paste0(stem, "_", gsub("[^A-Za-z0-9]+", "-", nm), ".csv")
    utils::write.csv(sheets[[nm]], f, row.names = FALSE)
    f
  }, character(1))

  message(sprintf(
    "Graded %d students on %s (%d exercises). %d unmatched, %d rows with a blank/unknown ID dropped.",
    nrow(grades), module, n_expected, length(unmatched), dropped_ids))
  message("Wrote: ", paste(wrote, collapse = ", "))

  invisible(if (!is.null(unmatched_df)) rbind(grades, unmatched_df) else grades)
}
