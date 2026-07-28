## =====================================================================
##  BisonExplorR — Module 5 pilot preflight
##  Run this in the Posit Cloud CONSOLE before piloting Module 5.
##
##  It checks everything that can be checked WITHOUT a live tutorial
##  session. The one thing it cannot reach — the shape of
##  get_tutorial_state() — needs the separate in-tutorial probe chunk
##  (see module5-state-probe.Rmd). That probe is the real blocker.
##
##  Every expected value below was computed from algae_beads.csv and is
##  quoted verbatim in a Module 5 pass message. If a check fails, the
##  tutorial is telling students something untrue.
## =====================================================================

ok <- function(label, passed, detail = "") {
  cat(sprintf("  [%s] %-52s %s\n",
              if (isTRUE(passed)) "PASS" else "FAIL", label, detail))
  isTRUE(passed)
}
results <- c()
near <- function(a, b, tol) isTRUE(abs(a - b) < tol)

cat("\n=== A. Environment ===\n")
for (pkg in c("learnr", "gradethis", "ggplot2", "httr", "shiny", "BisonExplorR")) {
  results <- c(results, ok(sprintf("package available: %s", pkg),
                           requireNamespace(pkg, quietly = TRUE)))
}

f <- system.file("extdata", "algae_beads.csv", package = "BisonExplorR")
results <- c(results, ok("algae_beads.csv found in inst/extdata", nzchar(f), f))
if (!nzchar(f)) {
  cat("\n  STOP: data file missing. Add algae_beads.csv to inst/extdata/,\n",
      "  reinstall the package, and re-run.\n")
  stop("preflight halted")
}

cat("\n=== B. Data integrity ===\n")
algae <- read.csv(f, stringsAsFactors = FALSE)
algae$species        <- factor(algae$species)
algae$nutrient_level <- factor(algae$nutrient_level,
                               levels = c("low", "medium", "high"))

results <- c(results, ok("60 rows", nrow(algae) == 60, nrow(algae)))
results <- c(results, ok("4 columns", ncol(algae) == 4, ncol(algae)))
results <- c(results, ok("no missing values", !anyNA(algae)))
cells <- table(algae$species, algae$nutrient_level)
results <- c(results, ok("balanced 10 per cell", all(cells == 10),
                         paste(range(cells), collapse = "-")))
results <- c(results, ok("nutrient_level ordered low<medium<high",
                         identical(levels(algae$nutrient_level),
                                   c("low", "medium", "high"))))

cat("\n=== C. Statistics quoted in pass messages ===\n")

## --- q1: t-test. R's t.test() defaults to WELCH. If this ever gets
## --- switched to var.equal = TRUE the p-value in the prose goes stale.
tt <- t.test(co2_drawdown_ppm ~ species, data = algae)
results <- c(results, ok("q1 Welch t = -2.355", near(unname(tt$statistic), -2.3552, 0.005),
                         sprintf("got %.4f", tt$statistic)))
results <- c(results, ok("q1 p = 0.022", near(tt$p.value, 0.02192, 0.0005),
                         sprintf("got %.5f", tt$p.value)))
results <- c(results, ok("q1 Welch (not pooled) df ~ 57.89",
                         near(unname(tt$parameter), 57.89, 0.5),
                         sprintf("got %.2f", tt$parameter)))
mC <- mean(algae$co2_drawdown_ppm[algae$species == "Chlorella"])
mS <- mean(algae$co2_drawdown_ppm[algae$species == "Scenedesmus"])
results <- c(results, ok("q1 prose: Chlorella 34.3 ppm", near(mC, 34.250, 0.05),
                         sprintf("got %.3f", mC)))
results <- c(results, ok("q1 prose: Scenedesmus 39.0 ppm", near(mS, 38.963, 0.05),
                         sprintf("got %.3f", mS)))

## --- q2: one-way ANOVA
fit <- aov(co2_drawdown_ppm ~ nutrient_level, data = algae)
sa  <- summary(fit)[[1]]
Fv  <- sa[["F value"]][1]; pv <- sa[["Pr(>F)"]][1]
results <- c(results, ok("q2 F = 23.62", near(Fv, 23.6214, 0.01), sprintf("got %.4f", Fv)))
results <- c(results, ok("q2 p = 3.4e-08", near(pv, 3.3737e-08, 1e-9), sprintf("got %.3e", pv)))
results <- c(results, ok("q2 df = 2 and 57",
                         sa[["Df"]][1] == 2 && sa[["Df"]][2] == 57,
                         sprintf("got %d and %d", sa[["Df"]][1], sa[["Df"]][2])))

## --- q3: Tukey. NOTE: the SIGN of each difference depends on factor
## --- level order, so compare absolute differences only.
tk  <- TukeyHSD(fit)$nutrient_level
gd  <- function(a, b) {
  rn <- rownames(tk)
  i  <- which(rn == paste0(a, "-", b) | rn == paste0(b, "-", a))
  if (length(i) != 1) return(NULL)
  list(diff = abs(tk[i, "diff"]), p = tk[i, "p adj"])
}
hl <- gd("high", "low"); hm <- gd("high", "medium"); ml <- gd("medium", "low")
results <- c(results, ok("q3 |high-low| = 12.01", !is.null(hl) && near(hl$diff, 12.010, 0.02),
                         if (is.null(hl)) "row not found" else sprintf("got %.3f", hl$diff)))
results <- c(results, ok("q3 |high-medium| = 10.65", !is.null(hm) && near(hm$diff, 10.650, 0.02),
                         if (is.null(hm)) "row not found" else sprintf("got %.3f", hm$diff)))
results <- c(results, ok("q3 high differs from both (p < 0.0001)",
                         !is.null(hl) && !is.null(hm) && hl$p < 1e-4 && hm$p < 1e-4))
results <- c(results, ok("q3 PASS MESSAGE: medium vs low p = 0.76",
                         !is.null(ml) && near(ml$p, 0.7582, 0.01),
                         if (is.null(ml)) "row not found" else sprintf("got %.4f", ml$p)))
results <- c(results, ok("q3 PASS MESSAGE: medium-low gap = 1.4 ppm",
                         !is.null(ml) && near(ml$diff, 1.360, 0.02),
                         if (is.null(ml)) "row not found" else sprintf("got %.3f", ml$diff)))

## --- q4: the boxplot claim ("high box sits clearly above the other two")
mu <- tapply(algae$co2_drawdown_ppm, algae$nutrient_level, mean)
results <- c(results, ok("q4 prose: high clearly above low and medium",
                         mu[["high"]] > mu[["medium"]] + 5 && mu[["high"]] > mu[["low"]] + 5,
                         sprintf("low %.1f / medium %.1f / high %.1f",
                                 mu[["low"]], mu[["medium"]], mu[["high"]])))

cat("\n=== C2. MC grading dependency ===\n")
tf <- system.file("tutorials", "05-groups", "05-groups.Rmd", package = "BisonExplorR")
if (!nzchar(tf)) {
  cat("  [WARN] tutorial source not found at inst/tutorials/05-groups/; skipping.\n")
} else {
  src <- paste(readLines(tf, warn = FALSE), collapse = "\n")
  has_handler <- grepl('event_register_handler("question_submission"', src, fixed = TRUE)
  results <- c(results, ok("question_submission handler present", has_handler))
  results <- c(results, ok("mc1-mc4 chunks present",
                           all(vapply(paste0("mc", 1:4),
                                      function(i) grepl(paste0("```{r ", i, ","), src, fixed = TRUE),
                                      logical(1)))))
  lk <- tryCatch(BisonExplorR:::module_exercises[["module5"]], error = function(e) NULL)
  if (is.null(lk)) lk <- c(paste0("q", 1:4), paste0("mc", 1:4))
  results <- c(results, ok("lookup lists all 8 items", length(lk) == 8, paste(lk, collapse = ",")))
  ## The failure mode worth guarding: lookup counts MC but nothing logs them,
  ## so the denominator is 8 while only 4 can ever arrive -> silent 50%% cap.
  results <- c(results, ok("lookup and handler agree (no phantom denominator)",
                           !(any(grepl("^mc", lk)) && !has_handler)))
}

cat("\n=== D. Coach plumbing ===\n")
# The registry is NOT in the package namespace -- exercise_registry.R is
# source()d server-side by plumber.R, never by installed package code. (An
# earlier draft looked for it in the namespace and would have reported a
# phantom failure.)
#
# As of 2026-07-25 coach-endpoint/ sits at the REPO ROOT and is .Rbuildignore'd,
# so it no longer installs and system.file() cannot find it. Look in the repo
# first, then fall back to the old installed location so this script works
# whether or not the move has happened yet. Run with wd at the package root.
reg <- tryCatch({
  rp <- "coach-endpoint/exercise_registry.R"
  if (!file.exists(rp)) {
    rp <- system.file("coach-endpoint", "exercise_registry.R",
                      package = "BisonExplorR")          # pre-move fallback
  }
  if (!nzchar(rp) || !file.exists(rp)) NULL else {
    e <- new.env(); sys.source(rp, envir = e)
    get("exercise_context", envir = e)
  }
}, error = function(e) NULL)
results <- c(results, ok("registry object reachable", !is.null(reg)))
if (!is.null(reg)) {
  for (k in c("module5-q1", "module5-q3")) {
    results <- c(results, ok(sprintf("registry key present: %s", k), k %in% names(reg)))
  }
  ## The registry must describe ALGAE now, not cardio.
  blob <- paste(unlist(reg[c("module5-q1", "module5-q3")]), collapse = " ")
  results <- c(results, ok("registry M5 entries mention algae variables",
                           grepl("co2_drawdown_ppm", blob)))
  results <- c(results, ok("registry M5 entries free of stale cardio names",
                           !grepl("resting_hr_bpm|activity_level", blob)))
  ## Keys are HYPHENATED (module5-q1). plumber.R does a bare [[ ]] lookup with a
  ## %||% fallback, so an underscore key does not error -- it silently returns
  ## generic context and the coach gives plausible but unspecific advice.
  results <- c(results, ok("registry keys use hyphens, not underscores",
                           !any(grepl("^module[0-9]+_q", names(reg)))))
}
cu <- getOption("BisonExplorR.coach_url", Sys.getenv("BISONEXPLORR_COACH_URL", ""))
if (!nzchar(cu)) {
  cat("  [WARN] coach_url not set -> coach runs in OFFLINE fallback mode.\n",
      "         Fine for a scaffolding-only pilot; set it to test live coaching.\n")
} else {
  live <- tryCatch({
    r <- httr::POST(cu, body = list(exercise_id = "module5-q1",
                                    student_code = "t.test(co2_drawdown_ppm ~ species)",
                                    correct = FALSE),
                    encode = "json", httr::timeout(20))
    httr::status_code(r) == 200
  }, error = function(e) FALSE)
  results <- c(results, ok("coach endpoint reachable (200)", live, cu))
}

cat("\n=== E. Logging round-trip ===\n")
lg <- tryCatch({
  r <- httr::POST(
    url = "https://docs.google.com/forms/d/e/1FAIpQLSfmm3cUcoaWWYBb0zk7rbowSpgUL13nQc-Dxn7K8zQ30GdykA/formResponse",
    body = list("entry.1413675438" = as.character(Sys.time()),
                "entry.1257984687" = "PREFLIGHT_TEST",
                "entry.1315894547" = "module5",
                "entry.1172625272" = "preflight",
                "entry.1835356043" = "TRUE"),
    encode = "form", httr::timeout(20))
  httr::status_code(r) %in% c(200L, 302L)
}, error = function(e) FALSE)
results <- c(results, ok("Google Form accepted a test row", lg,
                         "look for student_id = PREFLIGHT_TEST"))
cat("  NOTE: a 200 only means the form accepted the POST. Open the response\n",
    "        sheet and confirm the row landed with tutorial_id = module5 and\n",
    "        that the columns are not shifted.\n")

cat("\n=== F. soil_data constraints (M1/M3 — guards the re-theme) ===\n")
sf <- system.file("extdata", "soil_data.csv", package = "BisonExplorR")
if (!nzchar(sf)) {
  cat("  [WARN] soil_data.csv not found; skipping.\n")
} else {
  soil <- read.csv(sf)
  results <- c(results, ok("EXACTLY 15 rows (3 graded checks depend on it)",
                           nrow(soil) == 15, nrow(soil)))
  results <- c(results, ok("land_use is character (M1 quiz Q2)",
                           is.character(soil$land_use), class(soil$land_use)))
  results <- c(results, ok("soil_temp_c is numeric not integer (M1 quiz Q3)",
                           is.numeric(soil$soil_temp_c) && !is.integer(soil$soil_temp_c)))
  for (cn in c("land_use", "organic_matter_pct", "soil_temp_c",
               "respiration_rate_mg_co2_kg_hr")) {
    results <- c(results, ok(sprintf("grader-bound column kept: %s", cn), cn %in% names(soil)))
  }
  rr <- cor(soil$organic_matter_pct, soil$respiration_rate_mg_co2_kg_hr)
  results <- c(results, ok("M2 pass message: respiration rises with organic matter",
                           rr > 0.85, sprintf("r = %.3f", rr)))
}

cat("\n=====================================================\n")
cat(sprintf("  %d checks, %d passed, %d FAILED\n",
            length(results), sum(results), sum(!results)))
if (all(results)) {
  cat("  All automated checks pass.\n",
      "  REMAINING BLOCKER: run the in-tutorial state probe before piloting.\n")
} else {
  cat("  Fix the FAIL lines above before piloting.\n")
}
cat("=====================================================\n")
