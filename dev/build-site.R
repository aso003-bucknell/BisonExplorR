# dev/build-site.R -----------------------------------------------------------
#
# LIVES IN: dev/            (.Rbuildignore's ^dev$ keeps it out of the package)
# RUN FROM: the package root -- NOT from inside dev/
#
#     setwd("C:/Users/lexie/Documents/BisonExplorR")   # the clone, not the Drive mirror
#     source("dev/build-site.R")
#
# Every path below is relative to the package root ("R", "DESCRIPTION", "man/"),
# so running it with dev/ as the working directory fails at the first guard.
#
# ⚠️ THIS SCRIPT CANNOT RUN STRAIGHT THROUGH. Step 4 needs an R session restart
#    that only works when typed at the console. Run steps 0-3, then restart, then
#    run steps 4-6. The script is marked at the break.
#
# Ordered by dependency. Steps 1-3 must pass before step 4, because build_site()
# reads man/ and man/ is written by document().

# --- 0. Reflex check: am I in the right working copy? ------------------------
cat("cwd:  ", getwd(), "\n")
cat("git:  ", system("git log --oneline -1", intern = TRUE), "\n")
cat("branch:", system("git rev-parse --abbrev-ref HEAD", intern = TRUE), "\n\n")
stopifnot(file.exists("DESCRIPTION"))
if (grepl("Google Drive|Other computers", getwd())) {
  stop("This is the Drive mirror, not the clone. Open the clone instead.")
}

# --- 1. Files that must be in R/ before document() ---------------------------
need <- c("get_lab.R", "launch_graded_tutorial.R", "grade_module.R",
          "coach_module.R", "get_practice_exam.R")
missing <- setdiff(need, list.files("R"))
if (length(missing)) {
  stop("Missing from R/: ", paste(missing, collapse = ", "))
}
# And nothing that isn't source:
strays <- setdiff(list.files("R"), c(need, list.files("R", pattern = "\\.R$")))
strays <- c(strays, list.files("R", pattern = "\\.md$"))   # COACH_*.md live here
if (length(strays)) {
  message("NOTE: non-source files in R/ (R CMD check will flag these): ",
          paste(unique(strays), collapse = ", "))
}

# --- 2. DESCRIPTION preconditions -------------------------------------------
d <- read.dcf("DESCRIPTION", all = TRUE)
stopifnot(
  identical(trimws(d$VignetteBuilder), "knitr"),   # else R CMD build skips vignettes
  grepl("gradethis", d$Remotes)                    # gradethis is NOT on CRAN (404)
)
cat("DESCRIPTION: VignetteBuilder and Remotes both present.\n\n")

# --- 3. Document ------------------------------------------------------------
devtools::document()
ns <- readLines("NAMESPACE")
stopifnot(any(grepl("export\\(get_practice_exam\\)", ns)))
stopifnot(file.exists("man/get_practice_exam.Rd"))
cat("get_practice_exam exported and documented.\n\n")

# --- 4. Install, restart, build the site ------------------------------------
devtools::install(upgrade = FALSE, build_vignettes = TRUE)

## ======================= STOP -- RESTART HERE ==============================
## Type this at the console, then run the rest of the file:
##
##     .rs.restartR()
##
## Without the restart, build_site() documents the OLD installed copy: it picks
## up the previously loaded namespace, so a just-added export is invisible and
## the failure looks like document() not having worked.
## ===========================================================================

pkgdown::build_site()

# --- 5. Nothing sensitive shipped -------------------------------------------
# All three MUST return "". A path means it installed and any student can read it.
for (dir in c("coach-endpoint", "dev", "exams")) {
  p <- system.file(dir, package = "BisonExplorR")
  cat(sprintf("%-16s %s\n", dir, if (nzchar(p)) paste("SHIPPED ->", p) else "not installed  OK"))
}

# --- 6. And nothing sensitive is about to be pushed --------------------------
cat("\n-- git tracking check (all should be empty) --\n")
for (pat in c("coach-endpoint", "exams", "plumber.R", "exercise_registry.R")) {
  hits <- system(sprintf("git ls-files | grep -i %s", shQuote(pat)), intern = TRUE)
  cat(sprintf("%-22s %s\n", pat, if (length(hits)) paste("TRACKED:", paste(hits, collapse = ", ")) else "clean"))
}
