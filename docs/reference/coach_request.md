# Send one BisonExplorR Coach request

This is an internal helper used by
[`coach_server()`](https://aso003-bucknell.github.io/BisonExplorR/reference/coach_server.md).
The secure endpoint is configured with
`options(BisonExplorR.coach_url = "https://...")` or the
`BISONEXPLORR_COACH_URL` environment variable. The endpoint must return
JSON containing a single `reply` field.

## Usage

``` r
coach_request(
  exercise_id,
  student_code,
  question,
  correct = FALSE,
  timeout_seconds = 20
)
```

## Details

When no endpoint is configured, or the endpoint cannot be reached, the
function returns a deterministic local hint so the tutorial interface
can be tested without exposing an API key.
