# Project Knowledge Sync — 2026-07-22

What to change in project knowledge so it matches this session’s work.
**Three actions: replace, add, delete.** The deletes matter as much as
the adds — leaving the old files in place means two numbering schemes
coexist and a future session can’t tell which is authoritative.

------------------------------------------------------------------------

## 1. DELETE these (superseded — old numbering)

| File | Why |
|----|----|
| `03-wrangle-visualize.Rmd` | duplicate of Module 4 with the old `tutorial_id = "module2"` bug |
| `06-two-way-anova.Rmd` | renumbered → `07-two-way-anova.Rmd` |
| `07-regression-ancova.Rmd` | renumbered **and rewritten** → `08-ancova.Rmd` |
| `08-choosing-a-test.Rmd` | renumbered → `09-choosing-a-test.Rmd` |
| `09-joining-data.Rmd` | renumbered → `10-joining-data.Rmd` |

⚠️ `09-joining-data.Rmd` is the trap: the new `10-joining-data.Rmd` has
the same content but `tutorial_id = "module10"`. Two files claiming to
be the joining module, differing only in a logged id, is exactly the
kind of thing that silently splits a grading run.

------------------------------------------------------------------------

## 2. REPLACE these (same filename, new contents)

| File | What changed |
|----|----|
| `BisonExplorR_project_seed.md` | rewritten — new module table, verified stats, coach section |
| `04-wrangle-visualize.Rmd` | joins removed, `q1:q11` |
| `05-groups.Rmd` | logging harness wired |
| `grade_module.R` | lookup rewritten for modules 1–10 |
| `exercise_registry.R` | remapped + expanded 5 → 16 entries |
| `coach_request.R` | exercise-aware offline fallback |
| `coach_module.R` | hardened state extraction |
| `COACH_INTEGRATION.md` | rewritten as the integration guide |

------------------------------------------------------------------------

## 3. ADD these (new files)

| File | What it is |
|----|----|
| `06-regression.Rmd` | new Module 6 — linear regression, coach-wired |
| `07-two-way-anova.Rmd` | renumbered from 06 |
| `08-ancova.Rmd` | rebuilt — regression trimmed to review, new slopes-check `q3` |
| `09-choosing-a-test.Rmd` | renumbered from 08 |
| `10-joining-data.Rmd` | renumbered from 09 |
| `algae_light.csv` | verified Module 6 dataset |

------------------------------------------------------------------------

## 4. Repo placement (separate from project knowledge)

Project knowledge is the context store; these also need to land in the
actual package:

> ⚠️ **Corrected 2026-07-25.** The line below originally read
> `inst/coach-endpoint/ … <- NOT installed to students`. **That was
> wrong.** Everything under `inst/` installs and is reachable with
> [`system.file()`](https://rdrr.io/r/base/system.file.html). The folder
> has been moved to the repo root and `.Rbuildignore`d. See seed §9 for
> the full reasoning; run `dev/move-coach-endpoint.R` to apply.

    R/                     grade_module.R, get_lab.R, coach_module.R,
                           coach_request.R, launch_graded_tutorial.R
    inst/tutorials/        01-data-import/ … 10-joining-data/
                           (folder name == .Rmd basename; learnr takes the
                           tutorial name from the DIRECTORY)
    inst/extdata/          algae_beads.csv, algae_light.csv, cardio.csv,
                           mammals_data.csv, soil_data.csv
    inst/labs/             *.R lab scripts

    coach-endpoint/        plumber.R, exercise_registry.R, README.md
                           ^ REPO ROOT, .Rbuildignore'd — does NOT install.
                             Deployed by copying this folder to the proxy host.
    dev/                   preflight-module5.R, verify_module5.R,
                           module5-state-probe.Rmd, align-tutorial-folders.R,
                           move-coach-endpoint.R
                           ^ .Rbuildignore'd. A probe left in inst/tutorials/
                             would appear in every student's Tutorial pane.

**The test for anything in this tree:** if a student running
`system.file("<dir>", package = "BisonExplorR")` seeing that file would
be a problem, it does not belong under `inst/`. There is no “in the repo
but not installed” state inside `inst/` — only `.Rbuildignore` at the
root gives you that.

`exercise_registry.R` and `plumber.R` are deployed to the proxy host,
**not** shipped to students — the registry’s `skill` fields are the
closest thing to solutions in the project.

------------------------------------------------------------------------

## 5. Leave alone

Everything ending `Spring2026` (last year’s materials), the exam `.docx`
files and keys (instructor-controlled, out of package by design),
`01`/`02` tutorials, `tutorial_inlab_audit.md` (a dated snapshot — its
findings are now folded into the seed, but it’s worth keeping as a
record of what was audited when).

------------------------------------------------------------------------

## 6. After syncing — first three things

1.  **Verify `get_tutorial_state()` field names in Posit Cloud.**
    Blocking for the coach; see seed §9. Ten minutes, and the whole
    feature hangs on it.
2.  ~~**Decide Module 1’s labels.**~~ **Resolved 2026-07-23** — the
    lookup was repointed at M1’s nine descriptive labels (it had been
    scoring every student 0), and M8’s `q1:q4` → `q1:q3` (it had been
    capping every student at 75%). The remaining grading question is a
    *policy* one: whether Module 2 counts for credit, and whether M3
    should keep grading only 2 of its 8 exercises.
3.  **Test-render one renumbered module** end to end, confirming a
    submission actually lands in the Google Sheet with the right
    `tutorial_id`. The harnesses are wired but have never been run.
