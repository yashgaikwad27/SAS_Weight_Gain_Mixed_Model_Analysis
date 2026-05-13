# SAS Weight Gain Mixed-Effects Model Analysis

## Overview
Mixed-effects model analysis of weight gain data from 69 observations across 9 treatment 
groups and 8 litters in SAS. Litter was modeled as a random effect to account for 
within-litter correlation, with results compared against a traditional ANOVA approach 
to justify the mixed model choice.

## What I Did
- Performed systematic data cleaning, identifying and resolving 4 missing values, 
  2 duplicate records, 2 implausible weight gain values, 1 invalid treatment group, 
  and 1 invalid litter ID
- Generated descriptive statistics stratified by treatment group
- Fit a linear mixed-effects model using PROC MIXED with REML estimation and 
  Kenward-Roger degrees of freedom correction
- Extracted covariance parameter estimates to quantify the random effect of litter
- Conducted Tukey-Kramer post-hoc pairwise comparisons across all 9 treatment groups
- Verified model assumptions using Shapiro-Wilk normality testing on residuals, 
  a Q-Q plot, and Levene's test for homogeneity of variance
- Compared mixed model results against a traditional ANOVA with litter as a fixed 
  effect to demonstrate the advantage of the mixed model approach

## Tools & Methods
SAS, PROC MIXED, PROC GLM, PROC UNIVARIATE, REML Estimation, Kenward-Roger DF, 
Tukey-Kramer Post-Hoc, Shapiro-Wilk, Levene's Test, ODS PDF Output

## Files
- `Weight_Gain_Mixed_Model_Analysis.sas` - Full analysis code
- `Weight_Gain_Mixed_Model_Analysis.pdf` - ODS output with tables and diagnostic plots
