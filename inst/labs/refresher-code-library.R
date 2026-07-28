# ============================================================
# BIOL 204 — Post-Exam Refresher & Code Library Lock-In
# Homework: complete individually before Lab 9 (cardiovascular unit)
#
# Name: ______________________
#
# WHY THIS HOMEWORK
#   You just finished R Exam 1 and had a break — the syntax gets rusty
#   fast. This homework warms every skill back up on a NEW dataset
#   (beetles you've never seen) so you know it transfers, not just
#   memorized. As you go, you'll copy each confirmed template into
#   YOUR code library so it's ready for the cardiovascular unit.
#
# HOW TO USE THIS SCRIPT
#   - Work top to bottom. Run a line with Ctrl+Enter (Win) / Cmd+Enter (Mac).
#   - Each section has a WORKED example (already written — run it),
#     then a  # >>>  YOUR TURN prompt for you to fill in, then a
#     question to answer in a comment.
#   - Watch for  # -> LIBRARY :  that's your cue to paste the working
#     template into your personal library script (code-library-starter.R).
#   - Use the Document Outline (Ctrl+Shift+O / Cmd+Shift+O) to jump around.
# ============================================================


# _____________________________________
# Setup ----
# _____________________________________

# Start from a clean slate so nothing left over from Exam 1 interferes:
rm(list = ls())

library(dplyr)
library(ggplot2)
library(ggpubr)     # for the regression-line annotations

# The beetles data ships with the course package. Load it:
beetles <- read.csv(
  system.file("extdata", "beetles.csv", package = "BisonExplorR")
)

# ALWAYS look before you leap. Run each of these:
str(beetles)              # variable names + types
names(beetles)            # column names
head(beetles)             # first 6 rows
dim(beetles)              # rows x columns

# The two grouping columns are `diet` (control/low/high) and `sex`.
# Check their labels for typos before you trust any grouped result:
unique(beetles$diet)
# >>> YOUR TURN: print the unique values of sex.
# unique(beetles$______)

# Q1. How many beetles are in the dataset, and how many diet groups
#     are there? (Answer from str() / unique() output.)
#     ANSWER:


# _____________________________________
# Summarizing: group_by + summarise + SE ----
# _____________________________________

# WORKED: mean and standard error of mass, for each diet group.
# Remember SE = sd / sqrt(n), and we use length() for n (not n()).
beetles %>%
  group_by(diet) %>%
  summarise(
    mean_mass = mean(mass_mg),
    sd_mass   = sd(mass_mg),
    se_mass   = sd(mass_mg) / sqrt(length(mass_mg)),
    n         = length(mass_mg)
  )

# >>> YOUR TURN: build the same summary table, but grouped by sex.
# beetles %>%
#   group_by(______) %>%
#   summarise(
#     mean_mass = mean(mass_mg),
#     se_mass   = sd(mass_mg) / sqrt(length(mass_mg)),
#     n         = length(mass_mg)
#   )

# Q2. Which diet group has the highest mean mass? Does that group also
#     have the largest sample size, or are the groups balanced?
#     ANSWER:

# -> LIBRARY: paste the group_by + summarise template into the
#    "SUMMARIZING DATA" section of your library.


# _____________________________________
# Visualizing ----
# _____________________________________

## Boxplot ----

# WORKED: distribution of mass across the three diets.
ggplot(beetles, aes(x = diet, y = mass_mg)) +
  geom_boxplot() +
  labs(x = "Diet", y = "Mass (mg)") +
  theme_classic()

# >>> YOUR TURN: make a boxplot of body_length_mm by sex.
# ggplot(beetles, aes(x = ______, y = ______)) +
#   geom_boxplot() +
#   labs(x = "Sex", y = "Body length (mm)") +
#   theme_classic()


## Barplot (mean + SE) ----

# WORKED: this is a TWO-STEP plot — summarize first, then plot.
mass_summary <- beetles %>%
  group_by(diet) %>%
  summarise(
    mean_mass = mean(mass_mg),
    se_mass   = sd(mass_mg) / sqrt(length(mass_mg))
  )

ggplot(mass_summary, aes(x = diet, y = mean_mass)) +
  geom_col(fill = "grey70", color = "black") +
  geom_errorbar(aes(ymin = mean_mass - se_mass, ymax = mean_mass + se_mass),
                width = 0.2) +
  labs(x = "Diet", y = "Mean mass (mg)") +
  theme_classic()

# Q3. A boxplot and a mean+SE barplot show the same data differently.
#     What does the boxplot show that the barplot hides?
#     ANSWER:


## Scatterplot ----

# WORKED: does a bigger beetle weigh more? mass vs body length.
ggplot(beetles, aes(x = body_length_mm, y = mass_mg)) +
  geom_point() +
  labs(x = "Body length (mm)", y = "Mass (mg)") +
  theme_classic()

# >>> YOUR TURN: copy the scatter above and add  + facet_wrap(~ diet)
#     to get one panel per diet. What line would you add?
#     ANSWER:

# -> LIBRARY: confirm your boxplot, barplot, and scatterplot templates
#    all run, then paste them into the "ggplot TEMPLATES" section.


## Scatterplot + regression line ----

# WORKED: add the fitted line, its equation, and R^2 (ggpubr).
ggplot(beetles, aes(x = body_length_mm, y = mass_mg)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE, color = "black") +
  stat_regline_equation(label.y = 85) +   # y-position of the equation label
  stat_cor(aes(label = ..rr.label..), label.y = 79) +  # R^2 label
  labs(x = "Body length (mm)", y = "Mass (mg)") +
  theme_classic()

# Q4. Read the R^2 off your figure. Roughly what fraction of the
#     variation in mass is explained by body length?
#     ANSWER:

# -> LIBRARY: this fills the "Scatterplot + regression" slot that was
#    marked ADD LATER in your starter library. Paste it in now.


# _____________________________________
# Statistics ----
# _____________________________________

## T-test (two groups) ----

# WORKED: do male and female beetles differ in mass?
t.test(mass_mg ~ sex, data = beetles)

# Q5. Report the p-value. At alpha = 0.05, do the sexes differ in mass?
#     Write the one-sentence biological conclusion you'd put in a report.
#     ANSWER:

# -> LIBRARY: paste  t.test(response_var ~ group_var, data = df)  into
#    the "T-test" slot (you used this on Exam 1 — lock it in for keeps).


## One-way ANOVA + Tukey (three+ groups) ----

# WORKED: does mass differ AMONG the three diets? Two steps:
diet_anova <- aov(mass_mg ~ diet, data = beetles)
summary(diet_anova)          # the ANOVA table: look at the p-value (Pr(>F))

# A significant ANOVA says "at least one group differs" but not WHICH.
# Tukey's HSD does every pairwise comparison and adjusts for multiple tests:
TukeyHSD(diet_anova)

# Q6. From the ANOVA table, is there a significant effect of diet on mass?
#     Then from the Tukey output, which pair of diets does NOT differ
#     significantly (look at the `p adj` column)? Why does this pair make
#     the ANOVA-then-Tukey workflow worth the extra step?
#     ANSWER:

# -> LIBRARY: paste the aov() + summary() + TukeyHSD() block into the
#    "One-way ANOVA" slot.


# _____________________________________
# Wrap-up: what's still stubbed ----
# _____________________________________

# Your library should now have working templates for everything Exam 1
# covered: checking data, summarising + SE, three ggplots, the regression
# line, the t-test, and one-way ANOVA + Tukey.
#
# Leave these sections as "ADD LATER" stubs — you'll fill them during the
# cardiovascular unit, before R Exam 2:
#     - Two-way ANOVA
#     - ANCOVA (numeric covariate + a grouping factor)
#     - Multi-panel figures with plot_grid()
#     - Full lm() readout (slope / intercept / R^2 / p)
#
# Q7. Restart R (Session > Restart R), then run your LIBRARY script from
#     the top on this beetles dataset. Did every template execute with no
#     errors? If not, which one broke, and what did you fix?
#     ANSWER:

# ============================================================
# Submit: your completed library script running cleanly top-to-bottom,
# plus answers to Q1-Q7. See you in the cardiovascular unit.
# ============================================================
