/**************************************************************************
Project : NHANES HbA1c and Cardiovascular Disease
File    : 06_forest_plot.sas

Purpose:
Forest Plot of Odds Ratios (95% CI)
from multivariable logistic regression

NHANES 2017–2018
**************************************************************************/

options nodate nonumber;

%let proj=/home/u64297063;

libname nhanes "&proj";

ods graphics off;


/**************************************************************************
Logistic model

FIXED (3 issues):
1. RIDRETH1 removed from class/model - R's model does not adjust
   for race (cvd ~ hba1c + age + sex + bmi + smoking + hypertension).
   Including it here made this forest plot represent a different,
   race-adjusted model than the one in 05_regression.sas and in R.
2. hba1c_group -> LBXGH. This forest plot should visualize the
   CONTINUOUS HbA1c model (matching R's 06_forest_plot.R), not the
   categorical one - that belongs to 08_sensitivity_analysis.sas.
3. RIAGENDR(ref='2') -> RIAGENDR(ref='1'), same fix as in 05.

Expected (matches R): HbA1c OR ~1.16 [1.07-1.25], age OR ~1.06,
sex (Female vs Male) OR ~0.64, BMI OR ~1.02, smoking Former OR ~1.59,
smoking Current OR ~2.25, hypertension OR ~2.10
**************************************************************************/

ods output OddsRatios=OR_Table;

proc logistic data=nhanes.analysis_complete descending;

class

    RIAGENDR (ref='1')
    smoking (ref='Never')
    hypertension (ref='0')

    / param=ref;

model cvd =

    RIDAGEYR
    BMXBMI
    LBXGH
    hypertension
    smoking
    RIAGENDR;

run;


/**************************************************************************
Prepare Forest Plot dataset
**************************************************************************/

data forest;

    set OR_Table;

    length Variable $80;

    Variable = Effect;

    OR  = OddsRatioEst;
    LCL = LowerCL;
    UCL = UpperCL;

run;


/**************************************************************************
Sort variables
**************************************************************************/

proc sort data=forest;

by descending OR;

run;


/**************************************************************************
Forest Plot
**************************************************************************/

title "Adjusted Odds Ratios for Cardiovascular Disease";

proc sgplot data=forest;

scatter y=Variable
        x=OR
        / xerrorlower=LCL
          xerrorupper=UCL
          markerattrs=(symbol=circlefilled size=9);

refline 1 / axis=x lineattrs=(pattern=shortdash);

xaxis type=log
      label="Odds Ratio (95% CI)";

yaxis discreteorder=data
      display=(nolabel);

run;

title;

