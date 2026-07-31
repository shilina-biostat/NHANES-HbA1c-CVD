/**************************************************************************
Project : NHANES HbA1c and Cardiovascular Disease
File    : 05_regression.sas

Purpose:
Logistic regression analysis of cardiovascular disease (CVD)

Outcome:
    CVD (0/1)

Predictors:
    HbA1c
    Age
    Sex
    BMI
    Smoking
    Hypertension

NHANES 2017–2018
**************************************************************************/

options nodate nonumber;

%let proj=/home/u64297063;

libname nhanes "&proj";

ods graphics off;


/**************************************************************************
Study population
**************************************************************************/

title "Study population";

proc sql;

select count(*) as Participants
from nhanes.analysis_complete;

quit;

title;


/**************************************************************************
Univariate logistic regression
**************************************************************************/

title "Univariate logistic regression: HbA1c";

proc logistic data=nhanes.analysis_complete descending;

model cvd = LBXGH;

oddsratio LBXGH;

run;


title "Univariate logistic regression: Age";

proc logistic data=nhanes.analysis_complete descending;

model cvd = RIDAGEYR;

oddsratio RIDAGEYR;

run;


title "Univariate logistic regression: BMI";

proc logistic data=nhanes.analysis_complete descending;

model cvd = BMXBMI;

oddsratio BMXBMI;

run;


/**************************************************************************
Multivariable logistic regression

FIXED: RIAGENDR(ref='2') -> RIAGENDR(ref='1'). R's sex factor uses
levels=c(1,2), labels=c("Male","Female") - reference is "Male"
(the first level), so the model reports the Female-vs-Male effect.
ref='2' set the reference to Female instead, flipping the direction
of comparison relative to R (would report Male-vs-Female, i.e. a
reciprocal OR).

Expected (matches R): HbA1c OR ~1.16 [1.07-1.25], age OR ~1.06,
sex (Female vs Male) OR ~0.64, hypertension OR ~2.10
**************************************************************************/

title "Adjusted logistic regression";

proc logistic
    data=nhanes.analysis_complete
    descending;

class

    RIAGENDR (ref='1')
    smoking (ref='Never')
    hypertension (ref='0')

    / param=ref;

model cvd(event='1') =

        LBXGH
        RIDAGEYR
        BMXBMI
        RIAGENDR
        smoking
        hypertension

        / clodds=wald;

oddsratio LBXGH;
oddsratio RIDAGEYR;
oddsratio BMXBMI;

output
    out=predicted
    pred=probability;

run;


/**************************************************************************
ROC curve
**************************************************************************/

title "ROC curve";

proc logistic
    data=nhanes.analysis_complete
    plots(only)=roc;

class

    RIAGENDR(ref='1')
    smoking(ref='Never')
    hypertension(ref='0')

    / param=ref;

model cvd(event='1') =

        LBXGH
        RIDAGEYR
        BMXBMI
        RIAGENDR
        smoking
        hypertension;

roc;

run;


/**************************************************************************
Hosmer-Lemeshow goodness of fit
**************************************************************************/

title "Hosmer-Lemeshow test";

proc logistic
    data=nhanes.analysis_complete
    descending;

class

    RIAGENDR(ref='1')
    smoking(ref='Never')
    hypertension(ref='0')

    / param=ref;

model cvd =

        LBXGH
        RIDAGEYR
        BMXBMI
        RIAGENDR
        smoking
        hypertension

        / lackfit;

run;


/**************************************************************************
Distribution of predicted probabilities
**************************************************************************/

title "Predicted probability of CVD";

proc sgplot data=predicted;

histogram probability;

density probability;

xaxis label="Predicted probability";

run;

title;

