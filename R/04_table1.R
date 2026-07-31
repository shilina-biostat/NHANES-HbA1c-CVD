# =============================================================
# 04_table1.R
# NHANES 2017–2018
#
# Table 1. Baseline characteristics by cardiovascular disease
#
# Continuous variables:
#   - Mean (SD)
#   - Median [IQR]
#   - Student's t-test
#
# Categorical variables:
#   - n (%)
#   - Chi-square test
#   - Fisher's exact test when expected counts <5
#
# Output:
#   output/table1.csv
# =============================================================

rm(list = ls())

dir.create("output", showWarnings = FALSE)

# -------------------------------------------------------------
# Load analysis dataset
# -------------------------------------------------------------
df <- readRDS("data/analysis_complete.rds")

group <- df$cvd

# -------------------------------------------------------------
# Format p-values
# -------------------------------------------------------------
format_p <- function(p){
  
  if(is.na(p)) return("NA")
  
  if(p < 0.001)
    return("<0.001")
  
  sprintf("%.3f", p)
  
}

# -------------------------------------------------------------
# Continuous variables
# -------------------------------------------------------------
summarize_continuous <- function(x, group, varname){
  
  m  <- tapply(x, group, mean, na.rm = TRUE)
  s  <- tapply(x, group, sd, na.rm = TRUE)
  
  md <- tapply(x, group, median, na.rm = TRUE)
  q1 <- tapply(x, group, quantile, 0.25, na.rm = TRUE)
  q3 <- tapply(x, group, quantile, 0.75, na.rm = TRUE)
  
  p <- tryCatch(
    t.test(x ~ group)$p.value,
    error=function(e) NA
  )
  
  data.frame(
    
    Variable = varname,
    
    No_summary =
      sprintf("%.1f (%.1f); %.1f [%.1f–%.1f]",
              m["No"], s["No"],
              md["No"], q1["No"], q3["No"]),
    
    Yes_summary =
      sprintf("%.1f (%.1f); %.1f [%.1f–%.1f]",
              m["Yes"], s["Yes"],
              md["Yes"], q1["Yes"], q3["Yes"]),
    
    p_value = format_p(p),
    
    stringsAsFactors = FALSE
    
  )
  
}

# -------------------------------------------------------------
# Categorical variables
# -------------------------------------------------------------
summarize_categorical <- function(x, group, varname){
  
  tab <- table(x, group)
  
  prop <- prop.table(tab, margin = 2) * 100
  
  test <- suppressWarnings(chisq.test(tab))
  
  p <- test$p.value
  fisher_used <- FALSE
  
  if(any(test$expected < 5)){
    
    p <- fisher.test(
      tab,
      simulate.p.value = TRUE,
      B = 5000
    )$p.value
    
    fisher_used <- TRUE
    
  }
  
  out <- data.frame(
    
    Variable =
      c(varname,
        paste0("   ", rownames(tab))),
    
    No_summary =
      c("",
        sprintf("%d (%.1f%%)",
                tab[, "No"],
                prop[, "No"])),
    
    Yes_summary =
      c("",
        sprintf("%d (%.1f%%)",
                tab[, "Yes"],
                prop[, "Yes"])),
    
    p_value =
      c(
        paste0(
          format_p(p),
          ifelse(fisher_used,
                 " (Fisher)",
                 "")
        ),
        rep("", nrow(tab))
      ),
    
    stringsAsFactors = FALSE
    
  )
  
  out
  
}

# -------------------------------------------------------------
# Build Table 1
# -------------------------------------------------------------
table1 <- rbind(
  
  summarize_continuous(
    df$age,
    group,
    "Age, years"
  ),
  
  summarize_continuous(
    df$bmi,
    group,
    "BMI, kg/m²"
  ),
  
  summarize_continuous(
    df$hba1c,
    group,
    "HbA1c, %"
  ),
  
  summarize_categorical(
    df$sex,
    group,
    "Sex, n (%)"
  ),
  
  summarize_categorical(
    df$race,
    group,
    "Race/Ethnicity, n (%)"
  ),
  
  summarize_categorical(
    df$smoking,
    group,
    "Smoking status, n (%)"
  ),
  
  summarize_categorical(
    df$hypertension,
    group,
    "Hypertension, n (%)"
  ),
  
  summarize_categorical(
    df$hba1c_cat,
    group,
    "HbA1c category, n (%)"
  )
  
)

# -------------------------------------------------------------
# Rename columns
# -------------------------------------------------------------
n_no  <- sum(group == "No")
n_yes <- sum(group == "Yes")

names(table1) <- c(
  
  "Variable",
  
  sprintf("No CVD (n=%d)", n_no),
  
  sprintf("CVD (n=%d)", n_yes),
  
  "p-value"
  
)

# -------------------------------------------------------------
# Display
# -------------------------------------------------------------
cat("\n=====================================================\n")
cat("Table 1. Baseline characteristics by CVD status\n")
cat("=====================================================\n\n")

print(table1, row.names = FALSE)

# -------------------------------------------------------------
# Save
# -------------------------------------------------------------
write.csv(
  table1,
  "output/table1.csv",
  row.names = FALSE
)

cat("\nTable saved to:\n")
cat("output/table1.csv\n")
