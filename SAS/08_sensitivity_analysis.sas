/**************************************************************************
Project : NHANES HbA1c and Cardiovascular Disease
File    : 08_sensitivity_analysis.sas

Purpose:
Sensitivity analysis:
HbA1c as categorical variable

NHANES 2017–2018
**************************************************************************/

options nodate nonumber;

%let proj=/home/u64297063;

libname nhanes "&proj";

ods graphics off;

/**************************************************************************
Reference category
<5.7 (Normal)

FIXED (2 issues):
1. RIDRETH1 removed from class/model - R's sensitivity model does
   not adjust for race (cvd ~ hba1c_cat + age + sex + bmi + smoking +
   hypertension), so including it here made the categorical OR
   incomparable to R's benchmark values.
2. RIAGENDR(ref="2") -> RIAGENDR(ref="1"), same fix as elsewhere.

Expected (matches R): Prediabetes OR ~1.25 [0.98-1.60] p~0.067 (n.s.),
                       Diabetes OR ~1.72 [1.31-2.26] p<0.001
**************************************************************************/

proc logistic
    data=nhanes.analysis_complete
    descending;

class

    hba1c_group (ref="<5.7 (Normal)")
    RIAGENDR (ref="1")
    smoking (ref="Never")
    hypertension (ref="0")

    / param=ref;

model cvd(event='1') =

    hba1c_group
    RIDAGEYR
    RIAGENDR
    BMXBMI
    smoking
    hypertension;

oddsratio hba1c_group;

ods output
    ParameterEstimates = SensitivityParameters
    OddsRatios         = SensitivityOR
    Association        = SensitivityAUC;

run;


/**************************************************************************
Show Odds Ratios
**************************************************************************/

title "Sensitivity analysis: HbA1c categories";

proc print data=SensitivityOR noobs;
run;

title;


/**************************************************************************
Show model fit
**************************************************************************/

title "Model performance";

proc print data=SensitivityAUC noobs;
run;

title;


/**************************************************************************
Export results
**************************************************************************/

proc export
    data=SensitivityOR
    outfile="&proj/Sensitivity_OR.csv"
    dbms=csv
    replace;
run;
