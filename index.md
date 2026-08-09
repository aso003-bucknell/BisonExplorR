# BisonExplorR

Interactive R tutorials, in-lab scripts, and grading tools for the
**BIOL 203/204 Integrated Concepts in Biology** laboratory sequence at
Bucknell University.

BisonExplorR teaches biological data analysis in R to students who
mostly have never programmed before. Everything runs in a web browser
through **Posit Cloud** — students do not install R.

## Installation

``` r

# install.packages("remotes")
remotes::install_github("aso003-bucknell/BisonExplorR")
```

## For students

Three functions cover the whole course.

``` r

library(BisonExplorR)

# Open the graded homework tutorial for a module
launch_graded_tutorial("module5")

# Copy an in-lab partner script into your project
get_lab("comparing-groups")

# Copy a practice exam's datasets into your project
get_practice_exam("exam2")
```

To work through a tutorial **ungraded**, for practice, launch it
directly:

``` r

learnr::run_tutorial("05-groups", package = "BisonExplorR")
```

Practice copies show an orange *Practice mode* banner, ask for no
student ID, and record nothing. Only the deployed graded copies log
work.

See
[`vignette("students", package = "BisonExplorR")`](https://aso003-bucknell.github.io/BisonExplorR/articles/students.md)
for the full walkthrough.

## Modules

| Module | Tutorial               | Topic                                |
|--------|------------------------|--------------------------------------|
| 1      | `01-data-import`       | Introduction to R                    |
| 2      | `02-posit-cloud`       | Posit Cloud and data import          |
| 3      | `03-refresher`         | Welcome back — R refresher           |
| 4      | `04-wrangle-visualize` | Data wrangling and visualization     |
| 5      | `05-groups`            | Comparing groups — t-tests and ANOVA |
| 6      | `06-regression`        | Linear regression — fitting a line   |
| 7      | `07-2way-anova`        | Two-way ANOVA                        |
| 8      | `08-ancova`            | ANCOVA, and multi-panel figures      |
| 9      | `09-choosing-a-test`   | Choosing the right test              |
| 10     | `10-joining-data`      | Joining data — combining tables      |

## For instructors

``` r

grade_module("module5", responses = "responses.csv")
```

[`grade_module()`](https://aso003-bucknell.github.io/BisonExplorR/reference/grade_module.md)
reads the Google Form response sheet, matches submissions against a
per-module lookup of graded exercise labels, and writes a gradebook CSV.
Blank student IDs are dropped rather than guessed.

See
[`vignette("instructors", package = "BisonExplorR")`](https://aso003-bucknell.github.io/BisonExplorR/articles/instructors.md)
for deployment, the graded/practice split, and the parts of the design
that are load-bearing in non-obvious ways.

## The Coach

Tutorials can embed a Socratic hint assistant. It may name a concept or
an operator and may quote the student’s own code back to them, but it
does not assemble corrected code. It runs only inside tutorials, never
in the in-lab `.R` scripts.

The Coach calls a **server-side proxy**, so no API key ever ships in the
package. Without a configured proxy it falls back to static offline
nudges rather than failing.

``` r

options(BisonExplorR.coach_url = "https://<your-proxy>/coach")
```

## For developers / maintainers

The `dev/` directory contains scripts used during development. It is
excluded from the installed package by `.Rbuildignore` but is tracked by
git and visible in the public repo.

| Script | Purpose | Needs `coach-endpoint/`? |
|----|----|----|
| `build-site.R` | Ordered `document()` → `install()` → `build_site()` with pre-flight checks | no |
| `apply_allow_skip.py` | Apply `allow_skip` YAML + per-section overrides to all modules | no |
| `check_grading.py` | Cross-check [`grade_module()`](https://aso003-bucknell.github.io/BisonExplorR/reference/grade_module.md) lookup against actual chunk labels | no |
| `preflight-module5.R` | 40-check smoke test for Module 5 + the logging pipeline | yes (one check) |
| `check-coach-registry.R` | Verify coach registry ↔︎ tutorial wiring (17 ↔︎ 17) | yes |
| `backup-coach-endpoint.ps1` | Push endpoint to private repo + encrypted archive | yes |

`coach-endpoint/` is gitignored and never arrives with a clone. It holds
the plumber proxy and exercise registry — the server side of the Coach.
Restore it from the private backup before running the scripts that need
it. See `RECOVERY.md` in the private backup repo.

## What is deliberately not here

Real exam documents, answer keys, and their datasets are
instructor-controlled and live outside this repository. Anything under
`inst/` is readable by any student via
[`system.file()`](https://rdrr.io/r/base/system.file.html), so the
boundary is enforced by placement, not by convention.

## Funding

Developed with support from a Bucknell University **IDEA Grant**, summer
2026.

## License

CC BY 4.0.
