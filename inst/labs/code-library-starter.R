# ============================================================
# BIOL 204 — MY R CODE LIBRARY
# Your open-note reference script for the R exams.
#
# Name: ______________________
#
# HOW TO USE THIS FILE
#   - This is YOUR reference. Add to it as you learn new functions.
#   - The templates below use generic names: df (your data frame),
#     group_var (a category column), response_var / predictor_var
#     (numeric columns). Replace them with YOUR real column names.
#   - Open the Document Outline with Ctrl+Shift+O (Win) / Cmd+Shift+O (Mac)
#     to jump between sections instead of scrolling.
#   - Sections marked "ADD LATER" are for after the Statistics module,
#     before R Exam 2. Keep the headers so your outline is ready.
#   - Before an exam: load a practice dataset as df and run each template
#     to confirm it executes cleanly.
# ============================================================


# _____________________________________
# LOADING PACKAGES ----
# _____________________________________

library(dplyr)
library(ggplot2)
# library(ggpubr)    # uncomment when you add the regression / stats sections
# library(cowplot)   # uncomment when you add multi-panel figures


# _____________________________________
# CLEARING THE ENVIRONMENT ----
# _____________________________________

rm(list = ls())   # removes all objects so you start from a clean slate
# For a full reset (also reloads packages): Session > Restart R


# _____________________________________
# CHECKING DATA ----
# _____________________________________

## Structure and names ----

str(df)              # variable names, types, and a preview of values
names(df)            # column names only
unique(df$group_var) # every unique value in a column — catches label typos
dim(df)              # rows x columns
nrow(df)             # number of rows (confirm your sample size)

## Quick summaries ----

head(df)             # first 6 rows
summary(df)          # min, max, mean, and NA count per column


# _____________________________________
# SUMMARIZING DATA ----
# _____________________________________

## group_by + summarise ----

# Mean and standard error of a response, for each group.
# SE = sd / sqrt(n). Use length() for n, not n().
df %>%
  group_by(group_var) %>%
  summarise(
    mean_y = mean(response_var),
    sd_y   = sd(response_var),
    se_y   = sd(response_var) / sqrt(length(response_var)),
    n      = length(response_var)
  )


# _____________________________________
# ggplot TEMPLATES ----
# _____________________________________

## Barplot (mean + SE) ----

# Step 1: build a summary table of means and SEs.
plot_summary <- df %>%
  group_by(group_var) %>%
  summarise(
    mean_y = mean(response_var),
    se_y   = sd(response_var) / sqrt(length(response_var))
  )

# Step 2: bars for the means, error bars for the SE.
ggplot(plot_summary, aes(x = group_var, y = mean_y)) +
  geom_col(fill = "grey70", color = "black") +
  geom_errorbar(aes(ymin = mean_y - se_y, ymax = mean_y + se_y),
                width = 0.2) +
  labs(x = "Group", y = "Mean response") +
  theme_classic()

## Boxplot ----

ggplot(df, aes(x = group_var, y = response_var)) +
  geom_boxplot() +
  labs(x = "Group", y = "Response") +
  theme_classic()

## Scatterplot ----

ggplot(df, aes(x = predictor_var, y = response_var)) +
  geom_point() +
  labs(x = "Predictor", y = "Response") +
  theme_classic()
# To split into one panel per group, add:  + facet_wrap(~ group_var)

## Scatterplot + regression ----
# ADD LATER (after the regression content in the Statistics module).
# Breadcrumb: geom_smooth(method = "lm"), plus stat_cor() and
# stat_regline_equation() from ggpubr for the annotations.

## Multi-panel (plot_grid) ----
# ADD LATER (after the Statistics module).
# Breadcrumb: save separate plots as p1, p2, ... then combine with
# plot_grid(p1, p2, labels = c("A", "B")) from cowplot.


# _____________________________________
# STATISTICS ----
# _____________________________________
# ADD LATER — you'll build this section after the Statistics module,
# before R Exam 2. Keep the sub-headers so your outline is ready.

## T-test ----
# Breadcrumb: t.test(response_var ~ group_var, data = df)

## One-way ANOVA ----
# Breadcrumb: aov() then summary()

## Two-way ANOVA ----
# Breadcrumb: aov() with two grouping variables, then summary()

## ANCOVA ----
# Breadcrumb: aov() with a numeric covariate, then summary()


# ============================================================
# End of library. Add new templates under the right header as you
# learn them, and re-run from the top before an exam to confirm it
# all executes cleanly.
# ============================================================
