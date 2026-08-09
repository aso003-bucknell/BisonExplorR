# Copy an in-lab R script into your project

In-lab exercises ship with BisonExplorR as plain R scripts. They live
inside the installed package, which is read-only, so this function
copies one into your current Posit Cloud project where you can open,
edit, and run it with a partner.

## Usage

``` r
get_lab(lab = NULL, overwrite = FALSE)
```

## Arguments

- lab:

  Name of the lab script, without the `.R` extension (e.g.
  `"wrangle-visualize"`). If `NULL`, the available labs are listed.

- overwrite:

  Replace an existing copy in your project? Defaults to `FALSE` so you
  never lose work you've already done.

## Value

(Invisibly) the path to the copied file, or the vector of available lab
names when `lab = NULL`.

## Details

Call `get_lab()` with no arguments to see which labs are available.

## Examples

``` r
if (FALSE) { # \dontrun{
get_lab()                       # list available labs
get_lab("wrangle-visualize")    # copy one into your project
} # }
```
