############################################################
# Project : NHANES HbA1c and Cardiovascular Disease
# File    : 01_import.R
# Author  : Nadya Shilina
#
# Purpose:
# Import NHANES 2017–2018 datasets required for the analysis.
#
# Data source:
# National Health and Nutrition Examination Survey (NHANES)
# Centers for Disease Control and Prevention (CDC)
# https://www.cdc.gov/nchs/nhanes/
############################################################

#====================================================================
# Load packages
#====================================================================

library(haven)

#====================================================================
# Project directory
#====================================================================

setwd("D:/Universidad de Valencia/ENTRENAR_R_dif/HbA1c_cardiovascular disease_R_SAS")

#====================================================================
# Import NHANES datasets
#====================================================================

demo <- read_xpt("data/DEMO_J.xpt")
ghb  <- read_xpt("data/GHB_J.xpt")
bmx  <- read_xpt("data/BMX_J.xpt")
bpq  <- read_xpt("data/BPQ_J.xpt")
bpx  <- read_xpt("data/BPX_J.xpt")
smq  <- read_xpt("data/SMQ_J.xpt")
mcq  <- read_xpt("data/MCQ_J.xpt")

#====================================================================
# Verify imported datasets
#====================================================================

dataset_dimensions <- data.frame(
  
  Dataset = c(
    "DEMO",
    "GHB",
    "BMX",
    "BPQ",
    "BPX",
    "SMQ",
    "MCQ"
  ),
  
  Rows = c(
    nrow(demo),
    nrow(ghb),
    nrow(bmx),
    nrow(bpq),
    nrow(bpx),
    nrow(smq),
    nrow(mcq)
  ),
  
  Columns = c(
    ncol(demo),
    ncol(ghb),
    ncol(bmx),
    ncol(bpq),
    ncol(bpx),
    ncol(smq),
    ncol(mcq)
  )
  
)

print(dataset_dimensions)
