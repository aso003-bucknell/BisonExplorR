# dev/check-coach-registry.R -------------------------------------------------
#
# LIVES IN: dev/            (.Rbuildignore's ^dev$ keeps it out of the package)
# RUN FROM: the package root
#
#     source("dev/check-coach-registry.R")
#
# REQUIRES: coach-endpoint/ present at the package root (gitignored; does not
#   arrive with a fresh clone; copy it from the private backup repo first).
#   The script fails fast with a clear error if the folder is absent.
#
# FIXED 2026-07-29: the per-file coach_ui()/coach_server() pairing check used
# to match any line CONTAINING "coach_ui(" or "coach_server(" as a substring,
# including R comments that mention the function by name in prose (e.g.
# "# The Shiny id must match the coach_ui() call below it"). Those comment
# lines don't contain a quoted id in the expected position, so the old
# extraction fell through and returned the raw comment text -- producing a
# false FAIL on every coached module even though the wiring was correct.
# Fixed by stripping comments before searching and requiring the match to be
# an actual function call: fn( "id" ...
#
# Verify that the Coach's server-side registry and the tutorials agree.
#
# Run from the package root, with coach-endpoint/ present.

stopifnot(file.exists("coach-endpoint/exercise_registry.R"))

# --- registry keys -----------------------------------------------------------
e <- new.env()
sys.source("coach-endpoint/exercise_registry.R", envir = e)
registry <- sort(names(e$exercise_context))

# --- keys wired in the tutorials ---------------------------------------------
rmds <- list.files("inst/tutorials", pattern = "\\.Rmd$",
                   recursive = TRUE, full.names = TRUE)
if (length(rmds) == 0) rmds <- list.files(".", pattern = "^[0-9]{2}-.*\\.Rmd$")

txt <- lapply(rmds, readLines, warn = FALSE)

# Strip trailing "# ..." comments before any pattern match, so prose mentions
# of a function name never masquerade as a call. Fine for this codebase since
# exercise ids never contain '#'.
strip_comments <- function(lines) sub("#.*$", "", lines)

srv   <- unlist(lapply(txt, function(x) x[grepl("coach_server\\(", strip_comments(x))]))
wired <- sort(unique(regmatches(srv, regexpr('module[0-9]+-q[0-9]+', srv))))

# --- report ------------------------------------------------------------------
cat("registry entries:", length(registry), " | wired in tutorials:", length(wired), "\n\n")

fail <- FALSE

orphan <- setdiff(wired, registry)
if (length(orphan)) {
  fail <- TRUE
  cat("FAIL  wired but NOT in registry -- Coach falls back to generic context:\n  ",
      paste(orphan, collapse = ", "), "\n")
} else cat("ok    every wired exercise has a registry entry\n")

dead <- setdiff(registry, wired)
if (length(dead)) {
  cat("WARN  registry entry with no coach wired (harmless, but stale):\n  ",
      paste(dead, collapse = ", "), "\n")
} else cat("ok    no dead registry entries\n")

bad <- grep("_q[0-9]+$", c(registry, wired), value = TRUE)
if (length(bad)) {
  fail <- TRUE
  cat("FAIL  underscore-convention keys found (must be hyphens):\n  ",
      paste(bad, collapse = ", "), "\n")
} else cat("ok    all keys use the hyphen convention\n")

# --- ui/server pairing, per file (FIXED extraction) --------------------------
cat("\nper-file coach_ui / coach_server pairing:\n")

extract_id <- function(lines, fn) {
  code <- strip_comments(lines)
  hit  <- code[grepl(paste0(fn, "\\("), code)]
  m    <- regmatches(hit, regexpr(paste0(fn, '\\(\\s*"([^"]+)"'), hit, perl = TRUE))
  ids  <- sub(paste0('.*', fn, '\\(\\s*"([^"]+)".*'), "\\1", m)
  sort(unique(ids[nzchar(ids)]))
}

for (i in seq_along(rmds)) {
  x <- txt[[i]]
  ui <- extract_id(x, "coach_ui")
  sv <- extract_id(x, "coach_server")
  if (!length(ui) && !length(sv)) next
  same <- identical(ui, sv)
  if (!same) fail <- TRUE
  cat(sprintf("  %-28s %s  ui=[%s] server=[%s]\n",
              basename(rmds[i]), if (same) "ok  " else "FAIL",
              paste(ui, collapse = " "), paste(sv, collapse = " ")))
}

cat("\n", if (fail) "RESULT: FAIL -- fix before deploying the Coach\n" else
                    "RESULT: all checks passed\n", sep = "")
invisible(!fail)
