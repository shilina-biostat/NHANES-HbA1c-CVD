/**************************************************************************
Project : NHANES HbA1c and Cardiovascular Disease
File    : 03_eda.sas

Purpose:
Exploratory Data Analysis (EDA)

- Descriptive statistics
- Frequency tables
- Histograms
- Boxplots
- CVD prevalence by HbA1c category

NHANES 2017–2018
**************************************************************************/

options nodate nonumber;

%let proj=/home/u64297063;

libname nhanes "&proj";

ods graphics on;


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
Continuous variables
**************************************************************************/

title "Continuous variables";

proc means
    data=nhanes.analysis_complete
    n mean std median q1 q3 min max
    maxdec=2;

var
    RIDAGEYR
    BMXBMI
    LBXGH;

run;

title;


/**************************************************************************
Categorical variables
**************************************************************************/

title "Categorical variables";

proc freq
    data=nhanes.analysis_complete;

tables

    RIAGENDR
    RIDRETH1
    smoking
    hypertension
    hba1c_group
    cvd

    / missing;

run;

title;


/**************************************************************************
Histogram: Age
**************************************************************************/

title "Age distribution";

proc sgplot
    data=nhanes.analysis_complete;

histogram RIDAGEYR;

density RIDAGEYR;

xaxis label="Age (years)";

run;

title;


/**************************************************************************
Histogram: BMI
**************************************************************************/

title "BMI distribution";

proc sgplot
    data=nhanes.analysis_complete;

histogram BMXBMI;

density BMXBMI;

xaxis label="BMI (kg/m²)";

run;

title;


/**************************************************************************
Histogram: HbA1c
**************************************************************************/

title "HbA1c distribution";

proc sgplot
    data=nhanes.analysis_complete;

histogram LBXGH;

density LBXGH;

refline 5.7 6.5 / axis=x;

xaxis label="HbA1c (%)";

run;

title;


/**************************************************************************
HbA1c by CVD
**************************************************************************/

title "HbA1c by CVD";

proc sgplot
    data=nhanes.analysis_complete;

vbox LBXGH /
    category=cvd;

yaxis label="HbA1c (%)";

run;

title;


/**************************************************************************
BMI by CVD
**************************************************************************/

title "BMI by CVD";

proc sgplot
    data=nhanes.analysis_complete;

vbox BMXBMI /
    category=cvd;

yaxis label="BMI (kg/m²)";

run;

title;


/**************************************************************************
Age by CVD
**************************************************************************/

title "Age by CVD";

proc sgplot
    data=nhanes.analysis_complete;

vbox RIDAGEYR /
    category=cvd;

yaxis label="Age (years)";

run;

title;


/**************************************************************************
Characteristics by CVD
**************************************************************************/

title "Characteristics by CVD";

proc means
    data=nhanes.analysis_complete
    mean std median maxdec=2;

class cvd;

var

    RIDAGEYR
    BMXBMI
    LBXGH;

run;

title;


/**************************************************************************
Association between HbA1c category and CVD
**************************************************************************/

title "Association between HbA1c category and CVD";

proc freq
    data=nhanes.analysis_complete;

tables

    hba1c_group*cvd

    / chisq expected norow nocol;

run;

title;


/**************************************************************************
Percentage of CVD within HbA1c categories
**************************************************************************/

proc freq
    data=nhanes.analysis_complete
    noprint;

tables hba1c_group*cvd /
    out=cvd_bar
    outpct;

run;


/**************************************************************************
Keep only participants with CVD
**************************************************************************/

data cvd_bar;

    set cvd_bar;

    if cvd=1;

run;


/**************************************************************************
Bar plot
**************************************************************************/

title "Prevalence of CVD by HbA1c category";

proc sgplot
    data=cvd_bar;

vbar hba1c_group /

    response=pct_row
    datalabel;

yaxis label="CVD prevalence (%)";

xaxis label="HbA1c category";

run;

title;

ods graphics off;
