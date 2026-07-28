## =====================================================================
##  Move coach-endpoint/ OUT of inst/ so it stops shipping to students.
##  Run from the PACKAGE ROOT:  source("dev/move-coach-endpoint.R")
##
##  WHY. Everything under inst/ installs and is reachable with
##  system.file(). PROJECT_SYNC_2026-07-22.md annotated
##  inst/coach-endpoint/ as "NOT installed to students" — that was never
##  true. The API key was never at risk (env var), but plumber.R BUILDS
##  THE COACH'S SYSTEM PROMPT: shipping it hands every student the exact
##  Socratic constraints and the phrasing that gets around them.
##
##  WHY IT IS SAFE. No installed package code reads these files.
##    * plumber.R does a RELATIVE source("exercise_registry.R") in the
##      API's own working directory on the proxy host.
##    * the client only needs options(BisonExplorR.coach_url = ...).
##  Deployment is unchanged: copy the folder to the host as a unit.
##
##  THE ONE THING THAT BREAKS. dev/preflight-module5.R used to reach the
##  registry through system.file("coach-endpoint", ...), which resolved
##  ONLY because the folder installed. Post-move that returns "" and
##  section D reports a phantom "registry object reachable: FAIL" on the
##  script whose job is clearing the pilot. Patched 2026-07-25 to try the
##  repo path first; this script re-checks that patch is in place.
##
##  Safe to re-run: every step is skipped if already done.
## =====================================================================

if (!file.exists("DESCRIPTION")) {
  stop("Run me from the package root — no DESCRIPTION here.", call. = FALSE)
}

old_dir <- file.path("inst", "coach-endpoint")
new_dir <- "coach-endpoint"
expected <- c("plumber.R", "exercise_registry.R", "README.md")

cat("=== 1. Move the folder ===\n")

if (dir.exists(new_dir) && !dir.exists(old_dir)) {
  cat("  [OK]    already at repo root\n")
} else if (!dir.exists(old_dir)) {
  stop("Neither ", old_dir, " nor ", new_dir, " exists. Nothing to move.",
       call. = FALSE)
} else if (dir.exists(new_dir) && dir.exists(old_dir)) {
  stop("BOTH ", old_dir, " and ", new_dir, " exist. Two copies of the coach\n",
       "  endpoint is exactly the ambiguity this move is meant to remove.\n",
       "  Reconcile them by hand, keep one, then re-run.", call. = FALSE)
} else {
  dir.create(new_dir, showWarnings = FALSE)
  contents <- list.files(old_dir, full.names = TRUE, all.files = TRUE, no.. = TRUE)
  ok <- file.rename(contents, file.path(new_dir, basename(contents)))
  if (all(ok)) {
    unlink(old_dir, recursive = TRUE)
    cat(sprintf("  [MOVED] %s -> %s  (%d file(s))\n",
                old_dir, new_dir, length(contents)))
    cat("          git will detect this as a rename on the next add.\n")
  } else {
    stop("Could not move all contents out of ", old_dir, call. = FALSE)
  }
}

cat("\n=== 2. .Rbuildignore ===\n")

# ^dev$ belongs here too: dev/ holds the probe and preflight scripts, and
# anything under inst/tutorials/ would otherwise appear in students'
# Tutorial pane via available_tutorials().
need <- c("^coach-endpoint$", "^dev$")

if (!file.exists(".Rbuildignore")) {
  writeLines(character(0), ".Rbuildignore")
  cat("  [NEW]   created .Rbuildignore\n")
}
have <- readLines(".Rbuildignore", warn = FALSE)

for (pat in need) {
  if (pat %in% trimws(have)) {
    cat(sprintf("  [OK]    %-18s already ignored\n", pat))
  } else {
    have <- c(have, pat)
    cat(sprintf("  [ADDED] %-18s\n", pat))
  }
}
writeLines(have, ".Rbuildignore")

cat("\n=== 3. Verify ===\n")

fails <- character()
chk <- function(label, cond) {
  cat(sprintf("  [%s] %s\n", if (isTRUE(cond)) "OK" else "!!", label))
  if (!isTRUE(cond)) fails <<- c(fails, label)
}

chk("inst/coach-endpoint/ is gone", !dir.exists(old_dir))

for (f in expected) {
  chk(sprintf("%s present at %s/", f, new_dir),
      file.exists(file.path(new_dir, f)))
}

# The registry must still parse and still be hyphen-keyed.
reg <- tryCatch({
  e <- new.env()
  sys.source(file.path(new_dir, "exercise_registry.R"), envir = e)
  get("exercise_context", envir = e)
}, error = function(e) NULL)

chk("exercise_registry.R parses; exercise_context found", !is.null(reg))
if (!is.null(reg)) {
  chk(sprintf("registry has %d entries, all hyphen-keyed", length(reg)),
      !any(grepl("^module[0-9]+_q", names(reg))))
  # M8 and M9 legitimately use cardio — only flag if M5 or M7 entries still
  # reference it (those were the two migrated to algae_beads).
  migrated_entries <- reg[grepl("^module[57]-", names(reg))]
  chk("M5/M7 entries no longer reference cardio dataset",
      !any(grepl("resting_hr_bpm|activity_level|cardio", unlist(migrated_entries))))
}

# plumber.R's relative source() only resolves if the two files are siblings.
chk("plumber.R and exercise_registry.R are siblings (relative source() works)",
    file.exists(file.path(new_dir, "plumber.R")) &&
    file.exists(file.path(new_dir, "exercise_registry.R")))

# The preflight patch must be in place or the next pilot run reports a ghost.
pf <- "dev/preflight-module5.R"
if (file.exists(pf)) {
  chk("dev/preflight-module5.R patched for the new registry path",
      any(grepl('"coach-endpoint/exercise_registry.R"',
                readLines(pf, warn = FALSE), fixed = TRUE)))
} else {
  cat("  [WARN] dev/preflight-module5.R not found — if you restore it,\n",
      "         make sure it reads coach-endpoint/ from the repo, NOT\n",
      "         system.file(), or section D will report a phantom failure.\n")
}

cat("\n")
if (length(fails)) {
  cat(sprintf("%d check(s) FAILED:\n  - %s\n",
              length(fails), paste(fails, collapse = "\n  - ")))
} else {
  cat("All checks passed.\n\n",
      "Now reinstall and confirm the folder no longer ships:\n",
      '   devtools::install(upgrade = F); .rs.restartR()\n',
      '   system.file("coach-endpoint", package = "BisonExplorR")   # must be ""\n\n',
      "Deployment is unchanged — copy coach-endpoint/ to the proxy host as a\n",
      "unit and set ANTHROPIC_API_KEY (and BX_COACH_SHARED_SECRET) there.\n")
}
