# BisonExplorR q1 Coach Pilot

This patch adds the first vertical slice of the BisonExplorR Coach to
Module 5, exercise `q1`.

## What this version does

- Keeps the existing learnr editor as the only place where students
  write code.
- Reads the latest submitted `q1` code with
  [`learnr::get_tutorial_state()`](https://pkgs.rstudio.com/learnr/reference/get_tutorial_state.html).
- Requires at least one submitted attempt before the coach buttons
  become useful.
- Gives one short hint at a time.
- Removes the paste-ready `q1` hint, solution button, and failure
  message.
- Adds one ungraded concept check with the label `q1_concept_check`; the
  graded lookup is now `module5 = c(q1:q4, mc1:mc4)` — the four MC items
  score via the `question_submission` handler added 2026-07-23.
- Runs immediately in transparent **pilot hints** mode without an AI
  account.
- Can later call a secure instructor-controlled endpoint without
  changing the UI.

## Files to copy

Copy these into the matching locations in the package:

``` text
R/coach_module.R
R/coach_request.R
inst/tutorials/05-groups/05-groups.Rmd
```

Do not copy an API key or provider credential into the package.

## DESCRIPTION additions

Add these packages to `Imports` if they are not already present:

``` text
shiny,
htmltools,
httr
```

The tutorial already depends on `learnr`, `gradethis`, and `ggplot2`.

Because the functions use qualified calls such as
[`shiny::moduleServer()`](https://rdrr.io/pkg/shiny/man/moduleServer.html),
no manual NAMESPACE editing is needed. Run:

``` r

devtools::document()
devtools::load_all()
learnr::run_tutorial("05-groups", package = "BisonExplorR", clean = TRUE)
```

`clean = TRUE` matters because learnr pre-renders the Rmd and otherwise
may show an older cached tutorial.

## First test sequence

1.  Open Module 5 and go to q1.
2.  Submit the starter code with blanks or another incorrect attempt.
3.  Confirm that the ordinary gradethis feedback appears.
4.  Click **I’m stuck** in the coach panel.
5.  Confirm that the coach refers to the submitted attempt but does not
    provide a complete line of code.
6.  Correct and resubmit q1.
7.  Confirm that the coach status changes to indicate the exercise
    passed.
8.  Complete the ungraded concept check.

## Connecting a secure endpoint later

Set the endpoint in the environment that runs the tutorial:

``` r

options(BisonExplorR.coach_url = "https://YOUR-SERVICE.example/coach")
```

or set:

``` text
BISONEXPLORR_COACH_URL=https://YOUR-SERVICE.example/coach
```

The package sends this JSON payload:

> ⚠️ **`exercise_id` keys are HYPHENATED** (`module5-q1`), matching the
> keys in `exercise_registry.R`. This is not cosmetic: `plumber.R` does
> a bare `exercise_context[[exercise_id]]` lookup with a `%||%`
> fallback, so an underscore key **does not error** — it silently
> returns the generic context and the coach gives plausible-sounding but
> unspecific advice. An earlier version of this document showed an
> underscore here.

``` json
{
  "exercise_id": "module5-q1",
  "student_code": "the latest submitted q1 code",
  "student_question": "the student's question",
  "correct": false
}
```

The endpoint returns:

``` json
{
  "reply": "One brief Socratic nudge."
}
```

The package blocks fenced code, assignment statements, and apparent
complete model calls. A real backend should still enforce stronger
prompt rules, output validation, request limits, and authentication.

## Deliberate limitations of this pilot

- Only Module 5 q1 is connected.
- The online request is synchronous, so a slow endpoint temporarily
  blocks that student’s Shiny session.
- Conversation history is kept only in the active tutorial session.
- No student identity or conversation is logged by these files.
- The local fallback understands the q1 t-test exercise only.
