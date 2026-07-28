## =====================================================================
##  SID SCOPE PROBE — why does question_submission log "unknown"?
##
##  CONTEXT. In the 2026-07-25 pilot run, exercise_result captured the
##  student ID correctly while question_submission logged "unknown" in
##  the SAME session, seconds apart. So this is not a timing problem and
##  not a student-behaviour problem — the two handlers are seeing
##  different session objects.
##
##  HYPOTHESIS. learnr question() blocks are Shiny modules. The session
##  passed to a question_submission handler is the module's namespaced
##  scope, where input$sid does not exist; `sid` lives on the ROOT
##  session. exercise_result apparently receives the root session.
##
##  This probe tests that directly. Do not apply a fix until it reports.
##
##  WHERE. Paste inside the existing `event-setup` chunk in
##  inst/tutorials/05-groups/05-groups.Rmd, alongside the two handlers
##  already there. Relaunch with clean = TRUE, enter a student ID,
##  answer ONE multiple-choice item, then read the R CONSOLE.
## =====================================================================

event_register_handler("question_submission", function(session, event, data) {
  message("---- SID SCOPE PROBE ----")

  showit <- function(label, expr) {
    v <- tryCatch(expr, error = function(e) paste("ERROR:", conditionMessage(e)))
    if (is.null(v) || length(v) == 0) v <- "<empty>"
    message(sprintf("  %-34s %s", label, paste(v, collapse = ", ")))
  }

  # What we currently use, and what is failing.
  showit("session$input$sid",             session$input$sid)

  # Is this a namespaced module scope? A non-empty namespace prefix here
  # is the smoking gun for the hypothesis above.
  showit("session$ns('')",                session$ns(""))

  # Candidate 1: climb to the root session.
  showit("session$rootScope()$input$sid", session$rootScope()$input$sid)

  # Candidate 2: userData is SHARED between a module scope and its parent,
  # which makes it the robust cross-scope store if rootScope() is awkward.
  showit("session$userData$bx_sid",       session$userData$bx_sid)

  # Candidate 3: parent scope, one level up rather than all the way.
  showit("session$parent$input$sid",      session$parent$input$sid)

  # Sanity: confirm the payload itself is still shaped as expected.
  showit("data$label",                    data$label)
  showit("data$correct",                  data$correct)
})


## ---------------------------------------------------------------------
##  ALSO PASTE THIS — in a context="server" chunk (next to coach-server).
##
##  It populates userData$bx_sid so candidate 2 above has something to
##  find. If rootScope() turns out to work, this observer is unnecessary
##  and can be dropped; if it does NOT, this is the fix.
## ---------------------------------------------------------------------

# ```{r zz-sid-cache, context="server"}
# shiny::observeEvent(input$sid, {
#   if (!is.null(input$sid) && nzchar(input$sid)) {
#     session$userData$bx_sid <- input$sid
#   }
# }, ignoreInit = TRUE)
# ```


## ---------------------------------------------------------------------
##  HOW TO READ THE OUTPUT
##
##  session$ns('') non-empty  ->  hypothesis confirmed, it IS a module scope
##  rootScope() shows the ID  ->  fix is session$rootScope()$input$sid
##  userData shows the ID     ->  fix is the observer + session$userData$bx_sid
##                                (preferred if BOTH work: userData is shared
##                                 by design, rootScope() is more incidental)
##  ALL of them empty         ->  hypothesis wrong. Stop and rethink; do not
##                                ship a guess.
##
##  REMOVE THIS PROBE AFTERWARDS:
##    system('grep -n "SID SCOPE PROBE\\|zz-sid-cache" inst/tutorials/05-groups/05-groups.Rmd')
## ---------------------------------------------------------------------
