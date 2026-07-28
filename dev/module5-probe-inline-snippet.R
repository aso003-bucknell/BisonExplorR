## TEMPORARY — paste these two chunks near the END of
## inst/tutorials/05-groups/05-groups.Rmd, then launch the way students do:
##
##     learnr::run_tutorial("05-groups", package = "BisonExplorR", clean = TRUE)
##
## Submit q1, scroll to the bottom, read the dump, record the field name
## and the learnr version in the seed. THEN DELETE BOTH CHUNKS.
##
## Why inline rather than the standalone dev/module5-state-probe.Rmd:
## this exercises the exact run_tutorial() launch path students use, which
## is the thing we are actually uncertain about.


## ---------------------------------------------------------------- ##
## chunk 1 — UI. Place inside a normal section, e.g. under "Where you landed"
## ---------------------------------------------------------------- ##

```{r zz-probe-ui, echo=FALSE}
shiny::actionButton("zz_refresh", "DIAGNOSTIC: dump q1 state", class = "btn-warning")
shiny::verbatimTextOutput("zz_state_dump")
```


## ---------------------------------------------------------------- ##
## chunk 2 — server. Place next to the existing coach-server chunk.
## ---------------------------------------------------------------- ##

```{r zz-probe-server, context="server"}
output$zz_state_dump <- shiny::renderPrint({
  input$zz_refresh
  st <- tryCatch(learnr::get_tutorial_state("q1"), error = function(e) e)

  cat("learnr:", as.character(utils::packageVersion("learnr")), "\n")

  if (inherits(st, "error")) {
    cat("ERRORED:", conditionMessage(st), "\n"); return(invisible(NULL))
  }
  if (is.null(st)) {
    cat("NULL - submit q1 first. If still NULL, state is not keyed by the\n",
        "raw chunk label, and coach_server()'s reactive is wrong.\n")
    return(invisible(NULL))
  }

  cat("names(st):", paste(names(st), collapse = ", "), "\n\n")
  for (nm in names(st)) {
    v <- st[[nm]]
    if (is.character(v) && length(v) == 1 && nzchar(v)) {
      cat(sprintf("  $%-12s <chr> %s\n", nm, substr(gsub("\n", " ", v), 1, 60)))
    } else {
      cat(sprintf("  $%-12s <%s len %d>\n", nm,
                  paste(class(v), collapse = "/"), length(v)))
    }
  }

  cat("\ncandidates:\n")
  for (cand in c("answer", "code", "user_code", "submission", "value", "input")) {
    cat(sprintf("  $%-11s %s\n", cand,
                if (cand %in% names(st)) "PRESENT  <--" else "absent"))
  }
})
```


## ---------------------------------------------------------------- ##
## ---------------------------------------------------------------- ##
## chunk 3 — MC payload probe. Add this ONLY if you are grading mc1-mc4.
## Put it in a context="server-start" chunk (next to the existing handlers).
##
## Why: correctness for question_submission is assumed to be data$correct,
## NOT data$feedback$correct as for exercises. That has never been verified.
## If it is wrong, every MC row logs NA and each student silently loses 4 of
## 8 points on Module 5 with no error anywhere.
## ---------------------------------------------------------------- ##

```{r zz-mc-probe, context="server-start"}
event_register_handler("question_submission", function(session, event, data) {
  message("---- MC PAYLOAD PROBE ----")
  message("  names(data): ", paste(names(data), collapse = ", "))
  message("  data$label            = ", paste(data$label, collapse = ", "))
  message("  data$correct          = ", paste(data$correct, collapse = ", "))
  message("  data$feedback$correct = ", paste(data$feedback$correct, collapse = ", "))
  message("  -> whichever prints TRUE/FALSE (not blank) is the right field")
})
```

## Answer an MC item, then read the R console. Confirm:
##   * data$label is the CHUNK LABEL (mc1..mc4), not the question text --
##     grade_module() matches on the label, so anything else scores zero.
##   * one of the two correct fields holds TRUE/FALSE.
## Then check the Google Sheet: 8 distinct exercise values per student
## (q1-q4, mc1-mc4). If only q1-q4 appear, the handler is not firing.


## ---------------------------------------------------------------- ##
## AFTER RUNNING — remove ALL probe chunks. A quick way to confirm they are gone:
##
##   grep -n "zz-probe\|zz-mc-probe" inst/tutorials/05-groups/05-groups.Rmd
##
## Anything returned means diagnostic code is still in a student-facing file.
## ---------------------------------------------------------------- ##
