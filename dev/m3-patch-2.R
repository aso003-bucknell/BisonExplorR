## =====================================================================
##  BisonExplorR -- M3 patch 2: q8's invalid gradethis pronoun
##  Run from repo root:  source("dev/m3-patch-2.R")
##
##  BUG: 03-refresher.Rmd q8-check referenced `.user_env`, which is NOT
##  a gradethis object. The documented check-environment objects are:
##      .result .user .last_value .solution .solution_all .user_code
##      .solution_code .solution_code_all .envir_prep .envir_result
##      .envir_solution .evaluate_result .label .stage .engine
##  `.user_env` is on none of these lists. It never resolved, so
##      exists("class_data", envir = .user_env)
##  errored while evaluating its own `envir` argument. Students got a
##  grading error instead of a grade -- on EVERY submission to q8.
##
##  Never caught because M3 has never had a live run. This is the same
##  class of defect as the empty-sid logging bug, the failing YAML
##  stylesheet, and the newline-eating comment stripper: fluent,
##  plausible code that was never executed.
##
##  FIX: use the house helpers, matching M1 (8 uses) and the
##  review-assign fix in m3-patch-1.R. `.envir_result` would also work
##  and is the gradethis maintainers' own idiom, but user_object_get()
##  keeps one pattern across the package.
##
##  Scanned all ten modules first: only .result, .user_code, .label and
##  .user_env appear anywhere. The first three are valid. This is the
##  only invented pronoun in the package.
##
##  Idempotent. Matches on content, not line number.
## =====================================================================

f <- "inst/tutorials/03-refresher/03-refresher.Rmd"
if (!file.exists(f)) stop("Not found: ", f, "\nAre you at the repo root?")

x <- readLines(f, warn = FALSE)

subs <- list(
  list(from = 'exists("class_data", envir = .user_env)',
       to   = 'user_object_exists("class_data")'),
  list(from = 'get("class_data", envir = .user_env)',
       to   = 'user_object_get("class_data")')
)

cat("\n=== BEFORE ===\n")
hits <- grep("\\.user_env", x)
if (!length(hits)) {
  cat("  [ok] no .user_env references - already patched\n")
} else {
  for (k in hits) cat(sprintf("  %5d | %s\n", k, trimws(x[k])))
}

changed <- 0
for (s in subs) {
  i <- which(grepl(s$from, x, fixed = TRUE))
  if (!length(i)) next
  x[i] <- sub(s$from, s$to, x[i], fixed = TRUE)
  changed <- changed + length(i)
}

## Add an explanatory comment inside the grade_this() block, once.
if (changed > 0) {
  gi <- which(grepl("^```\\{r q8-check", x))
  if (length(gi) == 1) {
    gt <- gi + which(grepl("grade_this\\(\\{", x[(gi + 1):min(gi + 5, length(x))]))[1]
    if (!is.na(gt) && !any(grepl("user_env was not a gradethis object", x))) {
      x <- append(x, c(
        '  # NOTE: this previously used `.user_env`, which was not a gradethis',
        '  # object and never resolved -- every submission errored instead of',
        '  # being graded. Use the documented helpers (or .envir_result).'
      ), after = gt)
    }
  }
}

writeLines(x, f)

cat("\n=== AFTER ===\n")
y <- readLines(f, warn = FALSE)
for (k in grep("user_object_exists|user_object_get|\\.user_env", y))
  cat(sprintf("  %5d | %s\n", k, trimws(y[k])))

cat("\n=== VERIFY ===\n")
cat("  .user_env still present? ")
cat(if (any(grepl("\\.user_env", y))) "*** YES - STILL BROKEN ***\n" else "no\n")
cat(sprintf("  expressions replaced: %d (expect 2)\n", changed))

cat("\nNext: restart R, devtools::install(quick = TRUE), launch M3.\n")
cat("q8 needs a LIVE network call from inside the exercise sandbox --\n")
cat("that is the part no static check can confirm. Submit it for real.\n\n")
