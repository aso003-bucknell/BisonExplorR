## =====================================================================
##  BisonExplorR -- accessibility pass 1
##  Run from repo root:  source("dev/a11y-pass-1.R")
##
##  Three changes, all mechanical, all idempotent:
##
##  1. ALT TEXT on the two bare images (WCAG 1.1.1, Level A).
##     Only four images exist in the whole package; M2's two already
##     have alt text. These are the other two.
##
##  2. SIDEBAR DIM 0.5 -> 0.7 (WCAG 1.4.3, Level AA).
##     opacity:0.5 on #333 over the #F7F7F7 sidebar computes to an
##     effective #959595 = 2.80:1. AA normal text needs 4.5:1.
##     0.7 gives #6e6e6e = 4.76:1 and still reads as clearly dimmed.
##     DO NOT lower this back to 0.5. Measured, not guessed.
##
##  3. RECONCILE dev/custom.css with what actually ships.
##     custom.css disables `.topic > .nav-link` (the anchor).
##     The inlined block disables `.topic` (the li), because the
##     anchor approach did not work -- the <nav> is a shiny-bound-input
##     that delegates clicks, so an inert <a> passes the click up and
##     the handler fires anyway. custom.css has been stale since.
##
##  NOT DONE HERE, deliberately:
##     - tabindex="-1" / aria-disabled on locked topics. Locked topics
##       are still reachable by Tab+Enter, which is both a WCAG 4.1.2
##       problem and a real bypass of the allow_skip gate. Held pending
##       the Office of Accessibility Resources reply, because that is
##       the exact question being asked of them.
##     - The Ace editor keyboard trap (WCAG 2.1.2, Level A). Upstream
##       in learnr's dependency; not fixable from these files.
## =====================================================================

mods <- c("01-intro-to-r","02-data-import","03-refresher","04-wrangle-visualize",
          "05-groups","06-regression","07-two-way-anova","08-ancova",
          "09-choosing-a-test","10-joining-data")

rmd <- function(m) sprintf("inst/tutorials/%s/%s.Rmd", m, m)

## ---------------------------------------------------------------------
## 1. Alt text
## ---------------------------------------------------------------------
cat("\n=== 1. Alt text on bare images ===\n")

alt_fixes <- list(
  list(mod = "01-intro-to-r",
       from = "![](images/posit1.png)",
       to   = "![The RStudio window divided into four panes: Source, Console, Environment, and Files/Plots/Packages/Help/Viewer.](images/posit1.png)"),
  list(mod = "03-refresher",
       from = "![](images/Sheet_ID.png)",
       to   = "![A Google Sheets URL with the long ID between /d/ and /edit highlighted.](images/Sheet_ID.png)")
)

for (fx in alt_fixes) {
  f <- rmd(fx$mod)
  if (!file.exists(f)) { cat(sprintf("  [SKIP] %-22s file missing\n", fx$mod)); next }
  x <- readLines(f, warn = FALSE)
  i <- which(grepl(fx$from, x, fixed = TRUE))
  if (!length(i)) {
    already <- any(grepl(sub("^!\\[\\]", "![", fx$to), x, fixed = TRUE))
    cat(sprintf("  [%s] %-22s %s\n", if (already) "ok" else "WARN", fx$mod,
                if (already) "alt text already present" else "pattern NOT FOUND - check by hand"))
    next
  }
  x[i] <- sub(fx$from, fx$to, x[i], fixed = TRUE)
  writeLines(x, f)
  cat(sprintf("  [OK]   %-22s line %d\n", fx$mod, i[1]))
}

## ---------------------------------------------------------------------
## 2. Sidebar opacity 0.5 -> 0.7, all ten
## ---------------------------------------------------------------------
cat("\n=== 2. Sidebar dim 0.5 -> 0.7 (contrast 2.80 -> 4.76) ===\n")

old_line <- ".topicsList .nav-pills .topic:not(.current) > .nav-link { opacity: 0.5; }"
new_line <- ".topicsList .nav-pills .topic:not(.current) > .nav-link { opacity: 0.7; }"
note     <- "/* 0.7 not 0.5: at 0.5 the dimmed text is 2.80:1, below the 4.5:1  */"
note2    <- "/* WCAG AA floor. 0.7 measures 4.76:1 and still reads as dimmed.   */"

for (m in mods) {
  f <- rmd(m)
  if (!file.exists(f)) { cat(sprintf("  [SKIP] %-22s file missing\n", m)); next }
  x <- readLines(f, warn = FALSE)

  if (!any(grepl("^```\\{css bx-style", x))) {
    cat(sprintf("  [WARN] %-22s no bx-style chunk - run inline-css.R first\n", m)); next
  }
  i <- which(grepl(old_line, x, fixed = TRUE))
  if (!length(i)) {
    if (any(grepl(new_line, x, fixed = TRUE))) {
      cat(sprintf("  [ok]   %-22s already 0.7\n", m))
    } else {
      cat(sprintf("  [WARN] %-22s opacity line NOT FOUND - inspect by hand\n", m))
    }
    next
  }
  x[i] <- new_line
  x <- append(x, c(note, note2), after = i[1] - 1)
  writeLines(x, f)
  cat(sprintf("  [OK]   %-22s line %d\n", m, i[1]))
}

## ---------------------------------------------------------------------
## 3. Reconcile dev/custom.css with the shipped rules
## ---------------------------------------------------------------------
cat("\n=== 3. Reconciling dev/custom.css ===\n")

css_path <- "dev/custom.css"
css <- c(
'/* =====================================================================',
'   BisonExplorR -- shared tutorial stylesheet',
'',
'   *** NOT LOADED AT RUNTIME. ***',
'   `css: custom.css` in the YAML makes the browser request /custom.css',
'   over HTTP; the Shiny app does not serve that path, returns an HTML',
'   404, and the browser refuses it on MIME-type mismatch. The rules',
'   below ship as an inlined ```{css bx-style} chunk in each of the ten',
'   .Rmd files, written by dev/inline-css.R.',
'',
'   THIS FILE IS DOCUMENTATION. Editing it changes nothing. To change',
'   what students see, edit the chunk in the .Rmd files (or edit the',
'   block inside inline-css.R and re-run it), then update this file to',
'   match. It drifted once already -- see the note on rule 1.',
'',
'   Verified against learnr 0.11.6.9000 markup:',
'     <nav class="topicsList">',
'       <ul class="nav nav-pills nav-stacked">',
'         <li class="topic" index="0"><a class="nav-link">...</a></li>',
'         <li class="topic current" index="4">...</li>',
'     <footer class="topicsFooter"><span class="resetButton">Start Over</span>',
'',
'   NOTE: learnr marks only the CURRENT topic. There is no class',
'   distinguishing visited from unvisited, which is why this disables',
'   all sidebar links rather than only the ones ahead of the student.',
'   ===================================================================== */',
'',
'/* ---------------------------------------------------------------------',
'   1. Sidebar: display only, not navigation.',
'',
'   allow_skip: false gates the Continue button but NOT the sidebar --',
'   a student could click any topic and land there having completed',
'   nothing. This closes the mouse route.',
'',
'   CORRECTED 2026-08-15: this file previously disabled',
'       .topicsList .nav-pills .topic > .nav-link',
'   i.e. the anchor. That does not work. The <nav> is a',
'   shiny-bound-input that DELEGATES clicks, so an inert <a> passes the',
'   click up to a handler that fires anyway. The <li> is what must be',
'   disabled. The shipped chunk has always done this; only this file',
'   was wrong.',
'   --------------------------------------------------------------------- */',
'.topicsList .nav-pills .topic {',
'  pointer-events: none;',
'}',
'',
'/* Dimmed = locked. 0.7, NOT 0.5.',
'   At opacity 0.5 the effective text color over the #F7F7F7 sidebar is',
'   #959595, a contrast ratio of 2.80:1 -- below the 4.5:1 WCAG 2.1 AA',
'   floor for normal text (1.4.3). 0.7 gives #6e6e6e = 4.76:1 and still',
'   reads as clearly dimmed. Measured, not eyeballed. Do not lower. */',
'.topicsList .nav-pills .topic:not(.current) > .nav-link {',
'  opacity: 0.7;',
'}',
'',
'/* Start Over lives in .topicsFooter, outside .nav-pills, so it is',
'   unaffected by the rule above. Left deliberately clickable. */',
'',
'/* learnr paints a topicProgress.png sprite as the <li> background. */',
'/* With the sidebar inert it reads as clutter.                     */',
'.topicsList .nav-pills .topic { background-image: none; }',
'',
'/* ---------------------------------------------------------------------',
'   2. Previous button: RESTORED (decision 2026-08-14).',
'',
'   The former rule here --',
'       .topicActions .btn-default:first-child { display: none; }',
'   -- hid Previous. Combined with rule 1 that left students with no way',
'   back at all: a student on section 5 could not re-read section 3',
'   without Start Over, which wipes their work.',
'',
'   Forward movement is still gated by allow_skip: false. Backward',
'   movement is review, and review should be cheap.',
'',
'   Do not re-add a display:none rule here without also giving students',
'   some other route backward.',
'   --------------------------------------------------------------------- */',
'',
'/* ---------------------------------------------------------------------',
'   3. KNOWN GAP -- not fixed here.',
'',
'   pointer-events:none removes the MOUSE route into a locked topic but',
'   does NOT remove the <a> from the keyboard tab order. A keyboard user',
'   can still Tab to a locked topic and press Enter, which fires the',
'   delegated handler and bypasses the gate. Screen readers also',
'   announce these as ordinary links with no indication they are locked.',
'',
'   Correct fix is tabindex="-1" plus aria-disabled="true" on the locked',
'   anchors, which CSS cannot do -- it needs JS, alongside the existing',
'   MutationObserver in the sid-server chunk.',
'',
'   Deferred pending Office of Accessibility Resources consultation',
'   (contacted 2026-08-17), since the mitigation approach is the exact',
'   question put to them.',
'   --------------------------------------------------------------------- */'
)

if (!dir.exists("dev")) dir.create("dev")
writeLines(css, css_path)
cat(sprintf("  [OK]   %s rewritten (%d lines)\n", css_path, length(css)))

## ---------------------------------------------------------------------
## Verify -- PRINT THE LINES, do not report counts.
## A count proves a string exists, not what it means.
## ---------------------------------------------------------------------
cat("\n=== VERIFY: opacity line in each module (read these, do not count) ===\n")
for (m in mods) {
  f <- rmd(m)
  x <- if (file.exists(f)) readLines(f, warn = FALSE) else character(0)
  hit <- grep("opacity:", x, value = TRUE)
  cat(sprintf("  %-22s %s\n", m,
      if (length(hit)) trimws(paste(hit, collapse = " | ")) else "*** NO OPACITY LINE ***"))
}

cat("\n=== VERIFY: every image in the package, with its alt text ===\n")
for (m in mods) {
  f <- rmd(m)
  x <- if (file.exists(f)) readLines(f, warn = FALSE) else character(0)
  hit <- grep("!\\[", x, value = TRUE)
  for (h in hit) {
    bare <- grepl("![](", h, fixed = TRUE)
    cat(sprintf("  [%s] %-22s %s\n", if (bare) "BARE" else " ok ", m, trimws(h)))
  }
}

cat("\nWant: every opacity line reading 0.7, and no image marked BARE.\n")
cat("Then: restart R, devtools::install(quick = TRUE), relaunch M1 and M3.\n")
cat("Check by eye that the dimmed sidebar still reads as dimmed at 0.7.\n\n")
