# ============================================================
# BIOL 204 — In-Lab Exercise: Wrangling & Visualizing Data
# Companion to the Data Wrangling & Visualization module
#
# Partner names: ______________________   ______________________
# Date: ______________________
#
# HOW TO USE THIS SCRIPT
#   - Work through it WITH YOUR PARTNER, top to bottom.
#   - Run a line with Ctrl+Enter (Windows) or Cmd+Enter (Mac).
#   - Wherever you see  # >>>  , that's yours to fill in.
#   - Answer the questions written in comments as you go.
#   - Use the Document Outline (top-right of this pane) to jump between sections.
# ============================================================


# Setup ----
# ------------------------------------------------------------
library(dplyr)
library(ggplot2)

# The mammals data ships with the course package. Load it:
mammals <- read.csv(
  system.file("extdata", "mammals_data.csv", package = "BisonExplorR")
)

# Always look before you leap:
head(mammals)
str(mammals)

# Q0. How many species are in this dataset, and what are the four groups?
#     species: ______        groups: ______________________________________


# Part 1 — Filtering rows ----
# ------------------------------------------------------------
# Worked example: keep only the rodents.
rodents <- mammals %>%
  filter(group == "Rodent")

rodents

# >>> Your turn: build a data frame called 'big' with only the species
#     whose body_mass_kg is greater than 100.
big <- mammals %>%
  filter(______________)

# Q1. How many species ended up in 'big'? ______
#     (Hint: nrow(big) will tell you.)


# Part 2 — Making a new column with mutate() ----
# ------------------------------------------------------------
# A famous idea in biology: across mammals, the number of times a heart beats
# in a lifetime is surprisingly similar, even though heart RATE and lifespan
# vary enormously. Let's test it.
#
# beats per lifetime = beats/min x minutes/hour x hours/day x days/year x years
#
# >>> Fill in the calculation. lifespan_years is a column in the data.
mammals <- mammals %>%
  mutate(beats_per_lifetime = heart_rate_bpm * 60 * 24 * 365 * ______________)

# Peek at your new column for a few species:
mammals %>%
  select(species, group, heart_rate_bpm, lifespan_years, beats_per_lifetime) %>%
  head(10)

# Q2. Compare the mouse and the elephant. Their heart rates are wildly
#     different. Are their lifetime heartbeat totals as different as you'd
#     expect? ______________________________________________________________


# Part 3 — Group summaries with standard error ----
# ------------------------------------------------------------
# Worked example: mean resting heart rate per group.
mammals %>%
  group_by(group) %>%
  summarise(mean_hr = mean(heart_rate_bpm))

# >>> Your turn: for each group, summarise the MEAN and the STANDARD ERROR of
#     beats_per_lifetime. Remember SE = sd(x) / sqrt(length(x)).
lifetime_summary <- mammals %>%
  group_by(group) %>%
  summarise(
    mean_beats = mean(beats_per_lifetime),
    se_beats   = ______________________________________
  )

lifetime_summary

# Q3. Do the four groups' lifetime heartbeat totals land in the same
#     ballpark, or are they very different? What does that suggest about
#     the "same number of heartbeats per lifetime" idea?
#     ______________________________________________________________________


# Part 4 — A figure ----
# ------------------------------------------------------------
# Worked example: a scatter of body size vs. heart rate (log_mass is provided
# in the data because body mass spans mouse-to-elephant).
ggplot(mammals, aes(x = log_mass, y = heart_rate_bpm)) +
  geom_point() +
  labs(x = "log10 body mass (kg)", y = "Resting heart rate (bpm)") +
  theme_classic()

# >>> Your turn: make a BAR CHART of mean_beats per group from
#     lifetime_summary, with error bars showing the standard error.
#     Fill in the two geoms.
ggplot(lifetime_summary, aes(x = group, y = mean_beats)) +
  ______________ +                                        # bars (geom_col)
  ______________(aes(ymin = mean_beats - se_beats,        # error bars
                     ymax = mean_beats + se_beats),
                 width = 0.2) +
  labs(x = "Group", y = "Mean beats per lifetime") +
  theme_classic()

# Q4. Which group's bar sits highest? Do the error bars overlap the others?
#     ______________________________________________________________________


# Wrap-up discussion ----
# ------------------------------------------------------------
# Q5. Talk it through with your partner and write one or two sentences:
#     If small, fast-hearted mammals and large, slow-hearted mammals end up
#     with roughly similar lifetime heartbeat totals, what might that tell us
#     about how bodies use energy? (There's no single right answer — reason
#     from what you found above.)
#     ______________________________________________________________________
#     ______________________________________________________________________


# ============================================================
# Nice work. Save your script (File > Save) and be ready to share
# your figure and your answer to Q5 with the class.
# ============================================================
