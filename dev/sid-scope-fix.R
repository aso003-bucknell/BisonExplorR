## =====================================================================
##  SID SCOPE FIX — verified 2026-07-25, learnr 0.11.6
##
##  THE BUG. question() blocks are Shiny MODULES. The session handed to a
##  question_submission handler is namespaced — session$ns("") returns
##  "mc1-" — and its input$sid is EMPTY. The student ID lives on the ROOT
##  session. exercise_result receives the root session, which is why code
##  exercises logged correctly while every MC row logged "unknown" in the
##  same session, seconds apart.
##
##  IT FAILS SILENTLY. Nothing errors. Rows land in the sheet looking
##  perfectly well-formed, just unattributable, so grade_module() drops
##  them and every student loses the MC half of their score with no
##  warning anywhere.
##
##  PROBE OUTPUT THAT SETTLED IT:
##      session$input$sid                  <empty>
##      session$ns('')                     mc1-
##      session$rootScope()$input$sid      764876
##      session$userData$bx_sid            764876
##      session$parent$input$sid           <empty>
##
##  APPLY TO EVERY MODULE, not just M5. All ten register exercise_result;
##  M5 is only the first to register question_submission. Any module that
##  later grades MC items inherits this bug unless it uses bx_get_sid().
## =====================================================================


## ---------------------------------------------------------------------
##  PART 1 — add to the `setup` chunk, right after the `%||%` definition.
## ---------------------------------------------------------------------

# Resolve the student ID no matter which session scope a handler receives.
# Order matters: rootScope() is the verified path, userData is a belt-and-
# braces fallback (Shiny shares userData between a module scope and its
# parent by design), and the bare input$sid is last because it is the one
# that fails for MC items.
bx_get_sid <- function(session) {
  usable <- function(x) !is.null(x) && length(x) > 0 && nzchar(as.character(x)[1])

  sid <- tryCatch(session$rootScope()$input$sid, error = function(e) NULL)
  if (usable(sid)) return(sid)

  sid <- tryCatch(session$userData$bx_sid, error = function(e) NULL)
  if (usable(sid)) return(sid)

  sid <- tryCatch(session$input$sid, error = function(e) NULL)
  if (usable(sid)) return(sid)

  NULL   # log_attempt()'s %||% turns this into "unknown"
}


## ---------------------------------------------------------------------
##  PART 2 — REPLACE the whole `event-setup` chunk with this.
## ---------------------------------------------------------------------

```{r event-setup, context="server-start"}
# Code exercises. Correctness lives on data$feedback$correct here.
event_register_handler("exercise_result", function(session, event, data) {
  log_attempt(
    student_id  = bx_get_sid(session),
    exercise_id = data$label,
    correct     = data$feedback$correct
  )
})

# Multiple-choice items. This is what makes mc1-mc4 gradeable: without it
# question() blocks emit question_submission, nothing logs them, and
# grade_module() has no rows to score against.
#
# VERIFIED 2026-07-25 (learnr 0.11.6):
#   * correctness is on data$correct; data$feedback$correct is EMPTY here
#   * data$label is the CHUNK LABEL (mc1..mc4), which is what
#     grade_module() matches on
#   * session is a NAMESPACED MODULE SCOPE, so session$input$sid is empty —
#     bx_get_sid() climbs to the root session. Do not "simplify" this back
#     to session$input$sid; it fails silently and costs every student the
#     MC half of their score.
event_register_handler("question_submission", function(session, event, data) {
  correct_flag <- data$correct
  if (is.null(correct_flag) || length(correct_flag) == 0) {
    correct_flag <- data$feedback$correct
  }
  log_attempt(
    student_id  = bx_get_sid(session),
    exercise_id = data$label,
    correct     = correct_flag
  )
})
```


## ---------------------------------------------------------------------
##  PART 3 — OPTIONAL. Keep the userData observer as a live fallback.
##
##  Not required: rootScope() is verified and the fallback chain degrades
##  safely without it. Worth keeping only if you would rather have two
##  independent paths to the ID than one. If you keep it, add it to every
##  module; a fallback that exists in one module and not the others is
##  worse than no fallback, because it makes the failure inconsistent.
## ---------------------------------------------------------------------

```{r sid-cache, context="server"}
shiny::observeEvent(input$sid, {
  if (!is.null(input$sid) && nzchar(input$sid)) {
    session$userData$bx_sid <- input$sid
  }
}, ignoreInit = TRUE)
```


## ---------------------------------------------------------------------
##  AFTER APPLYING — remove the probe, reinstall, and re-verify:
##
##    system('grep -n "SID SCOPE PROBE\\|zz-sid-cache" inst/tutorials/05-groups/05-groups.Rmd')
##
##  Then relaunch, enter an ID, answer an MC item and submit a code
##  exercise, and confirm BOTH row types carry the real ID in the sheet.
## ---------------------------------------------------------------------
