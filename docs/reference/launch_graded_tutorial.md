# Open the graded (credit-bearing) version of a tutorial

Each module has two ways in.
[`learnr::run_tutorial()`](https://pkgs.rstudio.com/learnr/reference/run_tutorial.html)
opens a **practice** copy inside Posit Cloud — unlimited, ungraded, and
encouraged. This function opens the **deployed** copy in a browser tab,
which is the one that logs attempts for credit.

## Usage

``` r
launch_graded_tutorial(module = NULL)
```

## Arguments

- module:

  Which module to open, e.g. `"module5"`. Also accepts the folder-style
  name (`"05-groups"`) or a bare number (`5`). If `NULL`, the available
  modules are listed.

## Value

(Invisibly) the URL opened, or the vector of module ids when
`module = NULL`.

## Details

Call `launch_graded_tutorial()` with no arguments to list the modules.

## Instructor note — the URL map

`graded_urls` below is the only thing that needs editing when tutorials
are (re)deployed. Any module left as `NA_character_` raises an
informative error rather than opening a broken tab, so a half-deployed
course fails loudly at the module that is missing instead of silently
everywhere.

The names of `graded_urls` are `tutorial_id` values (`"module5"`),
**not** folder names (`"05-groups"`). Those are separate namespaces; see
the seed document. Student-facing input is normalised so all three of
`"module5"`, `"05-groups"`, and `5` reach the same entry.

## Examples

``` r
if (FALSE) { # \dontrun{
launch_graded_tutorial()           # list the modules
launch_graded_tutorial("module1")  # open Module 1 for credit
} # }
```
