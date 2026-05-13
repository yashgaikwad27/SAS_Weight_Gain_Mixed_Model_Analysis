/*============================================================
  WEIGHT GAIN ANALYSIS - CLEAN RESULTS REPORT
  Author: Yash Gaikwad
==============================================================*/

/* SAVING IN A PDF FORMAT */
ODS PDF FILE="/home/u64466214/EPG1V2/output/weightgain_report.pdf"
        STYLE=JOURNAL
        STARTPAGE=YES;

ODS NOPROCTITLE;

/* STEP 1: IMPORTING THE RAW DATA */
PROC IMPORT DATAFILE="/home/u64466214/EPG1V2/data/weightgain.csv"
    OUT=weightdata_raw
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
RUN;


/* STEP 2: DATA VALIDATION AND CLEANING */
/* CHECKING FOR MISSING VALUES */
PROC MEANS DATA=weightdata_raw NMISS N;
    VAR litter trt wgtgain;
    TITLE "Missing Value Check - Raw Data";
RUN;

/* CHECKING FOR ANY IMPLAUSIBLE VALUES
   (expected plausible range: 10 to 40 grams) */
PROC MEANS DATA=weightdata_raw MIN MAX MEAN STD N;
    VAR wgtgain;
    TITLE "Range Check - Weight Gain Variable (Raw)";
RUN;

/* CHECKING THAT TREATMENT GROUPS AND LITTER IDS ARE VALID
   (expected: trt = 1-9, litter = 1-8) */
PROC FREQ DATA=weightdata_raw;
    TABLES trt litter / NOCUM;
    TITLE "Frequency Check - Treatment Groups and Litter IDs (Raw)";
RUN;

/* CHECKING FOR DUPLICATE RECORDS */
PROC SORT DATA=weightdata_raw OUT=sorted_raw;
    BY litter trt;
RUN;

PROC SORT DATA=sorted_raw OUT=sorted_nodups NODUPKEY DUPOUT=duplicates;
    BY litter trt;
RUN;

PROC PRINT DATA=duplicates;
    TITLE "Duplicate Records Found";
RUN;

/*------------------------------------------------------------
  DATA QUALITY ISSUES FOUND IN RAW DATA:
  - 4 missing values found in wgtgain
  - 2 duplicate records found
  - 2 implausible wgtgain values found (99.50 and -3.20)
  - 1 invalid treatment group found (trt = 10, expected 1-9)
  - 1 invalid litter ID found (litter = 9, expected 1-8)
  The following cleaning steps address each of these issues.
------------------------------------------------------------*/

/* REMOVING THE DUPLICATE RECORDS */
PROC SORT DATA=weightdata_raw OUT=weightdata_nodups NODUPKEY;
    BY litter trt;
RUN;

/* REMOVING RECORDS WITH INVALID TREATMENT OR LITTER VALUES */
DATA weightdata_valid;
    SET weightdata_nodups;
    IF trt < 1 OR trt > 9 THEN DELETE;
    IF litter < 1 OR litter > 8 THEN DELETE;
RUN;

/* SETTING IMPLAUSIBLE VALUES TO MISSING
   (plausible range defined as 10 to 40 grams) */
DATA weightdata_clean;
    SET weightdata_valid;
    IF wgtgain < 10 OR wgtgain > 40 THEN wgtgain = .;
RUN;

/* REMOVING RECORDS WITH MISSING WGTGAIN AFTER ALL CLEANING STEPS */
DATA weightdata;
    SET weightdata_clean;
    WHERE wgtgain IS NOT MISSING;
RUN;

/* VERIFYING THE CLEANED DATASET */
PROC MEANS DATA=weightdata NMISS N MIN MAX MEAN STD;
    VAR litter trt wgtgain;
    TITLE "Verification - Cleaned Dataset";
RUN;

PROC FREQ DATA=weightdata;
    TABLES trt litter / NOCUM;
    TITLE "Frequency Check - Treatment Groups and Litter IDs (Cleaned)";
RUN;


/* STEP 3: LOOKING AT THE DESCRIPTIVE STATISTICS */
ODS OUTPUT Summary=desc_stats;
PROC MEANS DATA=weightdata MEAN STD MIN MAX N;
    CLASS trt;
    VAR wgtgain;
RUN;
ODS OUTPUT CLOSE;

PROC PRINT DATA=desc_stats NOOBS LABEL;
    VAR trt wgtgain_N wgtgain_Mean wgtgain_StdDev wgtgain_Min wgtgain_Max;
    LABEL trt            = "Treatment"
          wgtgain_N      = "N"
          wgtgain_Mean   = "Mean"
          wgtgain_StdDev = "Std Dev"
          wgtgain_Min    = "Minimum"
          wgtgain_Max    = "Maximum";
    FORMAT wgtgain_Mean wgtgain_StdDev wgtgain_Min wgtgain_Max 8.3;
    TITLE "Table 1. Descriptive Statistics of Weight Gain by Treatment Group";
RUN;

/* STEP 4: RUNNING OUR PRIMARY MIXED-EFFECTS MODEL*/
ODS OUTPUT CovParms  = cov_params
           SolutionF = fixed_effects
           Tests3    = type3_tests;

PROC MIXED DATA=weightdata METHOD=REML;
    CLASS trt litter;
    MODEL wgtgain = trt / SOLUTION DDFM=KR;
    RANDOM INTERCEPT / SUBJECT=litter;
    LSMEANS trt / DIFF ADJUST=TUKEY;
RUN;
ODS OUTPUT CLOSE;

/* Table 2: RANDOM EFFECTS */
PROC PRINT DATA=cov_params NOOBS LABEL;
    VAR CovParm Subject Estimate;
    LABEL CovParm  = "Covariance Parameter"
          Subject  = "Subject"
          Estimate = "Estimate";
    FORMAT Estimate 8.4;
    TITLE "Table 2. Covariance Parameter Estimates (Random Effect of Litter)";
RUN;

/* Table 3: FIXED EFFECTS */
PROC PRINT DATA=fixed_effects NOOBS LABEL;
    VAR Effect trt Estimate StdErr DF tValue Probt;
    LABEL Effect   = "Effect"
          trt      = "Treatment"
          Estimate = "Estimate"
          StdErr   = "Std Error"
          DF       = "DF"
          tValue   = "t Value"
          Probt    = "p Value";
    FORMAT Estimate StdErr 8.4 Probt 8.4;
    TITLE "Table 3. Fixed Effects Estimates - PROC MIXED (REML)";
RUN;

/* Table 4: OVERALL TREATMENT EFFECTS */
PROC PRINT DATA=type3_tests NOOBS LABEL;
    VAR Effect NumDF DenDF FValue ProbF;
    LABEL Effect  = "Effect"
          NumDF   = "Num DF"
          DenDF   = "Den DF"
          FValue  = "F Value"
          ProbF   = "p Value";
    FORMAT FValue 8.3 ProbF 8.4;
    TITLE "Table 4. Type 3 Test of Fixed Effects - Overall Treatment Effect";
RUN;


/* STEP 5: GETTING THE RESIDUALS VIA PROC GLM */
PROC GLM DATA=weightdata;
    CLASS trt litter;
    MODEL wgtgain = trt litter;
    OUTPUT OUT=resid_data RESIDUAL=resid PREDICTED=pred;
RUN;
QUIT;

/* TABLE 5: NORMALITY CHECK OF OUR MODEL*/
ODS OUTPUT TestsForNormality=normality_test;

/* STEP 6: CHECKING THE NORMALITY ASSUMPTION*/
PROC UNIVARIATE DATA=resid_data NORMAL;
    VAR resid;
    QQPLOT resid / NORMAL(MU=EST SIGMA=EST COLOR=RED);
RUN;
ODS OUTPUT CLOSE;

PROC PRINT DATA=normality_test NOOBS LABEL;
    VAR Test Stat pValue;
    LABEL Test   = "Test"
          Stat   = "Statistic"
          pValue = "p Value";
    FORMAT pValue 8.4;
    TITLE "Table 5. Tests for Normality of Residuals (Shapiro-Wilk)";
RUN;

/* TABLE 6: LEVENES TEST OF OUR MODEL*/
ODS OUTPUT HOVFTest=levene_test;

/* STEP 7: CHECKING THE HOMOGENEITY OF VARIANCES ASSUMPTION THROUGH LEVENE'S TEST */
PROC GLM DATA=weightdata;
    CLASS trt;
    MODEL wgtgain = trt;
    MEANS trt / HOVTEST=LEVENE;
RUN;
QUIT;
ODS OUTPUT CLOSE;

PROC PRINT DATA=levene_test NOOBS LABEL;
    VAR Source DF SS MS FValue ProbF;
    LABEL Source = "Source"
          DF     = "DF"
          SS     = "Sum of Squares"
          MS     = "Mean Square"
          FValue = "F Value"
          ProbF  = "p Value";
    FORMAT FValue 8.3 ProbF 8.4;
    TITLE "Table 6. Levene's Test for Homogeneity of Variance";
RUN;

/* TABLE 7: COMPARISON WITH ANOVA*/
ODS OUTPUT ModelANOVA=anova_model;

/* STEP 8: RUNNING A STANDARD ANOVA FOR COMPARISON (litter as fixed) */
PROC GLM DATA=weightdata;
    CLASS trt litter;
    MODEL wgtgain = trt litter;
RUN;
QUIT;
ODS OUTPUT CLOSE;

PROC PRINT DATA=anova_model NOOBS LABEL;
    VAR Source DF SS MS FValue ProbF;
    LABEL Source = "Source"
          DF     = "DF"
          SS     = "Sum of Squares"
          MS     = "Mean Square"
          FValue = "F Value"
          ProbF  = "p Value";
    FORMAT FValue 8.3 ProbF 8.4;
    TITLE "Table 7. Comparison: Traditional ANOVA (Litter as Fixed Effect)";
RUN;


/* CLOSING PDF */
ODS PDF CLOSE;
TITLE;
ODS PROCTITLE;