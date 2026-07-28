# BisonExplorR

**Interactive R tutorials for introductory biology at Bucknell
University.**

BisonExplorR supports the **BIOL 203/204 Integrated Concepts in
Biology** laboratory sequence. It delivers ten
[`learnr`](https://rstudio.github.io/learnr/) tutorials, in-lab partner
scripts, and biological datasets, plus an instructor-facing grading
function — all designed to run in [Posit Cloud](https://posit.cloud)
with no local installation.

The package was developed with support from a Bucknell **IDEA Grant**.

## The problem it addresses

In a Spring 2026 survey of BIOL 204 students (n = 111), **53% rated
their anxiety about R at 4 or 5 out of 5**, and about a third named
choosing and interpreting a statistical test as the hardest part of the
course. Two design decisions follow from that:

- **Tidy data is taught once in BIOL 203 and applied in BIOL 204**, so a
  student’s first contact with R code is not simultaneous with their
  first contact with data structure.
- **Statistics are isolated in 204** and reached only after a
  data-and-visualisation foundation, ending in a capstone module devoted
  entirely to test selection.

## Installation

``` r

# install.packages("remotes")
remotes::install_github("aso003-bucknell/BisonExplorR")
```

## For students

Three functions cover everything you need.

``` r

library(BisonExplorR)

# Open a tutorial for credit
launch_graded_tutorial("module5")

# Copy an in-lab script into your project
get_lab("comparing-groups")

# Copy a practice exam's datasets into your project
get_practice_exam("exam2")
```

Practice copies of any tutorial can be opened without credit:

``` r

learnr::run_tutorial("05-groups", package = "BisonExplorR")
```

A practice copy shows an orange **Practice mode** banner and records
nothing. The graded copy shows a navy banner and asks for your student
ID. If you see the orange banner in a tutorial you opened for credit,
tell your instructor — your work is not being recorded.

See [For
students](https://aso003-bucknell.github.io/BisonExplorR/articles/students.md)
for the full guide.

## Course structure

| Module | Topic | Where it sits |
|----|----|----|
| 1–2 | Intro to R, Posit Cloud, data import | BIOL 203, after Lab 10 |
| 3 | R refresher, from Sheets to R | Opens BIOL 204 |
| 4 | Wrangling and visualisation | Early 204 |
| 5 | Comparing groups: t-test, ANOVA, Tukey | Algae unit |
| 6 | Linear regression | Algae unit, pre-Exam 1 |
| 7 | Two-way ANOVA and interaction | Algae unit |
| 8 | ANCOVA, homogeneity of slopes, multi-panel figures | Cardio unit |
| 9 | Capstone: choosing the right test | Pre-Exam 2 |
| 10 | Joining tables | Cardio unit |

Each tutorial is homework, completed before the matching lab. In-lab
work happens in plain `.R` scripts with a partner.

## The Coach

Tutorials embed a **Socratic AI coach** on the exercises where students
most often stall — write-from-scratch steps, test selection, and
interpretation. It may name a concept, a function, or an operator, and
may quote a student’s own code back to them, but it will not assemble a
working line or chain solution steps.

The Coach lives **only in tutorials**, never in lab scripts, so in-lab
exercises keep more scaffolding. It requires a server-side proxy so that
no API key ships inside a student-inspectable package; without one
configured, it falls back to static offline hints.

## For instructors

Student progress is logged anonymously to a Google Form.
[`grade_module()`](https://aso003-bucknell.github.io/BisonExplorR/reference/grade_module.md)
turns the response sheet into per-section CSVs:

``` r

grade_module(
  log    = "form_responses.csv",
  module = "module5",
  roster = "section_roster.csv"
)
```

Scoring is 5 points for completion and 5 for correctness, with multiple
wrong attempts carrying no penalty. See [For
instructors](https://aso003-bucknell.github.io/BisonExplorR/articles/instructors.md).

## Datasets

Tutorials use engineered rather than sampled data: seeds are scanned
until a dataset hits its teaching target, so that — for example — a
Tukey test has exactly one non-significant pair to discuss. Every
statistic quoted in a pass message is computed from the shipped CSV
before it is written down.

## Citation and licence

Released under **CC BY 4.0**. Please cite as:

> Orr, A. (2026). *BisonExplorR: Interactive R Tutorials for
> Introductory Biology at Bucknell University.* R package version 0.1.0.
> <https://github.com/aso003-bucknell/BisonExplorR>

## Related

- [`learnr`](https://rstudio.github.io/learnr/) — the tutorial framework
- [`gradethis`](https://pkgs.rstudio.com/gradethis/) — exercise checking
