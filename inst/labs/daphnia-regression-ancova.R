# ============================================================
# BIOL 204 — In-Lab Exercise: From Regression to ANCOVA
# Companion to Module 7 (Continuous Predictors: Regression -> ANCOVA)
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
#
# THE QUESTION FOR TODAY
#   In small animals the heart beats faster. We have two Daphnia species of
#   different sizes. Today we ask two things:
#     (1) does HEART RATE track body SIZE?  (regression)
#     (2) is that size--heart-rate relationship the SAME in both species,
#         or do the species differ once size is accounted for?  (ANCOVA)
# ============================================================


# Setup ----
# ------------------------------------------------------------
library(ggplot2)
library(ggpubr)     # regression-line equation + R^2 annotations
library(cowplot)    # plot_grid() for the multi-panel figure

# The daphnia data ships with the course package. Load it:
daphnia <- read.csv(
  system.file("extdata", "daphnia_hr.csv", package = "BisonExplorR")
)

# Always look before you leap:
head(daphnia)
str(daphnia)

# Q0. Which column is our RESPONSE (the thing we're explaining)? ______________
#     We have TWO size measurements. Name them: ______________  ______________
#     How many species are there, and what are they called? ______________


# Part 1 — One line: simple regression ----
# ------------------------------------------------------------
# Start simple: ignore species for a moment and fit ONE line to all animals.
# geom_smooth(method = "lm") draws the fitted line; the two ggpubr layers
# print the equation and the R^2 so you can read the relationship off the plot.
# Worked example — run it and read it:
ggplot(daphnia, aes(x = body_length_mm, y = heart_rate_bpm)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE, color = "black") +
  stat_regline_equation(label.x = 2.9, label.y = 380) +
  stat_cor(aes(label = ..rr.label..), label.x = 2.9, label.y = 372) +
  labs(x = "Body length (mm)", y = "Heart rate (bpm)") +
  theme_classic()

# Q1. Is the slope positive or negative? In plain words, what does that say
#     about big vs. small Daphnia? ______________________________________
#
# Q2. Read the R^2 off the plot. Does body length explain a lot, or a little,
#     of the variation in heart rate? ______________


# Part 2 — Wait... there are two species ----
# ------------------------------------------------------------
# That single line pooled two different species together. Let's color by
# species and fit a SEPARATE line to each. We'll save the figure as an object
# named p_length so we can reuse it in the final multi-panel figure later.
#
# >>> Your turn: fill in the color mapping (color = species) and the method.
p_length <- ggplot(daphnia,
                   aes(x = body_length_mm, y = heart_rate_bpm, color = ______)) +
  geom_point() +
  geom_smooth(method = "______", se = FALSE) +
  labs(x = "Body length (mm)", y = "Heart rate (bpm)", color = "Species") +
  theme_classic()

p_length   # print it

# Q3. Look at the two lines. Are their SLOPES roughly the same (parallel),
#     or clearly different? ______________
#
# Q4. Are the two lines at the same HEIGHT, or is one species shifted up?
#     At the same body length, which species has the faster heart rate?
#     ______________________________________________________________________


# Part 3 — Put numbers on it: ANCOVA ----
# ------------------------------------------------------------
# ANCOVA asks: after accounting for body size (the covariate), does species
# still matter? Course convention: covariate FIRST, then the factor; fit with
# aov() and read it with summary().
#
# >>> Your turn: fit the model, save it as 'ancova_len', then summary() it.
ancova_len <- aov(heart_rate_bpm ~ ______________ + ______________, data = daphnia)
summary(______________)

# Q5. In the summary table, look at the body_length_mm row: is the covariate
#     significant (Pr(>F) < 0.05)? ______
#     Now the species row: after adjusting for size, do the species still
#     differ significantly? ______
#     Put those two answers into one biological sentence:
#     ______________________________________________________________________


# Part 4 — Are the slopes really parallel? The interaction ----
# ------------------------------------------------------------
# ANCOVA assumes the two species share a slope (parallel lines). We can TEST
# that by adding an interaction: size * species. The size:species row is the
# slope-difference test.
#
# >>> Your turn: change the + to a * to fit the interaction model.
slope_test <- aov(heart_rate_bpm ~ body_length_mm ______ species, data = daphnia)
summary(slope_test)

# Q6. Find the body_length_mm:species row. Is the interaction significant
#     (Pr(>F) < 0.05)? ______
#     If it is NOT significant, the slopes are effectively parallel and the
#     ANCOVA in Part 3 is valid. State what that means for the two species'
#     size--heart-rate relationship in plain words:
#     ______________________________________________________________________


# Part 5 — A second size measure + the multi-panel figure ----
# ------------------------------------------------------------
# Good science checks more than one measurement. Repeat the picture and the
# ANCOVA using eye_diameter_mm instead of body_length_mm.
#
# >>> Your turn (a): build the eye-diameter figure, saved as p_eye.
p_eye <- ggplot(daphnia,
               aes(x = ______________, y = heart_rate_bpm, color = species)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  labs(x = "Eye diameter (mm)", y = "Heart rate (bpm)", color = "Species") +
  theme_classic()

# >>> Your turn (b): run the ANCOVA for eye diameter (covariate first).
ancova_eye <- aov(heart_rate_bpm ~ ______________ + species, data = daphnia)
summary(ancova_eye)

# Q7. Does the eye-diameter analysis tell the SAME story as body length
#     (covariate significant, species significant)? ______

# >>> Your turn (c): combine your two figures into one labeled two-panel
#     figure, then export it. Fill in your two plot objects.
final_figure <- plot_grid(______________, ______________,
                          labels = c("A", "B"),
                          ncol = 2, align = "hv")
final_figure

ggsave("daphnia_size_hr_figure.png", final_figure,
       width = 22, height = 10, units = "cm")


# Wrap-up discussion ----
# ------------------------------------------------------------
# Q8. In one sentence each, when would you reach for each tool?
#     Regression: ___________________________________________________________
#     ANCOVA:     ___________________________________________________________
#
# Q9. A classmate says "the species have different heart rates, so size doesn't
#     matter." Using your ANCOVA result, explain why that's the wrong reading.
#     ______________________________________________________________________


# ============================================================
# Nice work. Save your script (File > Save) and upload your two-panel
# figure to your Lab folder. Be ready to share your ANCOVA interpretation
# with the class.
# ============================================================
