/**************************************************************************
Project : NHANES HbA1c and Cardiovascular Disease
File    : 07_roc_curve.sas

Purpose:
ROC Curve and AUC
(Logistic Regression Model)

NHANES 2017–2018
**************************************************************************/

options nodate nonumber;

%let proj=/home/u64297063;

libname nhanes "&proj";

ods graphics on;


/**************************************************************************
Logistic model with ROC curve

FIXED (3 issues):
1. RIDRETH1 removed - not part of R's model, was making this AUC
   incomparable to R's benchmark (0.812).
2. hba1c_group removed from CLASS - it was declared but never used
   in the MODEL statement (model already used continuous LBXGH),
   so it was a harmless but confusing leftover declaration.
3. RIAGENDR(ref='2') -> RIAGENDR(ref='1'), same fix as elsewhere.

Expected (matches R): AUC (c-statistic) ~0.812 [0.795-0.829]
**************************************************************************/

title "ROC Curve for Cardiovascular Disease Prediction";

proc logistic
    data=nhanes.analysis_complete
    plots(only)=roc(id=prob);

    class
        RIAGENDR (ref='1')
        smoking (ref='Never')
        hypertension (ref='0')
        / param=ref;

    model cvd(event='1') =

        RIDAGEYR
        BMXBMI
        LBXGH
        hypertension
        RIAGENDR
        smoking
        /

        outroc=roc_data
        ctable
        lackfit
        rsquare;

    roc "Full model";

run;

title;


/**************************************************************************
Display first ROC points
**************************************************************************/

title "ROC coordinates";

proc print data=roc_data(obs=20);
run;

title;


/**************************************************************************
Comparison: HbA1c-only model
ADDED to match R's 07_roc_curve.R, which explicitly compares the
full model AUC against an HbA1c-only model AUC to show how much
discrimination comes from HbA1c alone vs the other risk factors.

Expected (matches R): AUC (HbA1c only) ~0.674
**************************************************************************/

title "ROC Curve: HbA1c-only Model";

proc logistic data=nhanes.analysis_complete descending;

    model cvd = LBXGH;

    roc "HbA1c only";

run;

title;

ods graphics off;

