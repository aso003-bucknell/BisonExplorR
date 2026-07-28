# BisonExplorR Coach — Tutorial Integration Guide

*Written 2026-07-22, alongside the first live wiring (Module 6).*

---

## 1. Status

Before this pass the coach had a complete backend (`plumber.R`, `exercise_registry.R`) and a complete frontend (`coach_ui()`, `coach_server()`, `coach_request()`) — but **no tutorial called either one**. Module 6 is now the first wired module and serves as the reference pattern.

| Piece | State |
|---|---|
| Secure proxy (`plumber.R`) | built, not deployed |
| Exercise registry | **remapped + expanded to 16 exercises** (was 5, all stale after renumbering) |
| Client request + fallback | **fixed** — was t-test-only, now exercise-aware |
| Shiny module | **hardened** against learnr field-name drift |
| Tutorial wiring | **Module 6 only** — pattern below |
| `get_tutorial_state()` contract | **verified live 2026-07-22** |

---

## 2. The wiring pattern

Three edits per tutorial.

**a. Load it in `setup`:**

```r
library(shiny)
library(BisonExplorR)   # coach_ui() / coach_server()
```

**b. One `coach_server()` per coached exercise, in a `context="server"` chunk.**
This chunk must exist once per file, near the top:

````r
```{r coach-server, context="server"}
coach_server("coach_q2", shiny::reactive(learnr::get_tutorial_state("q2")), "module6-q2")
coach_server("coach_q4", shiny::reactive(learnr::get_tutorial_state("q4")), "module6-q4")
```
````

The three arguments are: the **Shiny module id** (local to the file), a **reactive wrapping the exercise state**, and the **`exercise_id`** sent to the endpoint. That third string must match a key in the server-side `exercise_registry.R`.

**c. Drop the UI after the exercise:**

````r
```{r coach-ui-q2, echo=FALSE}
coach_ui("coach_q2", "Stuck? Ask the Coach")
```
````

The `coach_q2` id must match the `coach_server()` call. Mismatched ids fail silently — the card renders and never responds.

---

## 3. Which exercises get a coach

Not all of them. The coverage rule:

> **Coach the steps where students actually stall** — write-from-scratch, test *selection*, and interpretation. Skip single-blank fills, where the inline hint already does the job and a coach just adds noise and cost.

Module 6 coaches **q2, q4, q5** and deliberately skips q1 (a scatter plot they built in M4) and q3 (a one-function recall). Three of five is roughly the ratio to aim for.

The highest-value target in the whole package is **Module 9**, the capstone — the Spring 2026 survey put test selection at the top of the difficulty list (~33%), and it is the one place where a Socratic nudge ("count the predictors, then ask the type of each") is worth much more than a worked answer.

---

## 4. Two problems found and fixed

### The offline fallback was giving t-test advice everywhere

`.bx_local_q1_hint()` inspected student code for `t.test`, `resting_hr_bpm`, and `sex` — it was written for Module 5 q1 and never generalised. It is also the **default** path: `coach_request()` returns `mode = "pilot"` and calls the local hint whenever no endpoint is configured, which is exactly the state during a pilot.

Net effect: a student stuck on regression in M6 would have been told to recheck "which named column contains the two sex groups."

**Fixed.** The function is renamed `.bx_local_ttest_hint()` and kept as the M5 q1 specialist. A new `.bx_local_hint(exercise_id, ...)` dispatches on exercise id against a `.bx_offline_nudges` table covering all 16 registered exercises, with `blank` / `stuck` / `done` variants. Unknown ids fall through to a purely structural prompt that invents nothing.

These nudges ship inside the package and are student-inspectable, so they are written to the same contract as the online coach: name a concept, point at what to reconsider, never assemble a line.

### The registry was entirely stale from module 6 up

Renumbering changed what every id above `module5` refers to. Remapped:

| Old | New | Why |
|---|---|---|
| `module4-q13` | `module4-q10` | M4 exercises renumbered when joins were cut |
| `module7-q3` | `module8-q1` | ANCOVA moved to M8 and became its first exercise |
| `module9-q1` | `module10-q1` | joining moved to M10 |

`module5-q1` and `module5-q3` are unchanged. Registry expanded from 5 entries to 16.

---

## 5. Open decisions

- [ ] **Deploy the proxy.** Until `options(BisonExplorR.coach_url = ...)` is set, every coach runs in pilot mode on the offline nudges. Those are now correct per-exercise, but they are static — no reading of the student's actual mistake.
- [ ] **Lock the strictness dial** (strict / medium / lenient). Currently the system prompt in `plumber.R` is fixed at roughly "medium": may name a function or argument in prose, may not assemble a line.
- [x] ~~Verify `get_tutorial_state()` field names live.~~ **Done 2026-07-22.** Returns `$type` / `$answer` / `$correct` / `$timestamp`; `.bx_normalize_exercise_state()` reads `$answer` and `$correct` as originally designed. State populates on **Submit**, not Run, and is `NULL` before the first submission.
- [ ] **Research confound.** The coach may need to be held out of the study year or treated as a separate arm. If it ships to only some sections, the wiring is per-file and easy to omit — but `grade_module()` cannot currently tell coached from uncoached attempts. Consider logging a coach-use flag if the comparison matters.
- [ ] **Cost.** `claude-haiku-4-5-20251001`, 300 max tokens, 40 requests/min per process. With ~175 students the rate limit is the thing to watch on a homework-due evening, not the token spend.
