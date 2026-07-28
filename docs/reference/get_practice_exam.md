# Copy a practice exam's datasets into your project

Practice exam datasets ship with BisonExplorR. They live inside the
installed package, which is read-only, so this function copies them into
your current Posit Cloud project where your code can read them.

## Usage

``` r
get_practice_exam(exam = NULL, overwrite = FALSE)
```

## Arguments

- exam:

  Name of the practice exam, e.g. `"exam2"`. If `NULL`, the available
  practice exams are listed.

- overwrite:

  Replace files already in your project? Defaults to `FALSE` so you
  never clobber work in progress.

## Value

(Invisibly) the paths of the copied files, or the vector of available
practice exam names when `exam = NULL`.

## Details

This deliberately mirrors how the real exam works. On exam day the CSVs
are already sitting in your project folder, so your code reads them by
bare filename:


    turtles <- read.csv("turtle_growth.csv")

Practising with
[`system.file()`](https://rdrr.io/r/base/system.file.html) instead would
mean rehearsing a call you will not use on exam day, so this function
puts the files where the exam expects them.

Call `get_practice_exam()` with no arguments to see what is available.

## Examples

``` r
if (FALSE) { # \dontrun{
get_practice_exam()          # list available practice exams
get_practice_exam("exam2")   # copy exam 2's datasets into your project
} # }
```
