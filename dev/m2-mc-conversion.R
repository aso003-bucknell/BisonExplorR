## =====================================================================
##  M2 — convert the three "type the letter" exercises into real
##  multiple-choice question() blocks.
##  Run from repo root:  source("dev/m2-mc-conversion.R")
##
##  WHY THE HANDLER MATTERS
##  Exercises emit `exercise_result`. question() blocks emit
##  `question_submission`. M2 registers only the former, so converting
##  these three without also adding a question_submission handler would
##  make all three log nothing while still sitting in grade_module()'s
##  module2 lookup -- every student silently capped at 5/8. That is the
##  documented failure mode, so the handler goes in the same pass.
##
##  Chunk labels are preserved (account-quiz, section-link-quiz,
##  project-quiz) so existing module2 lookup entries still match.
##
##  Boundaries are found by CHUNK LABEL, not by prose position, and a
##  block is replaced only if both ends are located unambiguously.
## =====================================================================

f <- "inst/tutorials/02-data-import/02-data-import.Rmd"
stopifnot(file.exists(f))
x <- readLines(f, warn = FALSE)
n0 <- length(x)

## Span from the lead-in prose line through the closing fence of the
## <label>-check chunk.
span <- function(lead, label) {
  s <- which(trimws(x) == lead)
  if (length(s) != 1) return(NULL)
  ck <- grep(sprintf("^```\\{r %s-check\\}", label), x)
  if (length(ck) != 1) return(NULL)
  e <- grep("^```\\s*$", x); e <- e[e > ck][1]
  if (is.na(e) || e < s) return(NULL)
  c(s, e)
}

replace_block <- function(lead, label, new) {
  sp <- span(lead, label)
  if (is.null(sp)) {
    cat(sprintf("  [SKIP] %-20s boundaries not unambiguous\n", label))
    return(invisible(FALSE))
  }
  x <<- append(x[-(sp[1]:sp[2])], new, after = sp[1] - 1)
  cat(sprintf("  [OK]   %-20s lines %d-%d replaced\n", label, sp[1], sp[2]))
  invisible(TRUE)
}

cat("\n=== Converting to question() ===\n")

replace_block(
  "Which Posit Cloud plan should you choose for this course?", "account-quiz",
  c("```{r account-quiz, echo=FALSE}",
    "question(",
    "  \"Which Posit Cloud plan should you choose for this course?\",",
    "  answer(\"Cloud Free\", correct = TRUE,",
    "         message = \"The free plan is all you need for this course.\"),",
    "  answer(\"Cloud Basic\"),",
    "  answer(\"Instructor\"),",
    "  answer(\"Enterprise\"),",
    "  allow_retry = TRUE,",
    "  random_answer_order = FALSE",
    ")",
    "```"))

replace_block(
  "Why should you use the link for your assigned lab section?", "section-link-quiz",
  c("```{r section-link-quiz, echo=FALSE}",
    "question(",
    "  \"Why should you use the link for your assigned lab section?\",",
    "  answer(\"It opens the correct course space for your section\", correct = TRUE,",
    "         message = \"The section link gets you into the correct course space.\"),",
    "  answer(\"It makes R run faster\"),",
    "  answer(\"It automatically writes your code for you\"),",
    "  answer(\"It replaces the need to save your work\"),",
    "  allow_retry = TRUE,",
    "  random_answer_order = FALSE",
    ")",
    "```"))

replace_block(
  "What should you create inside your lab section's Posit Cloud space?", "project-quiz",
  c("```{r project-quiz, echo=FALSE}",
    "question(",
    "  \"What should you create inside your lab section's Posit Cloud space?\",",
    "  answer(\"A new RStudio Project\", correct = TRUE,",
    "         message = \"Create a new RStudio Project.\"),",
    "  answer(\"A new email account\"),",
    "  answer(\"A new browser window only\"),",
    "  answer(\"A new spreadsheet only\"),",
    "  allow_retry = TRUE,",
    "  random_answer_order = FALSE",
    ")",
    "```"))

cat("\n=== Removing lettered option lists and 'type the letter' lines ===\n")
drop <- grep("^Type the letter of", trimws(x))
drop <- c(drop, grep("^- [a-d]\\) ", trimws(x)))
drop <- sort(unique(drop))
if (length(drop)) {
  cat(sprintf("  [OK]   removed %d line(s)\n", length(drop)))
  x <- x[-drop]
} else cat("  [ok]   none found\n")

cat("\n=== Adding question_submission handler ===\n")
if (any(grepl("question_submission", x, fixed = TRUE))) {
  cat("  [ok]   already present\n")
} else {
  i <- grep("^```\\{r event-setup", x)
  if (length(i) != 1) {
    cat("  [SKIP] no unique event-setup chunk -- add the handler by hand\n")
  } else {
    e <- grep("^```\\s*$", x); e <- e[e > i][1]
    handler <- c(
"",
"# Multiple-choice items. Without this, question() blocks emit",
"# question_submission, nothing logs them, and the three MC items listed",
"# in grade_module()'s module2 lookup score nothing -- silently capping",
"# every student at 5/8.",
"#",
"# NOTE: correctness is on data$correct here, NOT data$feedback$correct.",
"# Copied from 05-groups.Rmd, whose comment records that this field name",
"# was never verified against the installed learnr and that a wrong guess",
"# fails SILENTLY. Both are tried. VERIFY ON M2 BEFORE LAUNCH.",
"event_register_handler(\"question_submission\", function(session, event, data) {",
"  correct_flag <- data$correct",
"  if (is.null(correct_flag) || length(correct_flag) == 0) {",
"    correct_flag <- data$feedback$correct",
"  }",
"  log_attempt(",
"    student_id  = bx_get_sid(session),",
"    exercise_id = data$label,",
"    correct     = correct_flag",
"  )",
"})")
    x <- append(x, handler, after = e - 1)
    cat("  [OK]   handler added to event-setup\n")
  }
}

writeLines(x, f)

cat(sprintf("\n=== %d lines -> %d ===\n", n0, length(x)))
cat("\nVERIFY NEXT:\n")
cat(" 1. All three render as radio buttons, not code boxes.\n")
cat(" 2. bx_get_sid() exists in M2 -- the handler calls it. The seed\n")
cat("    records M2 as having had NO bx_get_sid at one point:\n")
cat("      length(grep('bx_get_sid', readLines(f)))\n")
cat(" 3. Submit one MC in graded mode; confirm the sheet row shows\n")
cat("    correct = TRUE, not NA. NA means data$correct was wrong and\n")
cat("    the fallback did not catch it.\n\n")
