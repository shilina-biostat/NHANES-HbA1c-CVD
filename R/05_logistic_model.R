# =============================================================
# 05_logistic_model.R
# NHANES 2017–2018
#
# Multivariable logistic regression
#
# Outcome:
#   Cardiovascular disease (CVD)
#
# Predictors:
#   - HbA1c
#   - Age
#   - Sex
#   - BMI
#   - Smoking status
#   - Hypertension
#
# Outputs:
#   output/logistic_model.rds
#   output/logistic_or_table.csv
# =============================================================

rm(list = ls())

dir.create("output", showWarnings = FALSE)

# -------------------------------------------------------------
# Load analysis dataset
# -------------------------------------------------------------
df <- readRDS("data/analysis_complete.rds")

# -------------------------------------------------------------
# Fit logistic regression model
# -------------------------------------------------------------
model <- glm(
  
  cvd ~
    hba1c +
    age +
    sex +
    bmi +
    smoking +
    hypertension,
  
  data = df,
  
  family = binomial(link = "logit")
  
)

# -------------------------------------------------------------
# Model summary
# -------------------------------------------------------------
cat("\n=====================================================\n")
cat("Multivariable Logistic Regression\n")
cat("=====================================================\n\n")

print(summary(model))

# -------------------------------------------------------------
# Odds ratios with 95% confidence intervals
# -------------------------------------------------------------
coef_table <- summary(model)$coefficients

ci <- confint(model)

or_table <- data.frame(
  
  Variable = rownames(coef_table),
  
  OR = exp(coef_table[, "Estimate"]),
  
  CI_lower = exp(ci[,1]),
  
  CI_upper = exp(ci[,2]),
  
  p_value = coef_table[, "Pr(>|z|)"],
  
  stringsAsFactors = FALSE
  
)

# -------------------------------------------------------------
# Format p-values
# -------------------------------------------------------------
format_p <- function(p){
  
  if(is.na(p)) return("NA")
  
  if(p < 0.001)
    return("<0.001")
  
  sprintf("%.3f", p)
  
}

or_table$OR       <- round(or_table$OR, 2)
or_table$CI_lower <- round(or_table$CI_lower, 2)
or_table$CI_upper <- round(or_table$CI_upper, 2)

or_table$p_value <- sapply(
  or_table$p_value,
  format_p
)

names(or_table) <- c(
  
  "Variable",
  
  "OR",
  
  "95% CI Lower",
  
  "95% CI Upper",
  
  "p-value"
  
)

# -------------------------------------------------------------
# Print results
# -------------------------------------------------------------
cat("\n=====================================================\n")
cat("Odds Ratios (95% CI)\n")
cat("=====================================================\n\n")

print(or_table, row.names = FALSE)

# -------------------------------------------------------------
# McFadden's pseudo-R²
# -------------------------------------------------------------
pseudo_r2 <-
  1 -
  model$deviance /
  model$null.deviance

cat("\nMcFadden's pseudo-R²:",
    round(pseudo_r2,3),
    "\n")

# -------------------------------------------------------------
# Save outputs
# -------------------------------------------------------------
saveRDS(
  
  model,
  
  "output/logistic_model.rds"
  
)

write.csv(
  
  or_table,
  
  "output/logistic_or_table.csv",
  
  row.names = FALSE
  
)

cat("\nFiles saved:\n")
cat(" - output/logistic_model.rds\n")
cat(" - output/logistic_or_table.csv\n")
