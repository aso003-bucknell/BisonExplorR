## =====================================================================
##  Roll dev/custom.css out to all ten tutorial folders and ensure each
##  .Rmd declares it.  Run from repo root:
##      source("dev/roll-out-css.R")
##
##  Fixes in passing: 02-data-import declares `css: custom.css` but the
##  file does not exist in its folder.
##
##  Idempotent -- safe to re-run after editing dev/custom.css.
## =====================================================================

src <- "dev/custom.css"
stopifnot(file.exists(src))

mods <- c("01-intro-to-r","02-data-import","03-refresher","04-wrangle-visualize",
          "05-groups","06-regression","07-two-way-anova","08-ancova",
          "09-choosing-a-test","10-joining-data")

cat("\n=== Copying stylesheet ===\n")
for (m in mods) {
  dest <- sprintf("inst/tutorials/%s/custom.css", m)
  if (!dir.exists(dirname(dest))) { cat(sprintf("  [SKIP] %-22s folder missing\n", m)); next }
  file.copy(src, dest, overwrite = TRUE)
  cat(sprintf("  [OK]   %-22s %s\n", m, dest))
}

cat("\n=== Ensuring YAML declares css ===\n")
for (m in mods) {
  f <- sprintf("inst/tutorials/%s/%s.Rmd", m, m)
  if (!file.exists(f)) { cat(sprintf("  [SKIP] %-22s .Rmd missing\n", m)); next }
  x <- readLines(f, warn = FALSE)

  if (any(grepl("^\\s*css:\\s*custom\\.css\\s*$", x))) {
    cat(sprintf("  [ok]   %-22s already declared\n", m)); next
  }

  ## Anchor on allow_skip, which every module has, and match its indent
  i <- grep("^\\s*allow_skip:", x)
  if (length(i) != 1) {
    cat(sprintf("  [SKIP] %-22s no unique allow_skip line to anchor on\n", m)); next
  }
  indent <- sub("^(\\s*).*$", "\\1", x[i])
  x <- append(x, paste0(indent, "css: custom.css"), after = i)
  writeLines(x, f)
  cat(sprintf("  [OK]   %-22s css line added after allow_skip\n", m))
}

cat("\n=== Verify ===\n")
for (m in mods) {
  f <- sprintf("inst/tutorials/%s/%s.Rmd", m, m)
  c1 <- file.exists(sprintf("inst/tutorials/%s/custom.css", m))
  c2 <- if (file.exists(f)) any(grepl("^\\s*css:\\s*custom\\.css\\s*$",
                                      readLines(f, warn = FALSE))) else NA
  cat(sprintf("  %-22s file:%-5s yaml:%s\n", m, c1, c2))
}
cat("\nBoth columns TRUE on all ten = done.\n")
cat("Then: restart R, devtools::install(quick = TRUE), and re-run M1.\n\n")
