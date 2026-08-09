# Choose the right offline hint for an exercise

Dispatches on `exercise_id` so a stuck student gets a nudge about the
exercise they are actually attempting. Unknown ids fall back to a purely
structural prompt rather than inventing specifics about the wrong
dataset.

## Usage

``` r
.bx_local_hint(exercise_id, student_code, question = "", correct = FALSE)
```
