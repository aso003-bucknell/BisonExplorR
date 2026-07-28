# Worksheet — the six real-exam rows for `DATASET_REGISTRY.md`

**Why this is a worksheet and not a completed table:** the real exam documents
(`BIOL204_R_Exam1.docx`, `BIOL204_R_Exam2.docx`) and their CSVs are instructor-controlled and
are not in project knowledge. Only the practice exams and their keys are. The exact filenames
and column sets therefore cannot be recovered from anything I can read — inventing them would
put fabricated values into the one file whose entire job is to be trustworthy.

This should take about ten minutes with both exam documents open.

---

## What to record, and where to find it

For each dataset, the registry needs four things. Three are in the exam document; one is in
the CSV.

| Field | Where it is |
|---|---|
| **Filename** | The `read.csv("____.csv")` line in the exam text |
| **Organism** | The scenario paragraph above it |
| **Columns** | `names(read.csv("____.csv"))` — or the codebook, if the exam ships one |
| **Rows** | `nrow()` — **check this against every row count quoted in the exam and key** |

> Run this in the exam-day Posit Cloud project, with all six CSVs present:
>
> ```r
> for (f in list.files(pattern = "\\.csv$")) {
>   d <- read.csv(f)
>   cat(f, " | ", nrow(d), " rows | ", paste(names(d), collapse = ", "), "\n\n")
> }
> ```
>
> Paste the output straight into the table below.

---

## Table to complete

Replace the italic placeholders, then paste the whole block over the "Real exam datasets"
table in `DATASET_REGISTRY.md`.

| Exam | Section | Filename | Organism | Columns | Rows |
|---|---|---|---|---|---|
| R Exam 1 | 1 · interpretation | `bee_visits.csv` | bees | *fill* | *fill* |
| R Exam 1 | 2 · guided | `salamander_streams.csv` | salamanders | *fill* | *fill* |
| R Exam 1 | 3 · open | `lizard_metabolism.csv` | lizards | *fill* | *fill* |
| R Exam 2 | 1 · interpretation | *fill* | birds | *fill* | *fill* |
| R Exam 2 | 2 · guided | *fill* | fish | *fill* | *fill* |
| R Exam 2 | 3 · open (ANCOVA) | *fill* | stream invertebrates | *fill* | *fill* |

The three Exam 1 filenames are recorded in the seed (§8) and are reliable. The three Exam 2
filenames were never written down — only the organisms were.

---

## Then re-run the collision check

Once the table is filled, three things need re-checking. The current registry's collision
check is explicitly conditional on this.

- [ ] **Filenames.** No real exam filename may appear in the practice or teaching tables.
      The known near-miss is `moth_visits.csv` (practice) against `bee_visits.csv` (real) —
      not a collision, but the closest pair in the set.
- [ ] **Column sets.** No real dataset may have a column set *identical* to a practice one.
      Individual shared names are fine and wanted. The one to look at hardest is R Exam 2
      section 3 (stream invertebrates, ANCOVA) against `cricket_metabolism.csv` — both are
      "id, treatment factor, body-size covariate, rate response," so they may well match
      structurally even with different names. **A structural match is acceptable; an exact
      column-name match is not.**
- [ ] **Row counts.** Every row count quoted in an exam document or key becomes a graded
      constraint the moment it is written down. Confirm each quoted number against `nrow()`
      rather than against the generator script.

---

## While the six rows are blank

The registry's collision guarantee is currently **only as strong as the organism column**.
Organisms are disjoint across all four documents, which is real protection — a student who
loads the wrong CSV gets birds where they expected crickets and will notice. But the
filename check, which is the one that catches the *silent* failure mode described at the top
of the registry, cannot be completed until these rows exist.

Nothing about this blocks the pkgdown build or the graded deployment. It blocks relying on
`DATASET_REGISTRY.md` as a safety check, which is a different and slower kind of risk.
