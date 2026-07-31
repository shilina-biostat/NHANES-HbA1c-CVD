/**************************************************************************
Project : NHANES HbA1c and Cardiovascular Disease
File    : 02_prepare_data.sas

Purpose:
Merge NHANES datasets and prepare analytical dataset.

NHANES 2017–2018
**************************************************************************/

options nodate nonumber;

%let proj=/home/u64297063;

libname nhanes "&proj";

/**************************************************************************
Sort datasets
**************************************************************************/

proc sort data=nhanes.demo_j; by SEQN; run;
proc sort data=nhanes.ghb_j;  by SEQN; run;
proc sort data=nhanes.bmx_j;  by SEQN; run;
proc sort data=nhanes.bpq_j;  by SEQN; run;
proc sort data=nhanes.bpx_j;  by SEQN; run;
proc sort data=nhanes.smq_j;  by SEQN; run;
proc sort data=nhanes.mcq_j;  by SEQN; run;


/**************************************************************************
Merge NHANES files
**************************************************************************/

data nhanes.analysis;

    merge

        nhanes.demo_j
            (keep=
                SEQN
                RIAGENDR
                RIDAGEYR
                RIDRETH1
                WTMEC2YR)

        nhanes.ghb_j
            (keep=
                SEQN
                LBXGH)

        nhanes.bmx_j
            (keep=
                SEQN
                BMXBMI)

        nhanes.bpq_j
            (keep=
                SEQN
                BPQ020)

        nhanes.bpx_j
            (keep=
                SEQN
                BPXSY1 BPXSY2 BPXSY3 BPXSY4
                BPXDI1 BPXDI2 BPXDI3 BPXDI4)

        nhanes.smq_j
            (keep=
                SEQN
                SMQ020
                SMQ040)

        nhanes.mcq_j
            (keep=
                SEQN
                MCQ160C
                MCQ160E
                MCQ160F);

    by SEQN;

    /* Adults only */

    if RIDAGEYR >=18;

run;


/**************************************************************************
Create derived variables
**************************************************************************/

data nhanes.analysis;

    set nhanes.analysis;

    /*************************************************************
    Mean blood pressure
    *************************************************************/

    sbp_mean = mean(of BPXSY1-BPXSY4);
    dbp_mean = mean(of BPXDI1-BPXDI4);


    /*************************************************************
    HbA1c category

    FIXED: explicit missing(LBXGH) check added FIRST.
    In SAS, a missing numeric is treated as -infinity in
    comparisons, so "if LBXGH < 5.7" would otherwise evaluate
    TRUE even when LBXGH is missing, silently mislabeling
    missing HbA1c as "Normal".
    *************************************************************/

    length hba1c_group $25;

    if missing(LBXGH) then
        hba1c_group = "Unknown";

    else if LBXGH < 5.7 then
        hba1c_group = "<5.7 (Normal)";

    else if LBXGH < 6.5 then
        hba1c_group = "5.7-6.4 (Prediabetes)";

    else
        hba1c_group = ">=6.5 (Diabetes)";


    /*************************************************************
    Smoking status

    FIXED: kept "Unknown" for readability in frequency tables,
    but the complete-case step (below) now explicitly excludes
    it, matching R's NA/complete.cases() behavior.
    *************************************************************/

    length smoking $10;

    if SMQ020=2 then
        smoking="Never";

    else if SMQ020=1 and SMQ040=3 then
        smoking="Former";

    else if SMQ020=1 and SMQ040 in (1,2) then
        smoking="Current";

    else
        smoking="Unknown";


    /*************************************************************
    Hypertension

    FIXED: rebuilt using intermediate flags hyp_self / hyp_meas,
    exactly mirroring the R logic:
      - "Yes" if EITHER source says Yes
      - "No"  if EITHER source says No (and neither says Yes)
      - missing only if BOTH sources are unavailable/inconclusive
    Previous version required BOTH self-report=No AND measured
    BP normal simultaneously to assign "No", which produced more
    missing (excluded) cases than R whenever one source was
    unavailable.
    *************************************************************/

    hyp_self = .;
    if BPQ020 = 1 then hyp_self = 1;
    else if BPQ020 = 2 then hyp_self = 0;

    hyp_meas = .;
    if not missing(sbp_mean) and not missing(dbp_mean) then do;
        if sbp_mean >= 140 or dbp_mean >= 90 then hyp_meas = 1;
        else hyp_meas = 0;
    end;

    hypertension = .;
    if hyp_self = 1 or hyp_meas = 1 then hypertension = 1;
    else if hyp_self = 0 or hyp_meas = 0 then hypertension = 0;


    /*************************************************************
    Cardiovascular disease (CVD)

    FIXED: previously required ALL THREE of MCQ160C/E/F to be
    explicitly "2" (No) to assign cvd=0 - if any single one was
    missing while the other two said No, the participant was
    incorrectly dropped to missing. Now matches R: cvd=0 if at
    least one source is known "No" and NONE says "Yes", even if
    another source is missing.
    *************************************************************/

    cvd=.;

    if MCQ160C=1 or
       MCQ160E=1 or
       MCQ160F=1 then
        cvd=1;

    else if (missing(MCQ160C) or MCQ160C=2) and
            (missing(MCQ160E) or MCQ160E=2) and
            (missing(MCQ160F) or MCQ160F=2) and
            (not missing(MCQ160C) or not missing(MCQ160E) or not missing(MCQ160F)) then
        cvd=0;

    drop hyp_self hyp_meas;

run;


/**************************************************************************
Create complete-case dataset

FIXED: added explicit exclusion of smoking="Unknown" (missing()
alone does not catch it, since the character value is never
truly blank). Also added checks for RIAGENDR and RIDRETH1 for
full parity with R's complete.cases() across all 8 analysis
variables (in practice these are almost never missing in NHANES
demographics, but included for exact equivalence).
**************************************************************************/

data nhanes.analysis_complete;

    set nhanes.analysis;

    if missing(RIDAGEYR) then delete;
    if missing(RIAGENDR) then delete;
    if missing(RIDRETH1) then delete;
    if missing(BMXBMI) then delete;
    if missing(LBXGH) then delete;

    if missing(hba1c_group) or hba1c_group = "Unknown" then delete;
    if missing(smoking) or smoking = "Unknown" then delete;
    if missing(hypertension) then delete;
    if missing(cvd) then delete;

run;


/**************************************************************************
Check datasets
**************************************************************************/

title "Analysis dataset";

proc contents data=nhanes.analysis;
run;


title "Analysis complete dataset";

proc contents data=nhanes.analysis_complete;
run;


/**************************************************************************
Number of observations
Expected (matches R): N_complete = 4919
**************************************************************************/

title "Number of observations";

proc sql;

select count(*) as N_analysis
from nhanes.analysis;

select count(*) as N_complete
from nhanes.analysis_complete;

quit;

title;


/**************************************************************************
Frequency of derived variables
Expected (matches R): cvd - 492 Yes / 4427 No
**************************************************************************/

proc freq data=nhanes.analysis_complete;

tables

    hba1c_group
    smoking
    hypertension
    cvd

    / missing;

run;

title;
