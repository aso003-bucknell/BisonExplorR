# Reusable Shiny module for the BisonExplorR Coach.

`%||%` <- function(a, b) if (!is.null(a) && length(a) > 0) a else b

.bx_coach_css <- function() {
  paste0(
    ".bx-coach-card{border:1px solid #E2DDD2;border-radius:12px;background:#fff;",
    "overflow:hidden;margin:16px 0 22px;font-family:system-ui,-apple-system,Segoe UI,sans-serif;}",
    ".bx-coach-head{display:flex;align-items:center;gap:9px;padding:12px 15px;",
    "border-bottom:1px solid #E2DDD2;color:#12324F;font-weight:700;}",
    ".bx-coach-mark{width:27px;height:27px;border-radius:50%;background:#C0602A;",
    "color:#fff;display:flex;align-items:center;justify-content:center;font-weight:800;}",
    ".bx-coach-status{padding:9px 14px;background:#F5F3EE;color:#3C5871;font-size:12px;}",
    ".bx-coach-thread{min-height:112px;max-height:270px;overflow-y:auto;padding:14px;",
    "display:flex;flex-direction:column;gap:9px;}",
    ".bx-msg{max-width:92%;padding:9px 12px;border-radius:11px;line-height:1.45;",
    "white-space:pre-wrap;font-size:14px;}",
    ".bx-msg-coach{align-self:flex-start;background:#F3E4D6;color:#1E2A33;",
    "border-bottom-left-radius:3px;}",
    ".bx-msg-student{align-self:flex-end;background:#12324F;color:#fff;",
    "border-bottom-right-radius:3px;}",
    ".bx-coach-input{border-top:1px solid #E2DDD2;padding:12px 14px;}",
    # Every property declared explicitly. These rules previously set background
    # and border-color only, inheriting color/padding/border-width from
    # whatever Bootstrap the tutorial happened to load -- and .btn-default was
    # REMOVED in Bootstrap 4, so under bslib it styled nothing at all. Result:
    # "I'm stuck" rendered with no button chrome and "Ask the coach" rendered
    # with unreadable text. Do not trim these back to the shorthand.
    #
    # Colour is #B55A14, the functional orange, NOT the #C0602A this card used
    # to use: #C0602A is 4.24:1 on white and fails AA in BOTH directions.
    # #B55A14 is 4.73:1. See the contrast table in the seed.
    ".bx-coach-actions{display:flex;gap:8px;align-items:center;}",
    ".bx-coach-actions .btn{border-radius:8px;font-weight:600;font-size:14px;",
    "padding:7px 14px;line-height:1.4;cursor:pointer;}",
    ".bx-coach-actions .btn-default{background:#fff;color:#B55A14;",
    "border:1px solid #B55A14;}",
    ".bx-coach-actions .btn-primary{background:#B55A14;color:#fff;",
    "border:1px solid #B55A14;flex:1;}",
    ".bx-coach-actions .btn[disabled]{opacity:.55;cursor:not-allowed;}",
    ".bx-mode{display:inline-block;border-radius:20px;padding:2px 7px;margin-left:5px;",
    "background:#F3E4D6;color:#9A461D;font-weight:700;text-transform:uppercase;",
    "letter-spacing:.45px;font-size:10px;}"
  )
}

#' BisonExplorR Coach user interface
#'
#' @param id Shiny module ID.
#' @param title Heading displayed above the coach.
#'
#' @return A Shiny UI tag list.
#' @export
coach_ui <- function(id, title = "BisonExplorR Coach") {
  ns <- shiny::NS(id)

  shiny::tagList(
    shiny::tags$style(htmltools::HTML(.bx_coach_css())),
    shiny::div(
      class = "bx-coach-card",
      shiny::div(
        class = "bx-coach-head",
        shiny::span(class = "bx-coach-mark", "B", `aria-hidden` = "true"),
        shiny::span(title)
      ),
      shiny::uiOutput(ns("status")),
      shiny::uiOutput(ns("thread")),
      shiny::div(
        class = "bx-coach-input",
        shiny::textAreaInput(
          ns("question"),
          label = NULL,
          value = "",
          rows = 2,
          width = "100%",
          placeholder = "Ask about your latest submitted code..."
        ),
        shiny::uiOutput(ns("controls"))
      )
    )
  )
}

.bx_normalize_exercise_state <- function(x) {
  if (inherits(x, "reactivevalues")) {
    x <- shiny::reactiveValuesToList(x)
  }

  if (is.null(x) || !is.list(x)) {
    return(list(
      attempted = FALSE,
      code = "",
      correct = FALSE,
      timestamp = ""
    ))
  }

  # learnr's exercise state has not carried a stable field name across
  # versions: the submitted source has appeared as $answer, $code, and
  # $user_code depending on release. Try them in order rather than betting on
  # one, so a learnr upgrade degrades to "no attempt yet" instead of silently
  # coaching against an empty string.
  raw_code <- x$answer %||% x$code %||% x$user_code %||% x$last_value
  code <- if (is.null(raw_code)) "" else paste(raw_code, collapse = "\n")
  timestamp <- .bx_scalar_character(x$timestamp)

  list(
    attempted = nzchar(trimws(code)) || nzchar(timestamp),
    code = code,
    correct = isTRUE(x$correct),
    timestamp = timestamp
  )
}

.bx_thread_message <- function(role, text) {
  list(role = role, text = .bx_scalar_character(text))
}

#' BisonExplorR Coach server
#'
#' @param id Shiny module ID matching [coach_ui()].
#' @param exercise_state A reactive expression returning the selected learnr
#'   exercise state, usually from `learnr::get_tutorial_state()`.
#' @param exercise_id Stable identifier sent to the secure coach endpoint.
#' @param request_fun Request function. The default uses [coach_request()].
#'
#' @return Invisibly returns a reactive containing the message thread.
#' @export
coach_server <- function(
    id,
    exercise_state,
    exercise_id,
    request_fun = coach_request) {

  shiny::moduleServer(id, function(input, output, session) {
    initial_mode <- if (nzchar(.bx_coach_endpoint())) "online" else "pilot"
    mode <- shiny::reactiveVal(initial_mode)
    thread <- shiny::reactiveVal(list(
      .bx_thread_message(
        "coach",
        "Submit one attempt in the exercise above. I will read that exact submission and give one next-step nudge rather than the answer."
      )
    ))

    current_state <- shiny::reactive({
      .bx_normalize_exercise_state(exercise_state())
    })

    output$status <- shiny::renderUI({
      state <- current_state()
      mode_label <- switch(
        mode(),
        online = "online coach",
        pilot = "pilot hints",
        fallback = "backup hints",
        `guarded-fallback` = "guarded backup",
        "coach"
      )

      status_text <- if (!state$attempted) {
        "Waiting for your first submitted attempt."
      } else if (state$correct) {
        "This exercise is correct. You can still ask a concept question."
      } else {
        "Ready to discuss your latest submitted attempt."
      }

      shiny::div(
        class = "bx-coach-status",
        status_text,
        shiny::span(class = "bx-mode", mode_label)
      )
    })

    output$thread <- shiny::renderUI({
      messages <- thread()
      shiny::div(
        class = "bx-coach-thread",
        lapply(messages, function(message) {
          css_class <- if (identical(message$role, "student")) {
            "bx-msg bx-msg-student"
          } else {
            "bx-msg bx-msg-coach"
          }
          shiny::div(class = css_class, message$text)
        })
      )
    })

    output$controls <- shiny::renderUI({
      state <- current_state()
      disabled_value <- if (state$attempted) NULL else "disabled"

      shiny::div(
        class = "bx-coach-actions",
        shiny::actionButton(
          session$ns("stuck"),
          "I'm stuck",
          class = "btn-default",
          disabled = disabled_value
        ),
        shiny::actionButton(
          session$ns("ask"),
          "Ask the coach",
          class = "btn-primary",
          disabled = disabled_value
        )
      )
    })

    add_message <- function(role, text) {
      messages <- c(thread(), list(.bx_thread_message(role, text)))
      if (length(messages) > 14L) {
        messages <- tail(messages, 14L)
      }
      thread(messages)
    }

    ask_once <- function(question) {
      state <- current_state()
      if (!state$attempted) {
        return(invisible(NULL))
      }

      question <- trimws(.bx_scalar_character(question))
      if (!nzchar(question)) {
        return(invisible(NULL))
      }

      add_message("student", question)

      result <- shiny::withProgress(
        message = "Coach is reading your latest submission...",
        value = 0.5,
        {
          tryCatch(
            request_fun(
              exercise_id = exercise_id,
              student_code = state$code,
              question = question,
              correct = state$correct
            ),
            error = function(e) list(
              reply = paste0(
                .bx_local_hint(exercise_id, state$code, question, state$correct),
                " The coaching service had a temporary problem, so this is the built-in backup hint."
              ),
              mode = "fallback"
            )
          )
        }
      )

      mode(.bx_scalar_character(result$mode, "fallback"))
      add_message("coach", .bx_scalar_character(
        result$reply,
        "I could not generate a hint just now. Recheck which variable is numeric and which variable defines the two groups."
      ))
      shiny::updateTextAreaInput(session, "question", value = "")
      invisible(NULL)
    }

    shiny::observeEvent(input$stuck, {
      ask_once("I'm stuck. What is the single next thing I should check?")
    }, ignoreInit = TRUE)

    shiny::observeEvent(input$ask, {
      ask_once(input$question)
    }, ignoreInit = TRUE)

    invisible(shiny::reactive(thread()))
  })
}
