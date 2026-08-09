# Graded Mode — Verification Runbook

**Written 2026-07-28. Run in Posit Cloud, working directory at the
package root.**

Covers the `bx_is_graded()` change applied to all ten modules: the ID
box now appears only in the graded deployment, practice copies do not
log, and the Continue button is gated on a non-empty ID.

**Phase 3 is the one that matters** — it is the only phase testing a
thing that fails *silently*.

------------------------------------------------------------------------

## What changed, per module

| Piece | Where | Does what |
|----|----|----|
| `bx_is_graded()` | `setup` chunk | Reads `getOption("BisonExplorR.graded")`, else env var `BISONEXPLORR_GRADED` |
| Logging gate | first line of `log_attempt()` | Practice copies return early and POST nothing |
| `uiOutput("sid_ui")` | `student-id` chunk | Placeholder only; no static `textInput` remains |
| `sid-server` chunk | `context="server"` | Renders the ID box **or** the practice banner; caches ID to `userData`; injects the Continue-button gate |
| [`library(shiny)`](https://shiny.posit.co/) | `setup` chunk | Added to M1–M3, which lacked it |

------------------------------------------------------------------------

## Phase 0 — Set the flag on the deployed app only

In the **deployed** app bundle, add a `.Renviron` at its root:

    BISONEXPLORR_GRADED=true

`.Renviron` is in the deployed bundle, **not** in the package source. If
it lands in the package, every practice copy becomes a graded copy and
starts logging.

Confirm `.Renviron` is **not** matched by `.Rbuildignore` in a way that
strips it from the deploy, and **is** excluded from the installed
package.

------------------------------------------------------------------------

## Phase 1 — Practice copy behaves as practice

``` r

learnr::run_tutorial("05-groups", package = "BisonExplorR")
```

An orange **“Practice mode”** banner appears where the ID box used to be

**No** student ID text box anywhere

The Continue button works normally with nothing entered

Submit one exercise, then check the Google Sheet: **no new row**

> If you see the ID box here, `bx_is_graded()` returned TRUE in a
> practice session — check whether a stray `.Renviron` or
> [`options()`](https://rdrr.io/r/base/options.html) call is setting the
> flag globally.

------------------------------------------------------------------------

## Phase 2 — Graded copy behaves as graded

Open the deployed URL, or simulate locally:

``` r

options(BisonExplorR.graded = TRUE)
learnr::run_tutorial("05-groups", package = "BisonExplorR")
```

Navy **“Graded copy”** banner and the ID text box both appear

With the box empty: Continue is greyed out, and “Enter your ID to
continue” is visible

Type an ID: Continue becomes clickable and the warning disappears

Clear the box again: Continue re-disables *(tests the input listener,
not just first paint)*

Submit a code exercise → row lands in the Sheet with the real ID

Answer an MC item → row lands with the real ID *(this is the
`bx_get_sid()` path)*

> **The gate is client-side and defeatable with devtools.** It exists to
> stop the student who forgets, not the one who is trying. The actual
> protection against unattributed rows is that
> [`grade_module()`](https://aso003-bucknell.github.io/BisonExplorR/reference/grade_module.md)
> drops blank IDs — which means a determined student who bypasses the
> gate scores zero rather than corrupting anyone else’s data.

------------------------------------------------------------------------

## Phase 3 — State store: RESOLVED FROM SOURCE 2026-07-28

**Both probes are answered. Neither needs a live deployment, and no
reset code should be written.** The answers come from
`learnr/R/storage.R`, `R/identifiers.R`, `R/utils.R`, and
`inst/lib/tutorial/tutorial.js` (learnr 0.11.6).

### Probe B — does the deployed app share one state store across students? **NO.**

The worry was reasonable and the mechanism is real, but it does not
reach the deployment:

1.  **`user_id` genuinely is shared.** `default_user_id()` returns
    `Sys.info()["user"]` — the **OS user of the R process**, not
    `session$user`. On a deployed app every student is the same OS user.
    So the premise of the worry was correct.
2.  **But the deployed app never uses `user_id`.** `tutorial.storage`
    defaults to `"auto"`, which resolves to `filesystem_storage` only
    when `is_localhost(location)` is TRUE. A deployed URL is not
    localhost, so it resolves to **`client_storage()`** instead. Its own
    source comment: *user scope is 100% determined by connecting user
    agent.* `client_storage()` accepts `user_id` as an argument and
    ignores it, keying on
    `paste(tutorial_id, tutorial_version, sep = "-")` alone.
3.  **The authoritative copy lives in the student’s own browser.**
    `save_object()` sends a `tutorial.store_object` custom message; the
    client writes it to **IndexedDB**, database
    `LearnrTutorialProgress`, object store
    `Store_<base64(tutorial_id + tutorial_version)>`. IndexedDB is
    per-origin and per-browser-profile.
4.  **The server-side mirror is per-connection.** It is held in
    `session$request`, a fresh environment on each Shiny session — one
    websocket, one student.

**There is no server-side shared store to leak through.** Two students
on the same deployed app cannot see each other’s progress, authenticated
or not.

**Probe B answered: NO shared store.** Recorded 2026-07-28 from learnr
source.

> **The configuration that WOULD break this — do not do it.** Setting
> `options(tutorial.storage = "local")`, or passing a
> `filesystem_storage()` handler, on the deployment switches to the
> backend that *does* key by `user_id` — and since `user_id` is the
> shared OS user, **every student would collapse into one store.** The
> safe default is the default. Never set `tutorial.storage` on the
> deployed app.

### Probe A — does practice progress carry into the graded copy? **NO.**

Two independent mechanisms each prevent it:

**Different origins.** Practice runs in Posit Cloud; the graded copy is
served from the deployment host. IndexedDB is origin-scoped, so the two
cannot see each other’s stores **even if every identifier matched.**

**Different `tutorial_id`.** No module sets `tutorial: id:` in its YAML,
so the id falls back to `default_tutorial_id()`:
`location$host + location$pathname` off localhost, and
`package:BisonExplorR-<subpath>` on it. Practice and graded therefore
key differently anyway.

**Probe A answered: no carryover.** The graded copy opens at the
beginning.

**No reset code written** — correctly, per the original reasoning.

> **The `tutorial: id:` fix is not needed and should not be added.** It
> would have been a FOURTH identifier alongside folder name /
> `tutorial_id` / coach registry key (seed §10), for no gain. Leave the
> YAML alone.

### One consequence worth knowing about

Store names include `tutorial_version`, which
`default_tutorial_version()` takes from **DESCRIPTION’s `Version:`
field** when running from an installed package. So bumping the package
version mid-semester **discards every practice copy’s stored progress**
— the old IndexedDB store is simply no longer looked up.

This does not touch the graded copies: on a deployed bundle
`package_info()` finds no package root, so `tutorial_version` is the
constant `"1.0"`. And it does not touch grading at all, which reads the
Google Sheet, not learnr state. But if a student reports that practice
work vanished after an update, this is why — and it is expected, not a
bug.

## Phase 4 — `allow_skip`: DECIDED 2026-07-28

**Set `allow_skip: false` in all ten modules, and add a per-section
override on the exercise-heavy sections.**

The split as found — M1–M4 `false`, M5–M10 `true` — was an artifact of
build order, not a choice: M5 onward were written from a later template.

### Why `false` globally

- **It is what makes the ID gate binding.** Where `allow_skip: true`,
  learnr renders a Skip control that moves past the ID section without
  the Continue button, so the gate is advisory. At `false` there is no
  bypass short of devtools.
- **`progressive: true` is already set everywhere**, so sections already
  reveal one at a time. `allow_skip` only governs whether a student may
  leave a section *unfinished*.
- **Consistency is worth something on its own.** Ten tutorials that
  behave differently for no stated reason is a support burden.

### Why a blanket `false` is not enough on its own

At `false`, learnr disables Continue until **every** exercise in the
section is complete, and shows *“You must complete the N exercises in
this section before continuing.”* For a cohort with high R anxiety, that
is a trap: a student stuck on one write-from-scratch exercise at 11 p.m.
cannot reach the rest of the tutorial, and the work they *could* have
done is lost along with the work they could not.

### The override

learnr honours a **per-section** `data-allow-skip` attribute, which
beats the YAML default. Put it on the sections where being stuck is
plausible — the write-from-scratch exercises the Coach is already
pointed at:

``` markdown
## Exercise q3: interaction plot {data-allow-skip="true"}
```

This gives the shape you actually want: **the ID section is unskippable,
the content is sequential, and the hardest exercises have an escape
hatch.** A student who skips still logs nothing for that exercise and
scores zero on it — the same outcome as not finishing — but keeps access
to the rest of the module.

> ⚠️ **`data-allow-skip` is a one-way switch — presence is what counts,
> not value.** Verified in `tutorial-format.js` (learnr 0.11.6). The
> attribute handler reads:
>
> ``` js
> if (typeof allowSkipAttr !== 'undefined' && allowSkipAttr !== false) {
>   sectionAllowSkip = allowSkipAttr = 'true' || allowSkipAttr === 'TRUE';
> }
> ```
>
> The right-hand side is a constant: `'true' || …` always evaluates to
> the string `'true'`. So **`data-allow-skip="false"` enables skipping
> just as surely as `"true"` does.** The attribute can only ever open a
> section, never close one.
>
> Two consequences. First, the direction of this plan is the only one
> that works: set the restrictive policy in YAML and use the attribute
> to open specific sections. Second, **never write
> `data-allow-skip="false"` anywhere** — it does the opposite of what it
> reads as, and it would fail silently on exactly the section you were
> trying to lock down.

### Applying it

Change `allow_skip: true` → `false` in M5–M10 (six files). M1–M4 already
correct.

Add `{data-allow-skip="true"}` to the write-from-scratch section
headings. Candidates, from the coach registry’s own coverage decision:
M4 q5/q10, M5 q1/q3, M6 q2/q5, M7 q1/q3, M8 q1/q4, M9 q1/q2/q3, M10
q1/q4.

Do **not** add it to the “Before you start” ID section in any module.

⚠️ **Preserve line endings.** M1, M3, and the other CRLF files must stay
CRLF; editing with a tool that rewrites them will show every line of
those files as changed. Edit in place.

## Phase 5 — Rebuild and re-check

``` r

devtools::install(upgrade = F)
.rs.restartR()
source("dev/preflight-module5.R")
```

Preflight passes **39/40** with only the expected `coach_url` warning.
⚠️ **Not 45/45** — that figure came from a copy of the script that was
never committed; the repo version has 40 checks. The one FAIL, “registry
object reachable”, appears only when `coach-endpoint/` is missing from
the working folder — it is gitignored, so it never arrives with a fresh
clone and must be copied across by hand.

Spot-check one module from each group — M1 (CRLF, no coach) and M9 (LF,
coach-wired) — to confirm both the banner and the ID box render
