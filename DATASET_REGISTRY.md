# BisonExplorR — Dataset Registry

**Purpose: prevent a practice dataset from ever colliding with a real
exam dataset.**

Practice materials ship inside the installable package and are therefore
student-inspectable and permanent. Real exam datasets do not. The safety
of that arrangement rests on one property: **a practice dataset must
never share a filename or a full column set with a real exam dataset.**
This file is where that property is checked, because it is not
self-enforcing.

Started 2026-07-28. Update it in the same edit that creates any new exam
or practice dataset.

> **Row counts are load-bearing on exams, not decoration.** Practice
> Exam 1 Q2 asks how many rows `shrub_summary` will have, and Practice
> Exam 2 Q1 and Q4 quote 90 / 36 / 18 / 24. If a dataset is ever
> regenerated, those numbers in the exam text and key go stale silently.
> Treat every row count in this table as a graded constraint.

------------------------------------------------------------------------

## The rule

A new dataset is safe to ship in `inst/practice-exams/` only if **all
three** hold:

1.  **Filename** appears nowhere in the “real exam” section below.
2.  **Organism** differs from every real exam dataset in the same exam.
3.  **Column set** is not identical to a real exam dataset’s.
    Overlapping *individual* names (`species`, `mass_g`) are fine and in
    fact desirable — students should meet familiar variable names. A
    full column-set match is not, because it means the practice CSV is a
    drop-in substitute for the real one.

> **Why filename matters more than it looks.** Both real and practice
> exams read by **bare filename** (`read.csv("turtle_growth.csv")`),
> because exam CSVs are dropped into the exam-day Posit Cloud project
> rather than installed. If a practice CSV shares a real exam CSV’s name
> and a student has run
> [`get_practice_exam()`](https://aso003-bucknell.github.io/BisonExplorR/reference/get_practice_exam.md)
> in that project, their copy silently shadows the real one — and their
> answers will be internally consistent but wrong. Nothing errors.

------------------------------------------------------------------------

## Real exam datasets — NEVER ship in the package

Live in `exams/` at the repo root (`.Rbuildignore`d) and are dropped
into the exam-day Posit Cloud project.

| Exam | Section | Filename | Organism | Columns |
|----|----|----|----|----|
| R Exam 1 | 1 · interpretation | `bee_visits.csv` | bees | *not recorded — fill from the exam doc* |
| R Exam 1 | 2 · guided | `salamander_streams.csv` | salamanders | *not recorded* |
| R Exam 1 | 3 · open | `lizard_metabolism.csv` | lizards | *not recorded* |
| R Exam 2 | 1 · interpretation | *bird surveys — exact filename not recorded* | birds | *not recorded* |
| R Exam 2 | 2 · guided | *fish growth — exact filename not recorded* | fish | *not recorded* |
| R Exam 2 | 3 · open (ANCOVA) | *stream invertebrates — filename not recorded* | stream inverts | *not recorded* |

> ⚠️ **Six gaps — still open as of 2026-07-28.** The real exam documents
> are instructor-controlled and not in project knowledge, so the exact
> filenames and column sets above cannot be read. **See
> `EXAM_ROWS_WORKSHEET.md`** for a fill-in table, the one-liner that
> dumps [`nrow()`](https://rdrr.io/r/base/nrow.html) and
> [`names()`](https://rdrr.io/r/base/names.html) for every CSV in the
> exam-day project, and the three re-checks to run afterwards (~10
> minutes with both exam documents open). Until then the collision check
> below is only as good as the organism column — real protection, but
> not the filename check that catches the *silent* failure mode
> described above.
>
> The three **Exam 1** filenames are reliable (recorded in seed §8). The
> three **Exam 2** filenames were never written down anywhere — only the
> organisms were.

------------------------------------------------------------------------

## Practice exam datasets — ship in `inst/practice-exams/`

| Exam | Section | Filename | Organism | Columns | Rows |
|----|----|----|----|----|----|
| Practice 1 | 1 | `moth_visits.csv` | moths | `patch_id, shrub, patch_area_m2, visits_per_hr, pollen_mg` | 45 |
| Practice 1 | 2 | `frog_reaches.csv` | frogs | `reach_id, shade, water_temp_c, snout_vent_mm, mass_g` | 60 |
| Practice 1 | 3 | `frog_jump.csv` | frogs | `frog_id, sex, elevation, femur_mm, jump_cm, temp_c` | 90 |
| Practice 2 | 1 | `bat_captures.csv` | bats | `bat_id, species, roost, forearm_mm, mass_g, torpid` | 90 |
| Practice 2 | 1 | `roost_sites.csv` | — (lookup) | `roost, elevation_m, canopy_cover` | 3 |
| Practice 2 | 2 | `turtle_growth.csv` | turtles | `turtle_id, habitat, carapace_mm, mass_g, growth_rate_mm_yr` | 60 |
| Practice 2 | 3 | `cricket_metabolism.csv` | crickets | `cricket_id, temp_treatment, body_mass_mg, metabolic_rate_ul_hr` | 54 |

**Practice 1 verified statistics** (computed from the CSVs, 2026-07-28):

- `moth_visits` — 45 patches, 15 per shrub. Mean visits/hr: buckwheat
  10.307 (SE 1.026), manzanita 20.333 (SE 1.068), sage 24.680 (SE
  1.178). Pooled without `group_by()`: 18.440 (SE 1.097). `busy_patch`
  is TRUE for 21 of 45.
- `frog_reaches` — 60 reaches, 20 per shade. Mean mass: exposed 3.891
  (SE 0.128), dappled 5.728 (SE 0.206), shaded 6.777 (SE 0.228).
- `frog_jump` — 90 frogs, 45 per sex, 30 per elevation. Regression
  `jump_cm ~ femur_mm`: slope **0.4584**, R² **0.6269**, p = 1.53e−20,
  **intercept NS (p = 0.388)**. Welch t-test by sex **t = −3.069, df =
  86.90, p = 0.00286**. One-way ANOVA by elevation **F₂,₈₇ = 13.778, p =
  6.34e−06**; Tukey **lowland–montane NS (p = 0.994)**, alpine differs
  from both. ⚠️ **The sex × elevation design is UNBALANCED** (13/14/18
  vs 17/16/12), so Type I ≠ Type II: the extra-credit two-way gives sex
  F = 12.107 under [`aov()`](https://rdrr.io/r/stats/aov.html) but F =
  8.890 under Type II. Interaction **F = 1.097, p = 0.339 NS** either
  way.

**Practice 2 verified statistics** (computed from the CSVs, 2026-07-28;
seeds bats 45, turtles 1, crickets 2):

- `turtle_growth` — one-way ANOVA **F₂,₅₇ = 49.84, p = 3.05e−13**; Tukey
  **pond–marsh NS (p = 0.467)** by design, river differs from both at p
  \< 0.0001.
- `cricket_metabolism` — pooled
  [`lm()`](https://rdrr.io/r/stats/lm.html) slope **0.3833**, R²
  **0.5353**, p = 3.29e−10, **intercept NS (p = 0.311)**. ANCOVA
  covariate-first: mass **F = 207.09**, temp **F = 128.75**. Homogeneity
  of slopes **F = 0.295, p = 0.589**.
- `bat_captures` — 90 rows, 36 torpid, 18 big brown with
  `forearm_mm > 45`, **24 at roost R4 which is absent from
  `roost_sites.csv`** (so `left_join()` yields 90 rows with 24 `NA`s;
  `inner_join()` would give 66, which is the designed wrong answer).

------------------------------------------------------------------------

## Teaching datasets — ship in `inst/extdata/`

Used by tutorials and labs. Not exam material, but listed here so a new
exam dataset does not collide with one.

| Filename | Used by | Columns |
|----|----|----|
| `soil_data.csv` | M1, M2, M3 | `site_id, land_use, soil_temp_c, water_content_pct, organic_matter_pct, microbial_biomass_mg_kg, respiration_rate_mg_co2_kg_hr, cfu_total_per_g, cfu_tet_per_g` |
| `mammals_data.csv` | M4 | `species, group, body_mass_kg, heart_rate_bpm, lifespan_years, log_mass` |
| `algae_beads.csv` | M5, M7 | `vial_id, species, nutrient_level, co2_drawdown_ppm` |
| `algae_light.csv` | M6 | `vial_id, light_umol, co2_drawdown_ppm` |
| `cardio.csv` | M8, M9 | `subject_id, sex, activity_level, body_mass_kg, resting_hr_bpm` |
| `daphnia_hr.csv` | Lab 10 | `daphnia_id, species, body_length_mm, eye_diameter_mm, heart_rate_bpm` |
| `beetles.csv` | post-Exam-1 lab | `beetle_id, sex, diet, body_length_mm, mass_mg` |

> ⚠️ `soil_data.csv` carries **four silently-graded regeneration
> constraints** (exactly 15 rows; `land_use` character; `soil_temp_c`
> keeps decimals; four column names must not be renamed). See seed §6
> before touching it.

------------------------------------------------------------------------

## Collision check — 2026-07-28

**Filenames:** no duplicates anywhere across the three tables above. ✅

**Organisms:** Practice 2 uses bats, turtles, and crickets. Real Exam 2
uses birds, fish, and stream invertebrates. Disjoint. ✅ Practice 1
(moths, frogs) versus Real Exam 1 (bees, salamanders, lizards) —
disjoint, though **moths/bees are both pollinators and
`moth_visits`/`bee_visits` are near-twin filenames**. Not a collision,
but the closest pair in the set; worth not repeating.

**Column sets:** no full match between any practice and any real dataset
— **but this can only be confirmed once the remaining gaps are filled.**
⚠️ Practice Exam 1’s three column sets were recorded 2026-07-28 from the
exam document; **the six real-exam rows are still outstanding.**

**Overlaps that are fine and intentional:** `species` appears in
`bat_captures`, `algae_beads`, `daphnia_hr`, and `mammals_data`.
`mass_g` appears in `bat_captures` and `turtle_growth`. `sex` appears in
`cardio` and `beetles`. Students meeting the same variable name across
contexts is a feature.

------------------------------------------------------------------------

## Checklist for adding any new exam dataset

Filename does not appear anywhere in this file

Organism not used by any dataset in the same exam, real or practice

Column set not identical to any real exam dataset

Every quoted statistic computed from the written CSV, not from the
generator

Row added to the correct table above, in the same edit

If practice: goes in `inst/practice-exams/<exam>/`. If real: goes in
`exams/`, never `inst/`
