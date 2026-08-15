## =====================================================================
##  BisonExplorR -- M3 patch, findings 1 and 2
##  Run from repo root:  source("dev/m3-patch-1.R")
##
##  FINDING 1 -- orphaned sentence fragment.
##    03-refresher.Rmd carries a bare line reading "exercises you
##    complete." with no beginning. It is the first prose a student sees
##    after the ID box. In PRACTICE mode it directly follows a banner
##    saying nothing is recorded, which makes it worse than redundant.
##    The graded banner already states that work is recorded, so the
##    line is deleted rather than repaired. The section then opens on
##    "It's been a few weeks..." which is a better first sentence anyway.
##
##  FINDING 2 -- review-assign grades TEXT, not STATE.
##    Current:  grepl("n_sites\\s*<-\\s*15", .user_code)
##    M1's equivalent (assign-exercise-check) grades the OBJECT:
##              user_object_exists() + user_object_get()
##    That is how the 2026-08-14 "= is acceptable for assignment"
##    decision was actually implemented -- implicitly, by checking state
##    instead of source. M3 never got it. Today M3 REJECTS all of:
##        n_sites = 15          (contradicts the M1 decision outright)
##        15 -> n_sites
##        n_sites <- 5 + 10
##    all of which leave n_sites holding 15. Rewritten to M1's pattern.
##
##  NOT CHANGED, deliberately:
##    - The exercise says "then type n_sites on the next line to print
##      it." Neither the old grader nor the new one enforces the print
##      step (the old \\bn_sites\\b test matched the assignment line
##      itself, so it never checked anything). Left unenforced to match
##      M1's behaviour rather than introducing a new way to fail.
##    - M3's other .user_code greps (review-str, q8) are LEGITIMATE.
##      str() returns NULL invisibly, so there is no result to inspect
##      and text is the only thing available. Do not "fix" those.
##
##  Matches on CONTENT, never on line number -- the live repo and the
##  project-knowledge copies are offset by the inlined css chunk.
##  Idempotent.
## =====================================================================

f <- "inst/tutorials/03-refresher/03-refresher.Rmd"

if (!file.exists(f)) stop("Not found: ", f, "\nAre you at the repo root?")
x <- readLines(f, warn = FALSE)
orig_n <- length(x)

## ---------------------------------------------------------------------
## FINDING 1 -- remove the orphan line
## ---------------------------------------------------------------------
cat("\n=== FINDING 1: orphaned fragment ===\n")

i <- which(trimws(x) == "exercises you complete.")

if (!length(i)) {
  cat("  [ok]   not present - already removed\n")
} else if (length(i) > 1) {
  cat(sprintf("  [STOP] found %d matches at lines %s - not touching, inspect by hand\n",
              length(i), paste(i, collapse = ", ")))
} else {
  cat("  --- before ---\n")
  for (k in max(1, i - 2):min(length(x), i + 2))
    cat(sprintf("  %5d | %s\n", k, x[k]))

  ## drop the line, and one adjacent blank so no double gap is left
  drop <- i
  if (i + 1 <= length(x) && !nzchar(trimws(x[i + 1]))) drop <- c(drop, i + 1)
  x <- x[-drop]

  cat("  --- after ---\n")
  for (k in max(1, i - 2):min(length(x), i + 1))
    cat(sprintf("  %5d | %s\n", k, x[k]))
  cat(sprintf("  [OK]   removed %d line(s)\n", length(drop)))
}

## ---------------------------------------------------------------------
## FINDING 2 -- replace the review-assign-check body
## ---------------------------------------------------------------------
cat("\n=== FINDING 2: review-assign grader ===\n")

open_i <- which(grepl("^```\\{r review-assign-check", x))

if (!length(open_i)) {
  cat("  [STOP] review-assign-check chunk not found - inspect by hand\n")
} else if (length(open_i) > 1) {
  cat("  [STOP] more than one review-assign-check chunk - inspect by hand\n")
} else {
  close_rel <- which(grepl("^```\\s*$", x[(open_i + 1):length(x)]))[1]
  if (is.na(close_rel)) {
    cat("  [STOP] no closing fence found - inspect by hand\n")
  } else {
    close_i <- open_i + close_rel

    if (any(grepl("user_object_exists", x[open_i:close_i], fixed = TRUE))) {
      cat("  [ok]   already state-based - no change\n")
    } else {
      cat("  --- before ---\n")
      for (k in open_i:close_i) cat(sprintf("  %5d | %s\n", k, x[k]))

      new_chunk <- c(
'```{r review-assign-check}',
'grade_this({',
'  # State-based, matching M1 assign-exercise-check. Grades WHAT the',
'  # student produced, not HOW they typed it, so `=` and `->` both pass.',
'  # `=` was accepted as assignment on 2026-08-14; a text grep here',
'  # silently reversed that decision for this one exercise.',
'  pass_if(',
'    user_object_exists("n_sites") &&',
'      identical(user_object_get("n_sites"), 15),',
'    "It comes back quickly - storing a value in an object works exactly as it did in the fall."',
'  )',
'',
'  fail_if(',
'    !user_object_exists("n_sites"),',
'    "Try again. Create an object called `n_sites`."',
'  )',
'',
'  fail_if(',
'    user_object_exists("n_sites") &&',
'      !identical(user_object_get("n_sites"), 15),',
'    "Try again. `n_sites` exists, but it should hold the value 15."',
'  )',
'',
'  fail("Assign the value 15 to an object called `n_sites`, then type `n_sites` on the next line to print it.")',
'})',
'```')

      x <- c(x[seq_len(open_i - 1)], new_chunk, x[(close_i + 1):length(x)])

      cat("  --- after ---\n")
      for (k in open_i:(open_i + length(new_chunk) - 1))
        cat(sprintf("  %5d | %s\n", k, x[k]))
      cat("  [OK]   grader replaced\n")
    }
  }
}

writeLines(x, f)
cat(sprintf("\n  written: %s  (%d -> %d lines)\n", f, orig_n, length(x)))

## ---------------------------------------------------------------------
## Verify -- print lines, never counts
## ---------------------------------------------------------------------
cat("\n=== VERIFY ===\n")
y <- readLines(f, warn = FALSE)

cat("  orphan fragment present? ")
cat(if (any(trimws(y) == "exercises you complete.")) "*** STILL THERE ***\n" else "no\n")

cat("  review-assign now grades: ")
cat(if (any(grepl("user_object_exists", y, fixed = TRUE))) "OBJECT (correct)\n" else "*** still TEXT ***\n")

cat("\n  All remaining .user_code greps in M3 (these SHOULD stay - str() returns NULL):\n")
for (k in grep("\\.user_code", y)) cat(sprintf("  %5d | %s\n", k, trimws(y[k])))

cat("\nThen: restart R, devtools::install(quick = TRUE), and launch M3.\n")
cat("On review-assign, try all four and expect all four to PASS:\n")
cat("    n_sites <- 15   /   n_sites = 15   /   15 -> n_sites   /   n_sites <- 5 + 10\n\n")
