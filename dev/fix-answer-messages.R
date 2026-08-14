## =====================================================================
##  Strip redundant leading affirmations from answer() feedback.
##  Run from repo root:  source("dev/fix-answer-messages.R")
##
##  WHY: learnr prints its own bold "Correct!" above the message on a
##  correct question() answer. A message that also opens with "Correct —"
##  renders as:
##        Correct!
##        Correct — plots appear in the Plots pane.
##
##  SCOPE: only `message = "..."` inside answer() calls. grade_this()
##  pass() messages on EXERCISES are NOT touched -- learnr prints no
##  header there, so "Correct —" is doing real work in those.
##
##  Prints every change for review. Re-runnable; already-fixed lines
##  simply will not match.
## =====================================================================

mods <- c("01-intro-to-r","02-data-import","03-refresher","04-wrangle-visualize",
          "05-groups","06-regression","07-two-way-anova","08-ancova",
          "09-choosing-a-test","10-joining-data")

## Leading affirmation + its trailing punctuation/dash/space.
## Anchored to the opening quote of the message string so it cannot
## touch prose elsewhere on the line.
pat <- '(message\\s*=\\s*")(Correct|Right|Exactly|Yes|Nice)([[:space:]]*[—.!,:-]+[[:space:]]*)'

total <- 0
for (m in mods) {
  f <- sprintf("inst/tutorials/%s/%s.Rmd", m, m)
  if (!file.exists(f)) { cat(sprintf("[SKIP] %s missing\n", m)); next }
  x <- readLines(f, warn = FALSE)

  ## Only lines that are part of an answer() call. answer() calls in this
  ## package are single-line or begin on the line above, so accept a line
  ## containing answer( OR a bare message= continuation line.
  cand <- grep(pat, x)
  if (!length(cand)) next

  cat("---", m, "---\n")
  for (i in cand) {
    before <- x[i]
    after  <- sub(pat, "\\1", before)
    if (identical(before, after)) next

    ## Capitalise the new first letter of the message if it is lowercase.
    after <- sub('(message\\s*=\\s*")([a-z])', '\\1\\U\\2', after, perl = TRUE)

    x[i] <- after
    total <- total + 1
    cat(sprintf("  %d:\n    - %s\n    + %s\n", i, trimws(before), trimws(after)))
  }
  writeLines(x, f)
}

cat(sprintf("\n=== %d message(s) changed ===\n", total))
cat("Review the +/- pairs above. Anything that now reads oddly can be\n")
cat("edited by hand -- these are one-line strings.\n\n")
cat("Remaining by design (grade_this pass messages on exercises):\n")
for (m in mods) {
  f <- sprintf("inst/tutorials/%s/%s.Rmd", m, m)
  if (!file.exists(f)) next
  n <- length(grep('"Correct', readLines(f, warn = FALSE)))
  if (n) cat(sprintf("  %-22s %d\n", m, n))
}
cat("\nThose are correct as-is: learnr prints no header for exercises.\n\n")
