# =============================================================
# 02_merge_clean.R
# NHANES 2017–2018
#
# Merge NHANES datasets, derive analysis variables,
# and create the analytical dataset.
# =============================================================

library(dplyr)

# -------------------------------------------------------------
# Convert tibbles to data.frames
# -------------------------------------------------------------

demo <- as.data.frame(demo)
ghb  <- as.data.frame(ghb)
bmx  <- as.data.frame(bmx)
bpq  <- as.data.frame(bpq)
bpx  <- as.data.frame(bpx)
smq  <- as.data.frame(smq)
mcq  <- as.data.frame(mcq)

# -------------------------------------------------------------
# Select variables
# -------------------------------------------------------------

demo_sub <- demo[, c(
  "SEQN",
  "RIDAGEYR",
  "RIAGENDR",
  "RIDRETH1"
)]

ghb_sub <- ghb[, c(
  "SEQN",
  "LBXGH"
)]

bmx_sub <- bmx[, c(
  "SEQN",
  "BMXBMI"
)]

bpq_sub <- bpq[, c(
  "SEQN",
  "BPQ020"
)]

bpx_sub <- bpx[, c(
  "SEQN",
  "BPXSY1","BPXSY2","BPXSY3","BPXSY4",
  "BPXDI1","BPXDI2","BPXDI3","BPXDI4"
)]

smq_sub <- smq[, c(
  "SEQN",
  "SMQ020",
  "SMQ040"
)]

mcq_sub <- mcq[, c(
  "SEQN",
  "MCQ160C",
  "MCQ160E",
  "MCQ160F"
)]

# -------------------------------------------------------------
# Calculate mean systolic and diastolic blood pressure
# -------------------------------------------------------------

sbp_vars <- c("BPXSY1","BPXSY2","BPXSY3","BPXSY4")
dbp_vars <- c("BPXDI1","BPXDI2","BPXDI3","BPXDI4")

bpx_sub$SBP_mean <- rowMeans(
  bpx_sub[, sbp_vars],
  na.rm = TRUE
)

bpx_sub$DBP_mean <- rowMeans(
  bpx_sub[, dbp_vars],
  na.rm = TRUE
)

bpx_sub$SBP_mean[is.nan(bpx_sub$SBP_mean)] <- NA
bpx_sub$DBP_mean[is.nan(bpx_sub$DBP_mean)] <- NA

bpx_sub <- bpx_sub[, c(
  "SEQN",
  "SBP_mean",
  "DBP_mean"
)]

# -------------------------------------------------------------
# Merge datasets
# -------------------------------------------------------------

df <- Reduce(
  function(x, y) merge(x, y, by = "SEQN", all.x = TRUE),
  list(
    demo_sub,
    ghb_sub,
    bmx_sub,
    bpq_sub,
    bpx_sub,
    smq_sub,
    mcq_sub
  )
)

cat("Participants after merge:", nrow(df), "\n")

# -------------------------------------------------------------
# Adults only (>=18 years)
# -------------------------------------------------------------

df <- df[df$RIDAGEYR >= 18, ]

cat("Participants aged 18 years or older:", nrow(df), "\n")

# -------------------------------------------------------------
# Create analysis variables
# -------------------------------------------------------------

## Age
df$age <- df$RIDAGEYR

## Sex
df$sex <- factor(
  df$RIAGENDR,
  levels = c(1,2),
  labels = c("Male","Female")
)

## Race/Ethnicity
df$race <- factor(
  df$RIDRETH1,
  levels = 1:5,
  labels = c(
    "Mexican American",
    "Other Hispanic",
    "Non-Hispanic White",
    "Non-Hispanic Black",
    "Other/Multiracial"
  )
)

## BMI
df$bmi <- df$BMXBMI

## HbA1c
df$hba1c <- df$LBXGH

## Smoking status
df$smoking <- NA_character_

df$smoking[df$SMQ020 == 2] <- "Never"

df$smoking[
  df$SMQ020 == 1 &
    df$SMQ040 %in% c(1,2)
] <- "Current"

df$smoking[
  df$SMQ020 == 1 &
    df$SMQ040 == 3
] <- "Former"

df$smoking <- factor(
  df$smoking,
  levels = c("Never","Former","Current")
)

## Hypertension

hyp_self <- ifelse(
  df$BPQ020 == 1,
  TRUE,
  ifelse(df$BPQ020 == 2, FALSE, NA)
)

hyp_measured <- ifelse(
  !is.na(df$SBP_mean) &
    !is.na(df$DBP_mean),
  df$SBP_mean >= 140 |
    df$DBP_mean >= 90,
  NA
)

df$hypertension <- ifelse(
  (!is.na(hyp_self) & hyp_self) |
    (!is.na(hyp_measured) & hyp_measured),
  1,
  ifelse(
    (!is.na(hyp_self) & !hyp_self) |
      (!is.na(hyp_measured) & !hyp_measured),
    0,
    NA
  )
)

df$hypertension <- factor(
  df$hypertension,
  levels = c(0,1),
  labels = c("No","Yes")
)

## Cardiovascular disease

is_yes <- function(x) x == 1
is_no  <- function(x) x == 2

any_cvd <- with(
  df,
  (!is.na(MCQ160C) & is_yes(MCQ160C)) |
    (!is.na(MCQ160E) & is_yes(MCQ160E)) |
    (!is.na(MCQ160F) & is_yes(MCQ160F))
)

all_no <- with(
  df,
  (is.na(MCQ160C) | is_no(MCQ160C)) &
    (is.na(MCQ160E) | is_no(MCQ160E)) &
    (is.na(MCQ160F) | is_no(MCQ160F)) &
    (!is.na(MCQ160C) |
       !is.na(MCQ160E) |
       !is.na(MCQ160F))
)

df$cvd <- ifelse(
  any_cvd,
  1,
  ifelse(all_no,0,NA)
)

df$cvd <- factor(
  df$cvd,
  levels = c(0,1),
  labels = c("No","Yes")
)

## HbA1c categories (ADA)

df$hba1c_cat <- cut(
  df$hba1c,
  breaks = c(-Inf,5.7,6.5,Inf),
  right = FALSE,
  labels = c(
    "<5.7 (Normal)",
    "5.7–6.4 (Prediabetes)",
    "≥6.5 (Diabetes)"
  )
)

# -------------------------------------------------------------
# Final analytical datasets
# -------------------------------------------------------------

analysis_vars <- c(
  "SEQN",
  "age",
  "sex",
  "race",
  "bmi",
  "hba1c",
  "hba1c_cat",
  "smoking",
  "hypertension",
  "cvd"
)

df_final <- df[, analysis_vars]

cat("\nMissing values by variable\n")

print(
  sapply(
    df_final,
    function(x) sum(is.na(x))
  )
)

df_complete <- df_final[
  complete.cases(df_final),
]

cat(
  "\nComplete cases:",
  nrow(df_complete),
  "\n"
)

# -------------------------------------------------------------
# Save datasets
# -------------------------------------------------------------

saveRDS(
  df_final,
  "data/analysis_full.rds"
)

saveRDS(
  df_complete,
  "data/analysis_complete.rds"
)

write.csv(
  df_complete,
  "data/analysis_complete.csv",
  row.names = FALSE
)

cat("\nStructure of the analytical dataset\n")

str(df_complete)

cat("\nDistribution of cardiovascular disease\n")

print(
  table(
    df_complete$cvd,
    useNA = "ifany"
  )
)

cat(
  "\nFiles created:
- analysis_full.rds
- analysis_complete.rds
- analysis_complete.csv\n"
)
