/**************************************************************************
Project : NHANES HbA1c and Cardiovascular Disease
File    : 01_import.sas
Author  : Nadya Shilina

Purpose:
Import NHANES 2017–2018 data (cycle J).

**************************************************************************/

options nodate nonumber;

%let proj=/home/u64297063;

libname nhanes "&proj";

/**************************************************************************
Import XPT files
**************************************************************************/

libname demo xport "&proj/DEMO_J.xpt";
proc copy in=demo out=nhanes; run;
libname demo clear;

libname ghb xport "&proj/GHB_J.xpt";
proc copy in=ghb out=nhanes; run;
libname ghb clear;

libname bmx xport "&proj/BMX_J.xpt";
proc copy in=bmx out=nhanes; run;
libname bmx clear;

libname bpq xport "&proj/BPQ_J.xpt";
proc copy in=bpq out=nhanes; run;
libname bpq clear;

libname bpx xport "&proj/BPX_J.xpt";
proc copy in=bpx out=nhanes; run;
libname bpx clear;

libname smq xport "&proj/SMQ_J.xpt";
proc copy in=smq out=nhanes; run;
libname smq clear;

libname mcq xport "&proj/MCQ_J.xpt";
proc copy in=mcq out=nhanes; run;
libname mcq clear;

/**************************************************************************
Check imported datasets
**************************************************************************/

proc contents data=nhanes.demo_j; run;
proc contents data=nhanes.ghb_j;  run;
proc contents data=nhanes.bmx_j;  run;
proc contents data=nhanes.bpq_j;  run;
proc contents data=nhanes.bpx_j;  run;
proc contents data=nhanes.smq_j;  run;
proc contents data=nhanes.mcq_j;  run;
