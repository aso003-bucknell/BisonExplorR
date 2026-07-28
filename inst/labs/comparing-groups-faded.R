# ============================================================
# BIOL 204 — In-Lab Exercise: Comparing Groups  (faded-scaffold version)
# Companion to Module 5 (Comparing Groups: t-tests and ANOVA)
#
# Partner names: ______________________   ______________________
# Date: ______________________
#
# HOW TO USE THIS SCRIPT
#   - Work through it WITH YOUR PARTNER, top to bottom.
#   - Run a line with Ctrl+Enter (Windows) or Cmd+Enter (Mac).
#   - Use the Document Outline (top-right of this pane) to jump between sections.
#
# THE THREE KINDS OF CODE BLOCK  (watch the marker on each one)
#   # WORKED      -> already written. Just run it and read it.
#   # >>> FILL    -> the shape is there; fill in the blanks.
#   # >>> WRITE   -> write the whole line yourself, from scratch.
#                    Stuck on a WRITE block? Check with your partner first,
#                    then flag down the instructor. (The AI coach is in the
#                    tutorials, not in lab — here your partner is the net.)
#
# The blocks get less scaffolded as you go — by the end you're writing
# whole lines on your own, which is exactly what the exam asks for.
#
# THE QUESTION FOR TODAY
#   Bigger animals tend to live longer. We'll ask it as a statistics question:
#   does LIFESPAN differ among the four mammal groups, and which groups differ?
# ============================================================


# Setup ----
# ------------------------------------------------------------
library(ggplot2)

# The mammals data ships with the course package. Load it:
mammals <- read.csv(
  system.file("extdata", "mammals_data.csv", package = "BisonExplorR")
)

# Always look before you leap:
head(mammals)
str(mammals)

# Q0. The 'group' column has four levels. Write them down: ______________________
#     Which column is our RESPONSE (the thing we're comparing)? ______________


# Part 1 — Two groups: the t-test ----
# ------------------------------------------------------------
# A t-test compares the means of exactly TWO groups. First time through,
# we'll scaffold it; then you'll do a second one on your own.

# WORKED — subset to just Rodents and Ungulates, then run nothing yet:
two_groups <- mammals[mammals$group %in% c("Rodent", "Ungulate"), ]
table(two_groups$group)     # sanity check: only two groups should appear

# >>> FILL — run a t-test of lifespan_years BY group on two_groups.
#     Use the formula interface:  response ~ group , with data = two_groups.
t.test(______________ ~ ______________, data = two_groups)

# Q1. What is the p-value? ______________
#     Significantly different (p < 0.05)? ______   Which group lives longer? __________


# ---- Now the same skill, no scaffold ----
# You've seen the pattern once. Do it again yourself for a DIFFERENT pair:
# compare the lifespan of CARNIVORES and PRIMATES.
#
# >>> WRITE — two lines. First build a data frame with only those two groups
#     (copy the shape of the two_groups line above, swap the names), then run
#     a t-test of lifespan_years by group on it. Stuck? Re-read the WORKED
#     line just above — the shape is identical, only the names change.


# Q2. Are carnivores and primates significantly different in lifespan? ______


# Part 2 — Three or more groups: one-way ANOVA ----
# ------------------------------------------------------------
# With FOUR groups a t-test won't do — use a one-way ANOVA. Course convention
# is aov() to FIT the model, then summary() to READ the table.

# >>> FILL — fit the model (the function is given; you supply the formula).
life_model <- aov(______________ ~ ______________, data = mammals)

# >>> WRITE — now print the ANOVA table. You just saw how summary() is used
#     on a model; write the one line that reads life_model's table.


# Q3. Find the 'group' row. What is the p-value (the Pr(>F) column)? ______________
#     Does lifespan differ among the four groups overall (p < 0.05)? ______
#
# Q4. The ANOVA says AT LEAST ONE group differs — but not which ones.
#     What would you run next to find out? ______________________________


# Part 3 — Which groups differ? Tukey HSD ----
# ------------------------------------------------------------
# TukeyHSD() takes the aov object and compares every pair of groups, adjusting
# for the fact that we're making many comparisons at once.
#
# >>> WRITE — one line: run Tukey HSD on life_model.
#     (Hint if you're stuck: which object does TukeyHSD() take — the fitted
#     model, or the summary table?)


# Read the 'p adj' column — the adjusted p-value for each pair.
#
# Q5. Which pair is MOST clearly different (smallest p adj)? ______________
#
# Q6. Find one pair whose p adj is GREATER than 0.05: ______________________
#     In plain words, those two groups' lifespans are NOT significantly
#     different, even though the overall ANOVA was. Why is that possible?
#     (Talk it through.) ____________________________________________________


# Part 4 — Show the comparison ----
# ------------------------------------------------------------
# A boxplot is the natural picture for "does the response differ by group?"
# You built plots like this in Module 4. In a coach-less lab this is the block
# most pairs stall on, so the skeleton stays — just fill the blanks.
#
# >>> FILL — boxplot of lifespan_years (y) by group (x) for mammals.
ggplot(mammals, aes(x = ______________, y = ______________)) +
  ______________() +
  labs(x = "Mammal group", y = "Lifespan (years)") +
  theme_classic()


# Q7. Does the picture match your statistics? Point to the group your Tukey
#     result flagged as different and say whether the boxplot agrees.
#     ______________________________________________________________________


# Wrap-up discussion ----
# ------------------------------------------------------------
# Q8. You used three tools today: a t-test, a one-way ANOVA, and Tukey HSD.
#     In one sentence each, when would you reach for each one?
#     t-test:  ______________________________________________________________
#     ANOVA:   ______________________________________________________________
#     Tukey:   ______________________________________________________________


# ============================================================
# Nice work. Save your script (File > Save) and be ready to share
# your Tukey result and your boxplot with the class.
# ============================================================
