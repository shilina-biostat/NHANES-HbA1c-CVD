# =============================================================
# 07_roc_curve.R
# ROC curve and AUC for the logistic regression model
#
# Model:
# CVD ~ HbA1c + age + sex + BMI + smoking + hypertension
#
# NHANES 2017–2018
# =============================================================

library(pROC)

dir.create("figures", showWarnings = FALSE)

# -------------------------------------------------------------
# Load data
# -------------------------------------------------------------

df <- readRDS("data/analysis_complete.rds")

# -------------------------------------------------------------
# Fit multivariable logistic regression model
# -------------------------------------------------------------

model <- glm(
  
  cvd ~ hba1c +
    age +
    sex +
    bmi +
    smoking +
    hypertension,
  
  data = df,
  family = binomial
  
)

# -------------------------------------------------------------
# Predicted probabilities
# -------------------------------------------------------------

df$predicted_probability <-
  predict(
    model,
    type = "response"
  )

# -------------------------------------------------------------
# ROC curve
# -------------------------------------------------------------

roc_model <-
  
  roc(
    
    response = df$cvd,
    
    predictor = df$predicted_probability,
    
    levels = c("No", "Yes"),
    
    direction = "<"
    
  )

auc_value <- auc(roc_model)

auc_ci <- ci.auc(roc_model)

cat("\n==============================\n")
cat("Multivariable model\n")
cat("==============================\n")

cat(
  
  sprintf(
    
    "AUC = %.3f (95%% CI %.3f–%.3f)\n",
    
    auc_value,
    
    auc_ci[1],
    
    auc_ci[3]
    
  )
  
)

# -------------------------------------------------------------
# Optimal cut-off (Youden Index)
# -------------------------------------------------------------

best_cutoff <-
  
  coords(
    
    roc_model,
    
    x = "best",
    
    best.method = "youden",
    
    ret = c(
      
      "threshold",
      
      "sensitivity",
      
      "specificity"
      
    )
    
  )

print(best_cutoff)

# -------------------------------------------------------------
# ROC plot
# -------------------------------------------------------------

png(
  
  filename = "figures/roc_curve.png",
  
  width = 700,
  
  height = 700,
  
  res = 150
  
)

plot(
  
  roc_model,
  
  col = "#C44E52",
  
  lwd = 3,
  
  legacy.axes = TRUE,
  
  main = sprintf(
    
    "ROC Curve\nAUC = %.3f (95%% CI %.3f–%.3f)",
    
    auc_value,
    
    auc_ci[1],
    
    auc_ci[3]
    
  ),
  
  xlab = "False Positive Rate (1 - Specificity)",
  
  ylab = "True Positive Rate (Sensitivity)"
  
)

abline(
  
  a = 0,
  
  b = 1,
  
  lty = 2,
  
  col = "grey50"
  
)

points(
  
  1 - best_cutoff$specificity,
  
  best_cutoff$sensitivity,
  
  pch = 19,
  
  col = "#4C72B0",
  
  cex = 1.3
  
)

text(
  
  1 - best_cutoff$specificity,
  
  best_cutoff$sensitivity,
  
  labels = sprintf(
    
    "  Threshold = %.3f",
    
    best_cutoff$threshold
    
  ),
  
  pos = 4,
  
  cex = 0.8,
  
  col = "#4C72B0"
  
)

dev.off()

# -------------------------------------------------------------
# HbA1c-only model
# -------------------------------------------------------------

model_hba1c <-
  
  glm(
    
    cvd ~ hba1c,
    
    data = df,
    
    family = binomial
    
  )

df$pred_hba1c <-
  
  predict(
    
    model_hba1c,
    
    type = "response"
    
  )

roc_hba1c <-
  
  roc(
    
    response = df$cvd,
    
    predictor = df$pred_hba1c,
    
    levels = c("No", "Yes"),
    
    direction = "<"
    
  )

cat("\n==============================\n")
cat("Model comparison\n")
cat("==============================\n")

cat(
  
  sprintf(
    
    "HbA1c only model:      AUC = %.3f\n",
    
    auc(roc_hba1c)
    
  )
  
)

cat(
  
  sprintf(
    
    "Multivariable model:   AUC = %.3f\n",
    
    auc_value
    
  )
  
)

cat(
  
  sprintf(
    
    "Improvement in AUC:    %.3f\n",
    
    auc_value - auc(roc_hba1c)
    
  )
  
)

cat("\nROC curve saved:\n")
cat("figures/roc_curve.png\n")
