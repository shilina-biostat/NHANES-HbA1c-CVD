# =============================================================
# 03_eda.R
# NHANES 2017–2018
# Exploratory Data Analysis (EDA)
#
# - Descriptive statistics
# - Frequency tables
# - Histograms
# - Boxplots
# - CVD prevalence by HbA1c category
# =============================================================

rm(list = ls())

# -------------------------------------------------------------
# Load data
# -------------------------------------------------------------

df <- readRDS("data/analysis_complete.rds")

dir.create("figures", showWarnings = FALSE)

# -------------------------------------------------------------
# Descriptive statistics
# -------------------------------------------------------------

describe_var <- function(x, name) {
  
  cat("\n----------------------------------------\n")
  cat(name, "\n")
  cat("----------------------------------------\n")
  
  cat(sprintf("N      : %d\n", sum(!is.na(x))))
  cat(sprintf("Mean   : %.2f\n", mean(x, na.rm = TRUE)))
  cat(sprintf("SD     : %.2f\n", sd(x, na.rm = TRUE)))
  cat(sprintf("Median : %.2f\n", median(x, na.rm = TRUE)))
  cat(sprintf("Q1     : %.2f\n", quantile(x, 0.25, na.rm = TRUE)))
  cat(sprintf("Q3     : %.2f\n", quantile(x, 0.75, na.rm = TRUE)))
  cat(sprintf("Min    : %.2f\n", min(x, na.rm = TRUE)))
  cat(sprintf("Max    : %.2f\n", max(x, na.rm = TRUE)))
  
}

cat("========================================\n")
cat("Study population\n")
cat("========================================\n")
cat("Participants:", nrow(df), "\n")

describe_var(df$age, "Age (years)")
describe_var(df$bmi, "Body Mass Index (kg/m²)")
describe_var(df$hba1c, "HbA1c (%)")

# -------------------------------------------------------------
# Frequency tables
# -------------------------------------------------------------

cat("\n========================================\n")
cat("Categorical variables\n")
cat("========================================\n")

categorical_vars <- c(
  "sex",
  "race",
  "smoking",
  "hypertension",
  "hba1c_cat",
  "cvd"
)

for (v in categorical_vars) {
  
  cat("\n----------------------------------------\n")
  cat(v, "\n")
  cat("----------------------------------------\n")
  
  tab <- table(df[[v]], useNA = "ifany")
  
  print(tab)
  print(round(prop.table(tab) * 100, 1))
  
}

# -------------------------------------------------------------
# Histograms
# -------------------------------------------------------------

png(
  "figures/hist_age_bmi_hba1c.png",
  width = 1500,
  height = 500,
  res = 120
)

par(mfrow = c(1, 3), mar = c(4, 4, 3, 1))

hist(
  df$age,
  breaks = 20,
  col = "#4C72B0",
  border = "white",
  main = "Age",
  xlab = "Years",
  ylab = "Frequency"
)

hist(
  df$bmi,
  breaks = 30,
  col = "#55A868",
  border = "white",
  main = "Body Mass Index",
  xlab = "kg/m²",
  ylab = "Frequency"
)

hist(
  df$hba1c,
  breaks = 30,
  col = "#C44E52",
  border = "white",
  main = "HbA1c",
  xlab = "%",
  ylab = "Frequency"
)

abline(v = c(5.7, 6.5), lty = 2, lwd = 2)

dev.off()

# -------------------------------------------------------------
# Boxplots by CVD status
# -------------------------------------------------------------

png(
  "figures/boxplot_by_cvd.png",
  width = 1000,
  height = 500,
  res = 120
)

par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))

boxplot(
  hba1c ~ cvd,
  data = df,
  col = c("#8FBBD9", "#E88C8C"),
  main = "HbA1c by CVD",
  xlab = "Cardiovascular disease",
  ylab = "HbA1c (%)"
)

boxplot(
  bmi ~ cvd,
  data = df,
  col = c("#8FBBD9", "#E88C8C"),
  main = "BMI by CVD",
  xlab = "Cardiovascular disease",
  ylab = "BMI (kg/m²)"
)

dev.off()

# -------------------------------------------------------------
# Age by CVD
# -------------------------------------------------------------

png(
  "figures/boxplot_age_by_cvd.png",
  width = 600,
  height = 500,
  res = 120
)

boxplot(
  age ~ cvd,
  data = df,
  col = c("#8FBBD9", "#E88C8C"),
  main = "Age by CVD",
  xlab = "Cardiovascular disease",
  ylab = "Age (years)"
)

dev.off()

# -------------------------------------------------------------
# CVD prevalence by HbA1c category
# -------------------------------------------------------------

cvd_prev <- prop.table(
  table(df$hba1c_cat, df$cvd),
  margin = 1
)[, "Yes"]

png(
  "figures/barplot_cvd_by_hba1c_cat.png",
  width = 700,
  height = 500,
  res = 120
)

bp <- barplot(
  100 * cvd_prev,
  col = "#C44E52",
  ylim = c(0, max(100 * cvd_prev) * 1.3),
  main = "CVD prevalence by HbA1c category",
  ylab = "Participants with CVD (%)",
  names.arg = names(cvd_prev),
  cex.names = 0.85
)

text(
  bp,
  100 * cvd_prev,
  labels = sprintf("%.1f%%", 100 * cvd_prev),
  pos = 3
)

dev.off()

# -------------------------------------------------------------
# End of script
# -------------------------------------------------------------

cat("\n========================================\n")
cat("EDA completed successfully.\n")
cat("Figures saved to: figures/\n")
cat("========================================\n")

list.files("figures")
