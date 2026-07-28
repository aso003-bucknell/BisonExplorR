# Verify the final Module 5 integration. RUN FROM THE PACKAGE ROOT --
# the paths below are relative to it, not to this script's location:
#     source("dev/verify_module5.R")
#
# Updated 2026-07-23: folder settled as inst/tutorials/05-groups/;
# .bx_local_q1_hint renamed to .bx_local_ttest_hint (and made
# dataset-agnostic when M5 moved to algae data); MC items now genuinely
# graded via a question_submission handler.

tutorial_file <- "inst/tutorials/05-groups/05-groups.Rmd"
grader_file   <- "R/grade_module.R"
coach_ui_file <- "R/coach_module.R"
coach_req_file <- "R/coach_request.R"

required_files <- c(tutorial_file, grader_file, coach_ui_file, coach_req_file)
missing_files <- required_files[!file.exists(required_files)]

if (length(missing_files)) {
  stop(
    "Missing required file(s): ",
    paste(missing_files, collapse = ", "),
    call. = FALSE
  )
}

tutorial <- paste(readLines(tutorial_file, warn = FALSE), collapse = "\n")
grader   <- paste(readLines(grader_file, warn = FALSE), collapse = "\n")
coach_ui <- paste(readLines(coach_ui_file, warn = FALSE), collapse = "\n")
coach_req <- paste(readLines(coach_req_file, warn = FALSE), collapse = "\n")

checks <- c(
  student_id_box =
    grepl('textInput\\s*\\(\\s*"sid"', tutorial, perl = TRUE),
  exercise_tracking =
    grepl('event_register_handler\\("exercise_result"', tutorial),
  multiple_choice_tracking =
    grepl('event_register_handler\\("question_submission"', tutorial),
  google_form_module5 =
    grepl('"entry\\.1315894547"\\s*=\\s*"module5"', tutorial, perl = TRUE),
  coach_server =
    grepl('BisonExplorR::coach_server', tutorial, fixed = TRUE),
  coach_ui =
    grepl('BisonExplorR::coach_ui', tutorial, fixed = TRUE),
  coach_functions_exported =
    grepl("@export", coach_ui, fixed = TRUE) &&
    grepl("coach_ui <- function", coach_ui, fixed = TRUE) &&
    grepl("coach_server <- function", coach_ui, fixed = TRUE),
  local_coach_fallback =
    grepl(".bx_local_ttest_hint", coach_req, fixed = TRUE),
  # M5 moved to algae data; the fallback must not still name cardio columns.
  coach_fallback_not_stale =
    !grepl("resting_hr_bpm\\s*\\)", coach_req, perl = TRUE),
  code_items_q1_q4 =
    all(vapply(paste0("q", 1:4), function(id) {
      grepl(paste0("```\\{r ", id, ","), tutorial)
    }, logical(1))),
  mc_items_mc1_mc4 =
    all(vapply(paste0("mc", 1:4), function(id) {
      grepl(paste0("```\\{r ", id, ","), tutorial)
    }, logical(1))),
  grader_has_all_8 =
    grepl('paste0\\("q", 1:4\\)', grader, perl = TRUE) &&
    grepl('paste0\\("mc", 1:4\\)', grader, perl = TRUE),
  # Guard the dependency that makes MC grading work at all. Without the
  # question_submission handler the lookup above scores 4 phantom items and
  # silently caps every student at 50%.
  mc_handler_backs_the_lookup =
    grepl('event_register_handler\\("question_submission"', tutorial, perl = TRUE),
  # M5 is in the algae unit now, not the cardio unit.
  uses_algae_data =
    grepl("algae_beads.csv", tutorial, fixed = TRUE) &&
    !grepl("resting_hr_bpm", tutorial, fixed = TRUE)
)

print(checks)

if (!all(checks)) {
  stop(
    "Module 5 verification failed for: ",
    paste(names(checks)[!checks], collapse = ", "),
    call. = FALSE
  )
}

message(
  "PASS: Module 5 contains the student-ID box, Google Sheet tracking, ",
  "q1 coach, four code exercises, four graded multiple-choice questions, ",
  "and the matching grade_module() lookup."
)
