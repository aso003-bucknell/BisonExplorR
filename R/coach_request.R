# Internal request and fallback helpers for the BisonExplorR Coach.
#
# The installed package never contacts a model provider directly. It either:
#   1. sends a small JSON payload to a secure instructor-controlled endpoint, or
#   2. uses a deterministic local hint while the interface is being piloted.

.bx_scalar_character <- function(x, default = "") {
  if (is.null(x) || length(x) == 0L || is.na(x[[1]])) {
    return(default)
  }
  as.character(x[[1]])
}

.bx_coach_endpoint <- function() {
  endpoint <- getOption("BisonExplorR.coach_url", "")
  if (!nzchar(endpoint)) {
    endpoint <- Sys.getenv("BISONEXPLORR_COACH_URL", unset = "")
  }
  trimws(endpoint)
}

.bx_coach_reply_is_unsafe <- function(reply) {
  if (!nzchar(reply)) {
    return(TRUE)
  }

  # The coach should not emit paste-ready code. This is intentionally generic:
  # no official exercise solution is stored in the package.
  has_fenced_code <- grepl("```", reply, fixed = TRUE)
  has_assignment <- grepl(
    "(?m)^\\s*[A-Za-z.][A-Za-z0-9._]*\\s*<-",
    reply,
    perl = TRUE
  )
  has_complete_model_call <- grepl(
    "(?i)(t\\.test|aov|lm|TukeyHSD)\\s*\\([^\\n]{0,180}~[^\\n]{0,180}data\\s*=",
    reply,
    perl = TRUE
  )

  has_fenced_code || has_assignment || has_complete_model_call
}

.bx_local_ttest_hint <- function(student_code, question = "", correct = FALSE) {
  code <- paste(student_code, collapse = "\n")
  code_no_comments <- gsub("#.*$", "", code)
  code_no_comments <- trimws(code_no_comments)
  question_lower <- tolower(question)

  has_ttest <- grepl("\\bt\\.test\\s*\\(", code_no_comments, perl = TRUE)
  has_formula <- grepl("~", code_no_comments, fixed = TRUE)

  # DATASET-AGNOSTIC as of 2026-07-23. This previously hardcoded the `cardio`
  # column names (resting_hr_bpm / sex), which broke when Module 5 was rebuilt
  # on algae data -- and this function is the DEFAULT path in pilot mode, so a
  # stale check here misleads on every attempt. Test the SHAPE of the formula,
  # never specific column names.
  formula_sides <- regmatches(
    code_no_comments,
    regexpr("[A-Za-z._][A-Za-z0-9._]*\\s*~\\s*[A-Za-z._][A-Za-z0-9._]*",
            code_no_comments, perl = TRUE)
  )
  has_both_sides <- length(formula_sides) > 0L

  if (isTRUE(correct)) {
    if (grepl("p[- ]?value", question_lower, perl = TRUE)) {
      return(
        "The p-value measures how surprising a difference this large would be if the two population means were actually equal. It does not tell you the probability that the null hypothesis is true."
      )
    }
    if (grepl("formula", question_lower, fixed = TRUE)) {
      return(
        "The formula states the roles of the variables: a numeric response is compared across categories supplied by the grouping factor. That structure lets R split the response into the two groups correctly."
      )
    }
    if (grepl("mean", question_lower, fixed = TRUE)) {
      return(
        "The two means summarize the average response in each group. Compare their direction, then use the p-value to judge whether the observed difference is statistically convincing."
      )
    }
    return(
      "Your code passed. Focus next on the p-value and the two group means: what biological claim can you make without turning the association into a claim of causation?"
    )
  }

  if (!nzchar(code_no_comments)) {
    return(
      "Start by identifying the numeric response and the categorical grouping variable. Which t-test form lets you place those on opposite sides of a tilde?"
    )
  }

  if (grepl("why", question_lower, fixed = TRUE) && grepl("formula", question_lower, fixed = TRUE)) {
    return(
      "The formula form tells R which numeric variable is the response and which categorical variable defines the groups. That is different from giving the test two separate numeric samples."
    )
  }

  if (!has_ttest) {
    return(
      "You have exactly two groups, so focus first on the test function used for a two-group comparison. Which function did the test-selection question identify?"
    )
  }

  if (!has_formula) {
    return(
      "You chose the right test function. In this course, a grouped t-test uses the formula interface, with the numeric response and grouping factor separated by a tilde."
    )
  }

  if (!has_both_sides) {
    return(
      "Your formula structure is moving in the right direction, but the tilde needs a named column on each side. Recheck the data reminder above the exercise: one column holds the numeric measurement, another holds the two groups."
    )
  }

  return(
    "Your test function and both variables are present. Now check their roles: the measured numeric response belongs on the left side of the formula, and the grouping factor belongs on the right."
  )
}

# ---------------------------------------------------------------------------
# Offline / pilot nudges, keyed by exercise_id.
#
# These ship inside the package and are therefore student-inspectable, so they
# are deliberately STRUCTURAL: they name a concept or point at what to
# reconsider, never a runnable line. Same contract as the online coach.
#
# Used whenever no endpoint is configured (pilot mode) or the endpoint fails.
# Keys must match exercise_registry.R on the server: "moduleN-qM".
# ---------------------------------------------------------------------------
.bx_offline_nudges <- list(

  "module1-q1" = list(
    blank = paste(
      "The exercise wants one column out of a dataframe, not the whole thing.",
      "Two pieces have to appear: the name of the dataframe, and the name of",
      "the column. What operator did the worked example just above put between",
      "them?"
    ),
    stuck = paste(
      "Check three things in order. First, is the dataframe named exactly as it",
      "appears in the reminder -- R is case-sensitive and will not guess.",
      "Second, is the column name spelled exactly as `str()` printed it,",
      "including the unit suffix. Third, is the dataframe on the left of the",
      "operator and the column on the right? Which of those three are you least",
      "sure about?"
    ),
    done = paste(
      "That worked. Notice what came back: a bare vector of numbers, not a",
      "one-column table. That distinction matters later -- most statistical",
      "functions in R want a vector for a single measurement and a dataframe",
      "when they need to see several columns at once. Which of those do you",
      "think a t-test needs?"
    )
  ),
  "module4-q5" = list(
    blank = "You need one row per group, not one row per animal. Which pair of verbs collapses a dataset that way?",
    stuck = "Check the standard error itself: it is the standard deviation divided by the square root of the group size. House style uses length() for that count.",
    done  = "Good. Now ask what an SE bar actually shows a reader, and why it is not the same as a standard deviation bar."
  ),
  "module4-q10" = list(
    blank = "Start with the plot you already know how to build, then add the fitted line as another layer.",
    stuck = "You need three things layered: the points, the straight-line fit, and the annotation that prints the equation and R-squared. Which of those is missing?",
    done  = "Good. Note that the annotation is drawing the same numbers you could get from summary() — the figure is reporting its own statistics."
  ),

  "module5-q3" = list(
    blank = "Three or more groups means the ANOVA family. Which function fits it, and which one reads it?",
    stuck = "Fitting the model and reading the model are two separate calls. And the post-hoc test runs on the fitted object, not on the summary of it.",
    done  = "Good. Now look at which specific pairs Tukey flags — is every pair significant, or only some? That is exactly why the post-hoc test exists."
  ),

  "module6-q2" = list(
    blank = "The formula has the same shape as the t-test you ran in Module 5: response on the left of the tilde, predictor on the right.",
    stuck = "Check two things: that the response and predictor are not swapped, and that the fit is wrapped in the function that prints the full readout.",
    done  = "Good. Four numbers in that output matter — slope, intercept, R-squared, and the p-value on the slope. Can you say what each one is for?"
  ),
  "module6-q4" = list(
    blank = "The summary object is a list. You can reach into it with the same operator you use to pull a column out of a data frame.",
    stuck = "You are close. Note there are two similarly named elements in that summary — one is adjusted, one is not. The exercise wants the unadjusted one.",
    done  = "Good. Remember R-squared answers a different question from the p-value: one is about how tightly the points hug the line, the other about whether the slope differs from zero."
  ),
  "module6-q5" = list(
    blank = "Build the scatter plot first, then add layers: one for the fitted line, one for the printed equation.",
    stuck = "Check which layer is missing. A line without an equation, or an equation without a line, will each fail differently.",
    done  = "Good. Compare the equation on the figure against the coefficients you extracted earlier — they should be the same two numbers."
  ),

  "module7-q1" = list(
    blank = "Two factors at once. The operator between them decides whether you also get their interaction.",
    stuck = "Check the operator joining your two factors. A plus fits main effects only; a star fits main effects and the interaction.",
    done  = "Good. Read the interaction row first — whether it is significant changes how you are allowed to read the two main effects."
  ),
  "module7-q3" = list(
    blank = "Look at the interaction row before either main-effect row. It sets the terms for everything else.",
    stuck = "Ask what a significant interaction would mean in plain language: does the effect of one factor stay the same across levels of the other?",
    done  = "Good. Say it as a biologist would: a non-significant interaction licenses you to describe each factor's effect on its own."
  ),

  "module8-q1" = list(
    blank = "Two predictors, but of different types — one measurement, one grouping factor. House style puts them in a specific order.",
    stuck = "Both terms may be present but in the wrong order. The covariate goes first, because terms are assigned variation sequentially.",
    done  = "Good. The factor's row is the payoff: it tests the group difference after the covariate has already been accounted for."
  ),
  "module8-q3" = list(
    blank = "You are checking whether the groups share a slope. That means fitting the model with an interaction rather than without one.",
    stuck = "Only one character needs to change in the formula. Which operator adds an interaction term?",
    done  = "Good — and note this is the rare case where a large p-value is the result you want. Report the simpler additive model, not this one."
  ),

  "module9-q1" = list(
    blank = "Do not write code yet. First classify: how many predictors, and is each one a factor or a measurement?",
    stuck = "Work the decision table in order. Count the predictors first, then ask the type of each. The function follows from those two answers.",
    done  = "Good. Try to state the rule you used in one sentence — that sentence is what you will need on the exam."
  ),
  "module9-q2" = list(
    blank = "One grouping factor. The only remaining question is how many levels it has.",
    stuck = "Count the levels of your factor. Two and three-or-more lead to different tests, and one of them needs a follow-up.",
    done  = "Good. If you ran the ANOVA family, check whether the scenario also needs a post-hoc test to answer the question as asked."
  ),
  "module9-q3" = list(
    blank = "Two predictors. The distinction that matters is the type of the second one, not the count.",
    stuck = "Ask whether your second predictor is a set of labels or a measured number. That single answer separates the two candidate tests.",
    done  = "Good. That type distinction is the one thing the capstone is really testing — make sure you could explain it without the table."
  ),

  "module10-q1" = list(
    blank = "You are protecting every row of one table while pulling matching columns from the other. Which table is the one being protected?",
    stuck = "Check that you have named the key column explicitly — house style never relies on the default matching.",
    done  = "Good. Now look at where the NAs landed and which rows disappeared entirely. Both tell you something about which table was protected."
  ),
  "module10-q4" = list(
    blank = "Before running it, predict the row count. Which table's rows does this join promise to keep?",
    stuck = "Rather than recalling the four names, reason it out: for this join, which side is guaranteed to survive intact?",
    done  = "Good. If you can predict row counts before running a join, you understand joins well enough for the exam."
  )
)

#' Choose the right offline hint for an exercise
#'
#' Dispatches on `exercise_id` so a stuck student gets a nudge about the
#' exercise they are actually attempting. Unknown ids fall back to a purely
#' structural prompt rather than inventing specifics about the wrong dataset.
#'
#' @keywords internal
.bx_local_hint <- function(exercise_id, student_code, question = "", correct = FALSE) {
  id <- .bx_scalar_character(exercise_id)

  # Module 5 q1 keeps its hand-written, code-aware specialist.
  if (identical(id, "module5-q1")) {
    return(.bx_local_ttest_hint(student_code, question, correct))
  }

  code <- trimws(gsub("#.*$", "", paste(student_code, collapse = "\n")))
  nudge <- .bx_offline_nudges[[id]]

  if (is.null(nudge)) {
    if (isTRUE(correct)) {
      return("Your code passed. Before moving on, say in one sentence what the result means biologically - and what it does not let you claim.")
    }
    if (!nzchar(code)) {
      return("Start from the shape of the task: what is the response, what is the predictor, and which function takes that pair? Sketch the shape before filling it in.")
    }
    return("Compare your code against the shape the exercise describes - the function, then the variables, then the order they appear in. Which of those three are you least sure about?")
  }

  if (isTRUE(correct)) return(nudge$done)
  if (!nzchar(code))   return(nudge$blank)
  nudge$stuck
}

#' Send one BisonExplorR Coach request
#'
#' This is an internal helper used by [coach_server()]. The secure endpoint is
#' configured with `options(BisonExplorR.coach_url = "https://...")` or the
#' `BISONEXPLORR_COACH_URL` environment variable. The endpoint must return JSON
#' containing a single `reply` field.
#'
#' When no endpoint is configured, or the endpoint cannot be reached, the
#' function returns a deterministic local hint so the tutorial interface can be
#' tested without exposing an API key.
#'
#' @keywords internal
coach_request <- function(
    exercise_id,
    student_code,
    question,
    correct = FALSE,
    timeout_seconds = 20) {

  endpoint <- .bx_coach_endpoint()

  if (!nzchar(endpoint)) {
    return(list(
      reply = .bx_local_hint(exercise_id, student_code, question, correct),
      mode = "pilot"
    ))
  }

  payload <- list(
    exercise_id = .bx_scalar_character(exercise_id),
    student_code = paste(student_code, collapse = "\n"),
    student_question = .bx_scalar_character(question),
    correct = isTRUE(correct)
  )

  response <- tryCatch(
    httr::POST(
      url = endpoint,
      body = payload,
      encode = "json",
      httr::timeout(timeout_seconds),
      httr::accept_json()
    ),
    error = function(e) e
  )

  if (inherits(response, "error") || httr::status_code(response) >= 300L) {
    return(list(
      reply = paste0(
        .bx_local_hint(exercise_id, student_code, question, correct),
        " The online coaching service was unavailable, so this is the built-in backup hint."
      ),
      mode = "fallback"
    ))
  }

  parsed <- tryCatch(
    httr::content(response, as = "parsed", type = "application/json", encoding = "UTF-8"),
    error = function(e) NULL
  )

  reply <- if (is.list(parsed)) .bx_scalar_character(parsed$reply) else ""
  reply <- trimws(reply)

  if (.bx_coach_reply_is_unsafe(reply)) {
    return(list(
      reply = paste0(
        .bx_local_hint(exercise_id, student_code, question, correct),
        " I replaced the online response because it was too close to paste-ready code."
      ),
      mode = "guarded-fallback"
    ))
  }

  list(
    reply = substr(reply, 1L, 900L),
    mode = "online"
  )
}

