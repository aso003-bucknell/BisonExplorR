# Changelog

## BisonExplorR (development version)

### Graded and practice modes are now distinct

- Tutorials detect whether they are the graded deployment via
  `bx_is_graded()`, which reads `BISONEXPLORR_GRADED` or the
  `BisonExplorR.graded` option.
- The student ID box renders **only** in the graded copy. Practice
  copies show a “Practice mode” banner and **record nothing**, so
  practice attempts no longer land in the response sheet as
  unattributable rows.
- In the graded copy, the section’s Continue button is disabled until a
  student ID has been entered.

### New

- [`get_practice_exam()`](https://aso003-bucknell.github.io/BisonExplorR/reference/get_practice_exam.md)
  copies a practice exam’s datasets into the working directory, so
  students read them by bare filename exactly as they will on exam day.
- Module 8 gained a **multi-panel figure** section covering
  `plot_grid()` and `ggsave()`, closing the last gap between what the
  tutorials teach and what R Exam 2 tests.
- The Coach is now wired into Modules 4 and 7–10, joining Modules 5 and
  6.

### Fixes

- **Multiple-choice answers logged `student_id = "unknown"`.**
  `question()` blocks are Shiny modules, so the handler receives a
  namespaced session whose `input$sid` is empty. `bx_get_sid()` now
  resolves the ID from the root session. Nothing errored previously —
  rows looked well-formed but were unattributable, so students silently
  lost the multiple-choice half of their score.
- **Module 8 capped every student at 75%.** Its
  [`grade_module()`](https://aso003-bucknell.github.io/BisonExplorR/reference/grade_module.md)
  lookup listed four exercises where the file had three.
- **Module 9 generated its dataset inline** rather than reading
  `cardio.csv`, so it could drift from Module 8’s copy of the same data
  across R versions.

## BisonExplorR 0.1.0

- Initial release: ten `learnr` tutorials, in-lab scripts via
  [`get_lab()`](https://aso003-bucknell.github.io/BisonExplorR/reference/get_lab.md),
  biological datasets, and
  [`grade_module()`](https://aso003-bucknell.github.io/BisonExplorR/reference/grade_module.md)
  for anonymous progress tracking.
