## =====================================================================
##  M1 revision — teach comments + typing; convert demo chunks to typed
##  Run from repo root:  source("dev/m1-typing-revision.R")
##
##  Changes:
##   1. New "Typing Code and Writing Comments" section before Objects
##      and Assignment, with one graded exercise (comment-exercise)
##   2. class-demo   -> one line shown, two prompted by comment
##   3. confirm-load -> blank + comment
##   4. str-review   -> blank + comment
##   5. dollar-demo  -> blank + comment
##   6. Prose updated: "Run the line below" -> typing instructions
##   7. capitalised -> capitalized
##
##  NOT done here: adding "comment-exercise" to grade_module()'s module1
##  lookup. That is a separate file and a separate decision (see end).
## =====================================================================

f <- "inst/tutorials/01-intro-to-r/01-intro-to-r.Rmd"
stopifnot(file.exists(f))
x <- readLines(f, warn = FALSE)
orig_n <- length(x)

rep1 <- function(from, to, label) {
  n <- sum(grepl(from, x, fixed = TRUE))
  if (n != 1) { cat(sprintf("  [SKIP] %-28s (%d matches, expected 1)\n", label, n)); return(invisible(FALSE)) }
  x <<- gsub(from, to, x, fixed = TRUE)
  cat(sprintf("  [OK]   %s\n", label)); invisible(TRUE)
}

cat("\n=== 1. Prose updates ===\n")

rep1("Run the code below to see the class of each example.",
     "The first line is written for you. Type the other two underneath it.",
     "class-demo prose")

rep1("Run the line below. You should see `\"data.frame\"`, which means `goldenrod` is stored as a dataframe.",
     "Type a line that checks what kind of object `goldenrod` is. You should see `\"data.frame\"`.",
     "confirm-load prose")

rep1("Run `str(goldenrod)` once more, then answer the questions that follow.",
     "Type `str(goldenrod)` once more, then answer the questions that follow.",
     "str-review prose")

rep1("Run the line below to pull out the `gall_status` column.",
     "Type a line that pulls out the `gall_status` column using `$`.",
     "dollar-demo prose")

rep1("spelled and capitalised the", "spelled and capitalized the",
     "capitalised -> capitalized")

cat("\n=== 2. Chunk conversions ===\n")

## --- class-demo: keep line 1, prompt for 2 and 3 ---
old <- c("```{r class-demo, exercise=TRUE}",
         "class(3.14)",
         "class(\"hello\")",
         "class(TRUE)",
         "```")
new <- c("```{r class-demo, exercise=TRUE}",
         "class(3.14)",
         "# Now do the same for \"hello\" and for TRUE",
         "",
         "```")
i <- which(x == old[1])
if (length(i) == 1 && identical(x[i:(i+4)], old)) {
  x <- append(x[-(i:(i+4))], new, after = i - 1)
  cat("  [OK]   class-demo converted\n")
} else cat("  [SKIP] class-demo — chunk body does not match expected\n")

## --- confirm-load ---
old <- c("```{r confirm-load, exercise=TRUE}", "class(goldenrod)", "```")
new <- c("```{r confirm-load, exercise=TRUE}",
         "# Check what kind of object goldenrod is",
         "",
         "```")
i <- which(x == old[1])
if (length(i) == 1 && identical(x[i:(i+2)], old)) {
  x <- append(x[-(i:(i+2))], new, after = i - 1)
  cat("  [OK]   confirm-load converted\n")
} else cat("  [SKIP] confirm-load — chunk body does not match expected\n")

## --- str-review ---
old <- c("```{r str-review, exercise=TRUE}", "str(goldenrod)", "```")
new <- c("```{r str-review, exercise=TRUE}",
         "# Look at the structure of goldenrod",
         "",
         "```")
i <- which(x == old[1])
if (length(i) == 1 && identical(x[i:(i+2)], old)) {
  x <- append(x[-(i:(i+2))], new, after = i - 1)
  cat("  [OK]   str-review converted\n")
} else cat("  [SKIP] str-review — chunk body does not match expected\n")

## --- dollar-demo ---
old <- c("```{r dollar-demo, exercise=TRUE}", "goldenrod$gall_status", "```")
new <- c("```{r dollar-demo, exercise=TRUE}",
         "# Pull out the gall_status column using $",
         "",
         "```")
i <- which(x == old[1])
if (length(i) == 1 && identical(x[i:(i+2)], old)) {
  x <- append(x[-(i:(i+2))], new, after = i - 1)
  cat("  [OK]   dollar-demo converted\n")
} else cat("  [SKIP] dollar-demo — chunk body does not match expected\n")

cat("\n=== 3. Grader message updates ===\n")

rep1("\"Correct — you ran the `class()` examples.\"",
     "\"Correct — three different types: numeric, character, logical.\"",
     "class-demo pass msg")
rep1("fail(\"Run the code as written to see the class of each example.\")",
     "fail(\"Add `class(\\\"hello\\\")` and `class(TRUE)` below the first line.\")",
     "class-demo fail msg")

rep1("\"Good — you ran the check.\"",
     "\"Good — `goldenrod` is a dataframe and it is loaded.\"",
     "confirm-load pass msg")
rep1("fail(\"Run `class(goldenrod)` to check that the dataset is available.\")",
     "fail(\"Type `class(goldenrod)` below the comment.\")",
     "confirm-load fail msg")

rep1("fail(\"Try again. Run `str(goldenrod)`.\")",
     "fail(\"Type `str(goldenrod)` below the comment.\")",
     "str-review fail msg")

rep1("fail(\"Run `goldenrod$gall_status` to access the `gall_status` column.\")",
     "fail(\"Type `goldenrod$gall_status` below the comment.\")",
     "dollar-demo fail msg")

cat("\n=== 4. New section ===\n")

anchor <- "## Objects and Assignment"
i <- which(x == anchor)
if (length(i) != 1) {
  cat("  [SKIP] anchor '## Objects and Assignment' not found exactly once\n")
} else if (any(grepl("## Typing Code and Writing Comments", x, fixed = TRUE))) {
  cat("  [SKIP] section already present\n")
} else {
  sec <- c(
"## Typing Code and Writing Comments",
"",
"Everything you have seen so far, you have read. Now you will type.",
"",
"The boxes in this tutorial work like the Console in RStudio: you type R code,",
"press **Run Code** to see what happens, and press **Submit Answer** when you",
"want it recorded. You can run as many times as you like before submitting.",
"",
"### Comments",
"",
"R ignores any line that starts with `#`. These lines are called **comments**,",
"and they are notes for humans — you, your lab partner, or you in three weeks",
"when you have forgotten why you did something.",
"",
"```{r comment-demo, exercise=FALSE, echo=TRUE}",
"# Count the stems in quadrat 3",
"n_stems <- 42",
"```",
"",
"R reads the second line and ignores the first entirely.",
"",
"**In this tutorial, comments are your instructions.** When you open an exercise",
"and see a line beginning with `#`, that line is telling you what to write.",
"Leave it there and type your code on the line below it.",
"",
"### Your turn",
"",
"The box below has a comment in it. Type a line underneath that creates an object",
"called `n_quadrats` with the value `3`.",
"",
"```{r comment-exercise, exercise=TRUE}",
"# Create an object called n_quadrats and set it to 3",
"",
"```",
"",
"```{r comment-exercise-check}",
"grade_this({",
"  pass_if(",
"    user_object_exists(\"n_quadrats\") &&",
"      identical(user_object_get(\"n_quadrats\"), 3),",
"    \"Correct — and notice the comment is still sitting there. R read straight past it.\"",
"  )",
"",
"  fail_if(",
"    !user_object_exists(\"n_quadrats\"),",
"    \"No object called `n_quadrats` yet. Type `n_quadrats <- 3` on the line below the comment.\"",
"  )",
"",
"  fail(\"`n_quadrats` exists but is not 3. Check the value you assigned.\")",
"})",
"```",
"",
"------------------------------------------------------------------------",
"")
  x <- append(x, sec, after = i - 1)
  cat("  [OK]   section inserted before 'Objects and Assignment'\n")
}

writeLines(x, f)

cat(sprintf("\n=== Written. %d lines -> %d lines ===\n", orig_n, length(x)))
cat("exercise=TRUE chunks now:",
    length(grep("exercise\\s*=\\s*TRUE", readLines(f, warn = FALSE))), "(expect 10)\n\n")
cat("NEXT: decide whether comment-exercise is graded. If yes, add\n")
cat("      \"comment-exercise\" to module1 in R/grade_module.R.\n")
cat("      Leaving it out keeps the denominator at 9 and makes it formative.\n\n")
