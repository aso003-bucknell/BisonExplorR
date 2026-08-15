## =====================================================================
##  BisonExplorR -- figure captions: numbering + spacing
##  Run from repo root:  source("dev/caption-pass.R")
##
##  CONTEXT: `![text](img.png)` in R Markdown is not alt-text-only.
##  Pandoc's implicit-figures mode renders that text as a VISIBLE
##  caption under the image. Adding alt text in dev/a11y-pass-1.R
##  therefore made captions appear on M1 and M3 where there were none.
##  M2's two already had them.
##
##  TWO CHANGES:
##
##  1. NUMBERING. Captions read as body prose running into the
##     following paragraph. Prefixed "Figure N." so they read as
##     captions. Numbering is PER MODULE (each tutorial is a standalone
##     document), so every module restarts at Figure 1.
##
##  2. SPACING + STYLING, rolled to all ten bx-style chunks.
##     Caption color #595959 = 7.00:1 on white. MEASURED.
##     Do not lighten toward a "muted grey": #808080 is 3.95:1 and
##     FAILS the 4.5:1 AA floor for normal text. Captions render small
##     but WCAG large-text only starts at 24px (or 18.66px bold), so the
##     normal-text threshold applies here.
##
##     Selectors cover BOTH `p.caption` and `figcaption` because which
##     one learnr emits has not been confirmed against rendered HTML.
##     Harmless if only one matches.
##
##  KNOWN, NOT FIXED: the caption text and the alt attribute are now
##  identical, so a screen reader announces the description twice.
##  Standard guidance is that when a visible caption fully describes an
##  image, alt can be empty. Left as-is deliberately -- raise it with
##  the Office of Accessibility Resources rather than guessing.
##
##  Idempotent. Matches on content, not line number.
## =====================================================================

mods <- c("01-intro-to-r","02-data-import","03-refresher","04-wrangle-visualize",
          "05-groups","06-regression","07-two-way-anova","08-ancova",
          "09-choosing-a-test","10-joining-data")
rmd <- function(m) sprintf("inst/tutorials/%s/%s.Rmd", m, m)

## ---------------------------------------------------------------------
## 1. Figure N. prefixes
## ---------------------------------------------------------------------
cat("\n=== 1. Caption numbering (per module) ===\n")

for (m in mods) {
  f <- rmd(m)
  if (!file.exists(f)) next
  x <- readLines(f, warn = FALSE)

  ## image lines with non-empty caption text
  idx <- grep("^!\\[[^]]", x)
  if (!length(idx)) { cat(sprintf("  [--]   %-22s no captioned images\n", m)); next }

  n <- 0
  for (i in idx) {
    if (grepl("^!\\[Figure [0-9]+\\.", x[i])) {   # already numbered
      n <- n + 1
      cat(sprintf("  [ok]   %-22s line %d already numbered\n", m, i))
      next
    }
    n <- n + 1
    x[i] <- sub("^!\\[", sprintf("![Figure %d. ", n), x[i])
    cat(sprintf("  [OK]   %-22s line %d -> Figure %d\n", m, i, n))
  }
  writeLines(x, f)
}

## ---------------------------------------------------------------------
## 2. Caption CSS into every bx-style chunk
## ---------------------------------------------------------------------
cat("\n=== 2. Caption spacing + styling ===\n")

css_block <- c(
'',
'/* Figure captions. `![text](img)` renders text as a VISIBLE caption, */',
'/* not alt-text-only, so these need to read as captions rather than   */',
'/* run into the next paragraph.                                       */',
'/* #595959 = 7.00:1 on white. MEASURED. Do NOT lighten -- #808080 is  */',
'/* 3.95:1 and fails the 4.5:1 AA floor. Small text does not qualify   */',
'/* as WCAG "large text"; that starts at 24px.                         */',
'.figure, figure { margin: 1.25em 0 1.75em 0; }',
'p.caption, figcaption {',
'  margin-top: 0.6em;',
'  font-size: 0.92em;',
'  font-style: italic;',
'  color: #595959;',
'  line-height: 1.4;',
'}'
)

for (m in mods) {
  f <- rmd(m)
  if (!file.exists(f)) next
  x <- readLines(f, warn = FALSE)

  open_i <- which(grepl("^```\\{css bx-style", x))
  if (!length(open_i)) {
    cat(sprintf("  [WARN] %-22s no bx-style chunk - run inline-css.R first\n", m)); next
  }
  if (any(grepl("p.caption, figcaption", x, fixed = TRUE))) {
    cat(sprintf("  [ok]   %-22s caption css already present\n", m)); next
  }

  close_rel <- which(grepl("^```\\s*$", x[(open_i[1] + 1):length(x)]))[1]
  if (is.na(close_rel)) {
    cat(sprintf("  [WARN] %-22s bx-style chunk has no closing fence\n", m)); next
  }
  close_i <- open_i[1] + close_rel

  x <- append(x, css_block, after = close_i - 1)
  writeLines(x, f)
  cat(sprintf("  [OK]   %-22s caption css added before line %d\n", m, close_i))
}

## ---------------------------------------------------------------------
## Verify -- print the lines
## ---------------------------------------------------------------------
cat("\n=== VERIFY: every image in the package ===\n")
for (m in mods) {
  f <- rmd(m)
  if (!file.exists(f)) next
  y <- readLines(f, warn = FALSE)
  for (k in grep("^!\\[", y)) {
    ok <- grepl("^!\\[Figure [0-9]+\\.", y[k])
    cat(sprintf("  [%s] %-22s %s\n", if (ok) " ok " else "BARE", m,
                substr(trimws(y[k]), 1, 88)))
  }
}

cat("\n=== VERIFY: caption css present in each module ===\n")
for (m in mods) {
  f <- rmd(m)
  y <- if (file.exists(f)) readLines(f, warn = FALSE) else character(0)
  cat(sprintf("  %-22s %s\n", m,
      if (any(grepl("p.caption, figcaption", y, fixed = TRUE))) "yes" else "*** MISSING ***"))
}

cat("\nThen: restart R, devtools::install(quick = TRUE), relaunch M3.\n")
cat("Check the caption sits clear of the paragraph below it and reads\n")
cat("as a caption, not as body text.\n\n")
