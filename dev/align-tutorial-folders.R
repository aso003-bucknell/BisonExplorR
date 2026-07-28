## =====================================================================
##  Align inst/tutorials/ folder names with their .Rmd filenames.
##  Run from the PACKAGE ROOT:  source("dev/align-tutorial-folders.R")
##
##  learnr takes the tutorial name from the DIRECTORY, not the .Rmd file.
##  Making them identical means run_tutorial() names are derivable from the
##  filename instead of needing a lookup.
##
##  WHAT THIS DOES NOT TOUCH — and must never touch:
##    * the `tutorial_id` string inside each .Rmd
##      ("entry.1315894547" = "module5"). grade_module() matches on that,
##      and every row already in the Google Sheet carries it. Renaming it
##      to match a folder would orphan all historical data silently.
##    * coach registry keys ("module5-q1") in exercise_registry.R.
##
##  Safe to re-run: it skips anything already in the right place.
## =====================================================================

root <- "inst/tutorials"
if (!dir.exists(root)) stop("Run me from the package root — ", root, " not found.")

## Target layout: folder name == .Rmd basename.
targets <- c("01-data-import", "02-posit-cloud", "03-refresher",
             "04-wrangle-visualize", "05-groups", "06-regression",
             "07-two-way-anova", "08-ancova", "09-choosing-a-test",
             "10-joining-data")

## Find where each .Rmd currently lives, wherever its folder is named.
found <- list.files(root, pattern = "\\.Rmd$", recursive = TRUE, full.names = TRUE)
if (!length(found)) stop("No .Rmd files found under ", root)

cat("Found", length(found), "tutorial file(s).\n\n")
moved <- 0L

for (tgt in targets) {
  src <- found[basename(found) == paste0(tgt, ".Rmd")]
  if (!length(src)) {
    cat(sprintf("  [SKIP]  %-22s no %s.Rmd found\n", tgt, tgt)); next
  }
  if (length(src) > 1) {
    cat(sprintf("  [WARN]  %-22s %d copies found, skipping: %s\n",
                tgt, length(src), paste(src, collapse = ", "))); next
  }
  cur_dir <- dirname(src)
  new_dir <- file.path(root, tgt)

  if (normalizePath(cur_dir, mustWork = FALSE) ==
      normalizePath(new_dir, mustWork = FALSE)) {
    cat(sprintf("  [OK]    %-22s already correct\n", tgt)); next
  }

  ## Move the whole folder's contents (images/, data/, helpers travel with it).
  dir.create(new_dir, recursive = TRUE, showWarnings = FALSE)
  contents <- list.files(cur_dir, full.names = TRUE, all.files = TRUE, no.. = TRUE)
  ok <- file.rename(contents, file.path(new_dir, basename(contents)))
  if (all(ok)) {
    unlink(cur_dir, recursive = TRUE)
    cat(sprintf("  [MOVED] %-22s %s -> %s\n", tgt, basename(cur_dir), tgt))
    moved <- moved + 1L
  } else {
    cat(sprintf("  [FAIL]  %-22s could not move all contents from %s\n", tgt, cur_dir))
  }
}

cat(sprintf("\n%d folder(s) renamed.\n\n", moved))

## ---- verify -------------------------------------------------------
cat("Verification — each folder should contain a matching .Rmd:\n")
bad <- character()
for (d in list.dirs(root, recursive = FALSE)) {
  nm  <- basename(d)
  hit <- file.exists(file.path(d, paste0(nm, ".Rmd")))
  cat(sprintf("  [%s] %-22s run_tutorial(\"%s\", \"BisonExplorR\")\n",
              if (hit) "OK" else "!!", nm, nm))
  if (!hit) bad <- c(bad, nm)
}
if (length(bad)) {
  cat("\n  Mismatched: ", paste(bad, collapse = ", "),
      "\n  These folders do not contain a same-named .Rmd.\n")
} else {
  cat("\n  All folders match their .Rmd. Now reinstall and confirm:\n",
      "    devtools::install(upgrade = \"never\"); .rs.restartR()\n",
      "    learnr::available_tutorials(\"BisonExplorR\")\n")
}

cat("\nReminder: tutorial_id strings inside the .Rmd files are UNCHANGED\n",
    "and should stay that way. Confirm none were touched:\n",
    "  grep -rn 'entry.1315894547' inst/tutorials/ | sort\n")
