# ============================================================
# BIOL 204 — In-Lab Exercise: Comparing Groups
# Companion to Module 5 (Comparing Groups: t-tests and ANOVA)
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
# A t-test compares the means of exactly TWO groups. Let's compare the
# lifespan of Rodents and Ungulates (hoofed mammals).
#
# First we need a data frame with just those two groups. Worked example:
two_groups <- mammals[mammals$group %in% c("Rodent", "Ungulate"), ]

# Sanity check — you should see only two groups now:
table(two_groups$group)

# >>> Your turn: run a t-test of lifespan_years BY group on two_groups.
#     Use the formula interface:  response ~ group , with data = two_groups.
t.test(______________ ~ ______________, data = two_groups)

# Q1. Read the output. What is the p-value? ______________
#     Are the two groups' mean lifespans significantly different (p < 0.05)? ______
#     Which group lives longer, and by roughly how many years? ______________


# Part 2 — Three or more groups: one-way ANOVA ----
# ------------------------------------------------------------
# With FOUR groups a t-test won't do — we use a one-way ANOVA. The course
# convention is aov() to fit the model, then summary() to read the table.
#
# >>> Your turn: fit an ANOVA of lifespan_years by group across ALL of mammals,
#     save it as 'life_model', then print its summary().
life_model <- aov(______________ ~ ______________, data = mammals)
summary(______________)

# Q2. Find the 'group' row in the table. What is the p-value (the Pr(>F) column)?
#     ______________
#     Does lifespan differ among the four groups overall (p < 0.05)? ______
#
# Q3. The ANOVA tells you that AT LEAST ONE group differs — but not which ones.
#     What would you need to run next to find out? ______________________________


# Part 3 — Which groups differ? Tukey HSD ----
# ------------------------------------------------------------
# TukeyHSD() takes the aov object and compares every pair of groups, adjusting
# for the fact that we're making many comparisons at once.
#
# >>> Your turn: run TukeyHSD() on life_model.
TukeyHSD(______________)

# Read the 'p adj' column — that is the adjusted p-value for each pair.
#
# Q4. Which pair of groups is MOST clearly different (smallest p adj)? ______________
#
# Q5. Find at least one pair whose p adj is GREATER than 0.05. Write it down.
#     ______________________________________________________________________
#     In plain words: those two groups' lifespans are NOT significantly
#     different from each other, even though the overall ANOVA was significant.
#     Why is that possible? (Talk it through with your partner.)
#     ______________________________________________________________________


# Part 4 — Show the comparison ----
# ------------------------------------------------------------
# A boxplot is the natural picture for "does the response differ by group?"
# Worked example — fill in nothing, just run it and read it:
ggplot(mammals, aes(x = group, y = lifespan_years)) +
  geom_boxplot() +
  labs(x = "Mammal group", y = "Lifespan (years)") +
  theme_classic()

# Q6. Does the picture match your statistics? Point to the group your Tukey
#     result flagged as different and say whether the boxplot agrees.
#     ______________________________________________________________________


# Wrap-up discussion ----
# ------------------------------------------------------------
# Q7. You used three tools today: a t-test, a one-way ANOVA, and Tukey HSD.
#     In one sentence each, when would you reach for each one?
#     t-test:  ______________________________________________________________
#     ANOVA:   ______________________________________________________________
#     Tukey:   ______________________________________________________________


# ============================================================
# Nice work. Save your script (File > Save) and be ready to share
# your Tukey result and your boxplot with the class.
# ============================================================
