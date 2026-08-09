# BisonExplorR Coach server

BisonExplorR Coach server

## Usage

``` r
coach_server(id, exercise_state, exercise_id, request_fun = coach_request)
```

## Arguments

- id:

  Shiny module ID matching
  [`coach_ui()`](https://aso003-bucknell.github.io/BisonExplorR/reference/coach_ui.md).

- exercise_state:

  A reactive expression returning the selected learnr exercise state,
  usually from
  [`learnr::get_tutorial_state()`](https://pkgs.rstudio.com/learnr/reference/get_tutorial_state.html).

- exercise_id:

  Stable identifier sent to the secure coach endpoint.

- request_fun:

  Request function. The default uses
  [`coach_request()`](https://aso003-bucknell.github.io/BisonExplorR/reference/coach_request.md).

## Value

Invisibly returns a reactive containing the message thread.
