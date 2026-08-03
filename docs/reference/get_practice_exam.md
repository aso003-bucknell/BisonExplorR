# Copy a practice exam's datasets into your project

The practice R exams are written against a small set of CSV files. Those
files ship inside the installed package, which is read-only, so this
function copies them into your current Posit Cloud project where
[`read.csv()`](https://rdrr.io/r/utils/read.table.html) can find them
with a bare filename — exactly as it will on exam day.

## Usage

``` r
get_practice_exam(exam = NULL, overwrite = FALSE)
```

## Arguments

- exam:

  Name of the practice exam, e.g. `"exam1"` or `"exam2"`. If `NULL`, the
  available practice exams are listed.

- overwrite:

  Replace copies already in your project? Defaults to `FALSE` so a
  second call never wipes out work in progress.

## Value

(Invisibly) a character vector of the paths copied, or the vector of
available exam names when `exam = NULL`.

## Details

Call `get_practice_exam()` with no arguments to see which practice exams
are available.

Only **practice** exam datasets are distributed this way. Real exam
documents, answer keys, and their CSVs are instructor-controlled and are
deliberately absent from the package — anything under `inst/` is
readable by any student through
[`system.file()`](https://rdrr.io/r/base/system.file.html), so that
boundary is enforced by placement rather than by convention.

## See also

[`get_lab()`](https://aso003-bucknell.github.io/BisonExplorR/reference/get_lab.md)
for in-lab partner scripts.

## Examples

``` r
if (FALSE) { # \dontrun{
get_practice_exam()         # list available practice exams
get_practice_exam("exam2")  # copy exam 2's datasets into your project
} # }
```
