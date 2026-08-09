# For instructors

This guide covers deploying tutorials, grading them, and the parts of
the design that are load-bearing in ways that are not obvious from the
code.

## The three layers

The package deliberately keeps three things separate:

| Layer | Format | Role | Coach? |
|----|----|----|----|
| **Tutorials** (Modules 1–10) | `learnr` `.Rmd` | graded homework, done before lab | yes |
| **In-lab exercises** | plain `.R` via [`get_lab()`](https://aso003-bucknell.github.io/BisonExplorR/reference/get_lab.md) | partner work during the 3-hour lab | **no** |
| **Exams** | `.docx` + CSVs, instructor-controlled | assessment | no |

The Coach exists only in tutorials. Lab scripts therefore keep more
scaffolding — a time-boxed lab where the instructor is circulating makes
stalling expensive, and there is no automated help available in a plain
`.R` file.

## Graded versus practice mode

Each tutorial detects which copy it is:

``` r

bx_is_graded()
```

It reads the `BisonExplorR.graded` option, falling back to the
`BISONEXPLORR_GRADED` environment variable. In the **deployed** app
bundle, add a `.Renviron` containing:

    BISONEXPLORR_GRADED=true

Put this in the deployed bundle only. If it reaches the package source,
every practice copy starts logging.

The consequences of the flag:

| Mode | Student sees | Logs? |
|----|----|----|
| Graded | navy banner, student ID box, Continue disabled until filled | yes |
| Practice | orange “Practice mode” banner | **no** |

### Why the practice copy shows a banner rather than nothing

If the flag is ever missing on a deployed graded app, the ID box
disappears and nothing logs — every student silently scores zero, and
you would not find out until grades were due. The banner turns that into
something a student notices on the first screen and reports the same
day.

**Deploy check: open the deployed URL once and confirm you see the ID
box, not the banner.** That single step is the whole safety net.

### The Continue-button gate is client-side

It stops the student who forgets to enter an ID, not one who is
determined to avoid it — anyone with browser developer tools can
re-enable the button. That is an acceptable trade:
[`grade_module()`](https://aso003-bucknell.github.io/BisonExplorR/reference/grade_module.md)
drops rows with a blank ID, so a student who bypasses the gate scores
zero rather than corrupting anyone else’s data.

## Logging

Progress is logged anonymously by POSTing to a Google Form, so no Posit
Connect licence is required. Each tutorial hardcodes a `tutorial_id`
(`"module1"` … `"module10"`) that
[`grade_module()`](https://aso003-bucknell.github.io/BisonExplorR/reference/grade_module.md)
matches against.

**Never change a `tutorial_id`.** Every row already in the response
sheet carries the old string; changing it orphans all historical data,
and
[`grade_module()`](https://aso003-bucknell.github.io/BisonExplorR/reference/grade_module.md)
returns nothing with no error anywhere.

Download the response sheet as a CSV to grade.

## Grading

``` r

grade_module(
  responses = "form_responses.csv",
  module    = "module5",
  roster    = "section_roster.csv"
)
```

The roster needs a student-id column and a section column. With one
supplied, you get a CSV per section plus `ALL` and `UNMATCHED`; without
one, just `ALL`.

Scoring is 5 points completion, 5 points correctness:

- **Completion** — the fraction of the module’s exercises with at least
  one real submission. Running code without submitting does not count.
- **Correctness** — the fraction with at least one correct submission.
  Repeated wrong attempts carry no penalty.

Override the denominator per call if you need to:

``` r

grade_module("form_responses.csv", "module5", exercises = paste0("q", 1:4))
```

### Two failure modes that do not error

**A wrong denominator mis-scales silently.** If the lookup lists more
exercises than the file contains, every student is capped below 100%;
fewer, and scores inflate. Module 8 capped every student at 75% this way
for weeks. **Whenever you add or remove an exercise, update the lookup
in the same edit.**

**Multiple-choice items only score if the tutorial registers a
`question_submission` handler.** `question()` blocks emit that event
rather than `exercise_result`, so the default handler never sees them.
Listing `mc1`–`mc4` in a lookup without the handler gives a denominator
of 8 where only 4 rows can ever arrive — every student capped at 50%.
Module 5 registers the handler; no other module currently does.

### Check the roster after a run

The message reports how many students were unmatched and how many rows
were dropped for a blank or unknown ID. A large unmatched count usually
means students typed their IDs inconsistently, which is worth catching
in week two rather than week twelve.

## Deploying the graded tutorials

1.  Deploy each tutorial as its own Shiny app (`shinyapps.io` or
    equivalent).
2.  Include a `.Renviron` with `BISONEXPLORR_GRADED=true` in each
    bundle.
3.  Fill the deployed URLs into the `graded_urls` vector in
    `R/launch_graded_tutorial.R`, then `document()` and reinstall.

The `graded_urls` names are `tutorial_id` values, not folder names. Any
module left as `NA_character_` raises an informative error pointing the
student at the ungraded `run_tutorial()` copy — so a half-deployed
course fails loudly at the missing module rather than opening dead tabs
everywhere. Deploying one module at a time is a supported workflow, not
a broken state.

## The Coach

The Coach is Socratic by construction. It may name a concept, function,
or operator, and may quote a student’s own code back to them, but it
will not assemble a working line or chain several solution steps
together. It gives exactly one nudge per request.

It requires a **server-side proxy** so that no API key ships inside a
package students can inspect. Point tutorials at it with:

``` r

options(BisonExplorR.coach_url = "https://your-proxy.example.org/coach")
```

Without a URL configured, the Coach falls back to static offline hints.
Those are exercise-aware and safe, but not adaptive — so an unconfigured
Coach degrades rather than breaks.

Coach coverage is deliberately partial, targeting the steps where
students actually stall: write-from-scratch exercises, test selection,
and interpretation. Single-blank fills where the inline hint already
suffices are skipped, because a Coach there adds noise and cost without
adding help.

## Datasets

Tutorial datasets are engineered rather than sampled. Seeds are scanned
until a dataset hits its teaching target — a Tukey test with exactly one
non-significant pair, an interaction that is reliably absent, an
intercept that is meaningless on purpose. Every statistic quoted in a
pass message is computed from the shipped CSV before it is written down.

The practical consequence: **row counts and group means are
load-bearing.** Several graders and quiz answers reference them
directly. Regenerating a dataset without re-verifying will break
exercises silently rather than loudly.
