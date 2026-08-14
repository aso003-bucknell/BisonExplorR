## =====================================================================
##  Inline the tutorial CSS instead of serving it as a file.
##  Run from repo root:  source("dev/inline-css.R")
##
##  WHY: `css: custom.css` in the YAML makes the browser request
##  /custom.css over HTTP. The Shiny app does not serve that path, so it
##  returns an HTML 404 page and Chrome refuses it:
##      "Refused to apply style ... MIME type ('text/html')"
##  The file IS installed (system.file() finds it) -- it just is not
##  reachable over HTTP. A ```{css} chunk is embedded directly into the
##  rendered HTML and has no serving dependency.
##
##  IMPORTANT CONSEQUENCE: the stylesheet has probably never loaded in
##  any module. That means the old rule
##      .topicActions .btn-default:first-child { display: none; }
##  never hid the Previous button either. Do not treat the current
##  appearance of any module as evidence about what the CSS does.
##
##  Idempotent -- safe to re-run.
## =====================================================================

mods <- c("01-intro-to-r","02-data-import","03-refresher","04-wrangle-visualize",
          "05-groups","06-regression","07-two-way-anova","08-ancova",
          "09-choosing-a-test","10-joining-data")

## Kept deliberately short. Anything long belongs in a real stylesheet,
## and if we ever get file serving working this is what moves back.
block <- c(
'```{css bx-style, echo=FALSE}',
'/* Sidebar is a progress display, not navigation.                   */',
'/* allow_skip: false gates the Continue button but NOT the sidebar, */',
'/* so without this a student can click any topic and land there     */',
'/* having completed nothing.                                        */',
'/* Disabling the <li>, not the <a>: the <nav> is a shiny-bound-input */',
'/* that delegates clicks, so an inert <a> just passes the click up.  */',
'.topicsList .nav-pills .topic { pointer-events: none; }',
'.topicsList .nav-pills .topic:not(.current) > .nav-link { opacity: 0.5; }',
'',
'/* Start Over sits in .topicsFooter, outside .nav-pills, so it stays */',
'/* clickable. The Previous button is deliberately NOT hidden --      */',
'/* with the sidebar inert it is the only way back to review.         */',
'```',
'')

cat("\n=== Removing failing YAML css reference ===\n")
for (m in mods) {
  f <- sprintf("inst/tutorials/%s/%s.Rmd", m, m)
  if (!file.exists(f)) { cat(sprintf("  [SKIP] %-22s .Rmd missing\n", m)); next }
  x <- readLines(f, warn = FALSE)
  i <- grep("^\\s*css:\\s*custom\\.css\\s*$", x)
  if (!length(i)) { cat(sprintf("  [ok]   %-22s no css: line\n", m)); next }
  x <- x[-i]
  writeLines(x, f)
  cat(sprintf("  [OK]   %-22s removed %d line(s)\n", m, length(i)))
}

cat("\n=== Inserting inline css chunk ===\n")
for (m in mods) {
  f <- sprintf("inst/tutorials/%s/%s.Rmd", m, m)
  if (!file.exists(f)) next
  x <- readLines(f, warn = FALSE)

  if (any(grepl("^```\\{css bx-style", x))) {
    cat(sprintf("  [ok]   %-22s already present\n", m)); next
  }

  ## Anchor: the closing --- of the YAML header (second --- in the file)
  d <- grep("^---\\s*$", x)
  if (length(d) < 2) {
    cat(sprintf("  [SKIP] %-22s could not find YAML delimiters\n", m)); next
  }
  x <- append(x, c("", block), after = d[2])
  writeLines(x, f)
  cat(sprintf("  [OK]   %-22s chunk inserted after YAML\n", m))
}

cat("\n=== Verify ===\n")
for (m in mods) {
  f <- sprintf("inst/tutorials/%s/%s.Rmd", m, m)
  x <- if (file.exists(f)) readLines(f, warn = FALSE) else character(0)
  cat(sprintf("  %-22s css-chunk:%-5s yaml-css:%s\n", m,
      any(grepl("^```\\{css bx-style", x)),
      any(grepl("^\\s*css:\\s*custom\\.css\\s*$", x))))
}
cat("\nWant css-chunk TRUE and yaml-css FALSE on all ten.\n")
cat("Then: restart R, devtools::install(quick = TRUE), relaunch M1.\n")
cat("The custom.css files can stay in the folders for now -- harmless,\n")
cat("and they are the thing to reuse if file serving ever works.\n\n")
