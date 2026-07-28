# Grade a BisonExplorR tutorial module from logged responses

Reads the CSV exported from the Google Sheet that the tutorials log to,
scores each student on **completion** and **correctness** for one
module, and writes a spreadsheet with one worksheet per section.

## Usage

``` r
grade_module(
  responses,
  module,
  roster = NULL,
  exercises = NULL,
  completion_points = 5,
  correctness_points = 5,
  output = NULL,
  roster_cols = list(student = "student_id", section = "section")
)
```

## Arguments

- responses:

  Path to the exported responses CSV, or a data.frame.

- module:

  The `tutorial_id` value to grade, e.g. `"module4"`.

- roster:

  Optional. Path to a CSV (or a data.frame) linking students to
  sections. Needs a student-id column and a section column (see
  `roster_cols`). When supplied, every rostered student appears in the
  output even if they have no logged activity (they score 0), and output
  is split one sheet per section. Students in the log but not on the
  roster land on an `UNMATCHED` sheet.

- exercises:

  Optional. Either an integer count of exercises in the module, or a
  character vector of the expected exercise IDs. If `NULL`, the function
  uses the built-in `module_exercises` lookup, and if the module isn't
  there, falls back to the distinct exercise IDs seen in the data (with
  a warning).

- completion_points, correctness_points:

  Points each half is worth.

- output:

  Filename stem (or path) for the CSVs. One CSV is written per section,
  plus an `ALL` CSV and (if any) an `UNMATCHED` CSV. Any extension is
  ignored. If `NULL`, a stem is generated in the working directory.

- roster_cols:

  Named list giving the student-id and section column names in the
  roster, e.g. `list(student = "student_id", section = "section")`.

## Value

(Invisibly) the full per-student grade data.frame. Also writes a file.

## Details

Each tutorial exercise logs a row every time a student **Runs** or
**Submits** code. A Run has no grading feedback, so its `correct` value
is blank; a Submit records `TRUE`/`FALSE`. The two scores use that
distinction:

- **Completion** (default 5 pts): the fraction of the module's exercises
  for which the student made at least one real submission (a non-blank
  `correct`).

- **Correctness** (default 5 pts): the fraction of the module's
  exercises the student answered correctly at least once (any `TRUE`).
