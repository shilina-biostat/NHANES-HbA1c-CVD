/**************************************************************************
Project : NHANES HbA1c and Cardiovascular Disease
File    : 04_table1.sas

Purpose:
Table 1. Baseline characteristics by cardiovascular disease (CVD)

NHANES 2017–2018
**************************************************************************/

options nodate nonumber;

%let proj=/home/u64297063;

libname nhanes "&proj";

ods listing;


/**************************************************************************
Continuous variables
**************************************************************************/

title "Table 1. Continuous variables by CVD";

proc means
    data=nhanes.analysis_complete
    n mean std median q1 q3
    maxdec=2;

class cvd;

var

    RIDAGEYR
    BMXBMI
    LBXGH
    sbp_mean
    dbp_mean;

run;


/**************************************************************************
Age
**************************************************************************/

ods output TTests=p_age;

ods graphics off;

proc ttest data=nhanes.analysis_complete;

class cvd;

var RIDAGEYR;

run;


/**************************************************************************
BMI
**************************************************************************/

ods output TTests=p_bmi;

proc ttest data=nhanes.analysis_complete;

class cvd;

var BMXBMI;

run;


/**************************************************************************
HbA1c
**************************************************************************/

ods output TTests=p_hba1c;

proc ttest data=nhanes.analysis_complete;

class cvd;

var LBXGH;

run;


/**************************************************************************
SBP
**************************************************************************/

ods output TTests=p_sbp;

proc ttest data=nhanes.analysis_complete;

class cvd;

var sbp_mean;

run;


/**************************************************************************
DBP
**************************************************************************/

ods output TTests=p_dbp;

proc ttest data=nhanes.analysis_complete;

class cvd;

var dbp_mean;

run;


/**************************************************************************
Categorical variables
**************************************************************************/

%macro freqtest(var);

title "&var";

proc freq
    data=nhanes.analysis_complete;

tables

    &var*cvd

    / chisq;

run;

%mend;


%freqtest(RIAGENDR);
%freqtest(RIDRETH1);
%freqtest(smoking);
%freqtest(hypertension);
%freqtest(hba1c_group);


/**************************************************************************
Missing values
**************************************************************************/

title "Missing values";

proc means
    data=nhanes.analysis_complete
    n nmiss;

var

    RIDAGEYR
    BMXBMI
    LBXGH
    sbp_mean
    dbp_mean;

run;

title;


/**************************************************************************
Dataset dimensions
**************************************************************************/

proc sql;

title "Dataset dimensions";

select count(*) as Participants
from nhanes.analysis_complete;

quit;

title;
