# =============================================================
# 08_sensitivity_analysis.R
# Sensitivity analysis:
# HbA1c as a categorical predictor
#
# Model:
# CVD ~ HbA1c category + age + sex + BMI +
#       smoking + hypertension
#
# NHANES 2017–2018
# =============================================================

library(ggplot2)

dir.create("output", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

# -------------------------------------------------------------
# Load data
# -------------------------------------------------------------

df <- readRDS("data/analysis_complete.rds")

# -------------------------------------------------------------
# Logistic regression
# -------------------------------------------------------------

model_cat <-
  
  glm(
    
    cvd ~
      
      hba1c_cat +
      
      age +
      
      sex +
      
      bmi +
      
      smoking +
      
      hypertension,
    
    data = df,
    
    family = binomial
    
  )

summary(model_cat)

# -------------------------------------------------------------
# Odds Ratios
# -------------------------------------------------------------

coef_table <- summary(model_cat)$coefficients

ci <- confint(model_cat)

format_p <- function(p) {
  
  ifelse(
    p < 0.001,
    "<0.001",
    sprintf("%.3f", p)
  )
  
}

or_table <- data.frame(
  
  Variable = rownames(coef_table),
  
  OR = exp(coef_table[, "Estimate"]),
  
  Lower = exp(ci[, 1]),
  
  Upper = exp(ci[, 2]),
  
  Pvalue = coef_table[, "Pr(>|z|)"],
  
  stringsAsFactors = FALSE
  
)

or_table$OR <- round(or_table$OR, 2)

or_table$Lower <- round(or_table$Lower, 2)

or_table$Upper <- round(or_table$Upper, 2)

or_table$Pvalue <- format_p(or_table$Pvalue)

print(or_table)

write.csv(
  
  or_table,
  
  "output/sensitivity_or_table.csv",
  
  row.names = FALSE
  
)

saveRDS(
  
  model_cat,
  
  "output/logistic_model_categorical.rds"
  
)

# -------------------------------------------------------------
# Compare with continuous model
# -------------------------------------------------------------

model_continuous <-
  
  glm(
    
    cvd ~
      
      hba1c +
      
      age +
      
      sex +
      
      bmi +
      
      smoking +
      
      hypertension,
    
    data = df,
    
    family = binomial
    
  )

cat("\n==============================\n")
cat("Model comparison\n")
cat("==============================\n")

cat(
  
  sprintf(
    
    "Continuous HbA1c model : AIC = %.1f\n",
    
    AIC(model_continuous)
    
  )
  
)

cat(
  
  sprintf(
    
    "Categorical HbA1c model: AIC = %.1f\n",
    
    AIC(model_cat)
    
  )
  
)

# -------------------------------------------------------------
# Forest plot
# -------------------------------------------------------------

plot_df <-
  
  subset(
    
    or_table,
    
    grepl("^hba1c_cat", Variable)
    
  )

plot_df$Label <- c(
  
  "Prediabetes (5.7–6.4%)",
  
  "Diabetes (≥6.5%)"
  
)

reference <- data.frame(
  
  Variable = "Reference",
  
  OR = 1,
  
  Lower = 1,
  
  Upper = 1,
  
  Pvalue = "Reference",
  
  Label = "Normal (<5.7%)",
  
  stringsAsFactors = FALSE
  
)

plot_df <- rbind(reference, plot_df)

plot_df$Label <- factor(
  
  plot_df$Label,
  
  levels = rev(c(
    
    "Normal (<5.7%)",
    
    "Prediabetes (5.7–6.4%)",
    
    "Diabetes (≥6.5%)"
    
  ))
  
)

plot_df$Text <-
  
  ifelse(
    
    plot_df$Variable == "Reference",
    
    "Reference",
    
    sprintf(
      
      "%.2f (%.2f–%.2f)",
      
      plot_df$OR,
      
      plot_df$Lower,
      
      plot_df$Upper
      
    )
    
  )

forest_plot <-
  
  ggplot(
    
    plot_df,
    
    aes(
      
      x = OR,
      
      y = Label
      
    )
    
  ) +
  
  geom_vline(
    
    xintercept = 1,
    
    colour = "grey50",
    
    linetype = "dashed"
    
  ) +
  
  geom_errorbar(
    
    aes(
      
      xmin = Lower,
      
      xmax = Upper
      
    ),
    
    orientation = "y",
    
    height = 0.15,
    
    linewidth = 0.8,
    
    colour = "#4C72B0"
    
  ) +
  
  geom_point(
    
    size = 3,
    
    colour = "#C44E52"
    
  ) +
  
  geom_text(
    
    aes(
      
      x = Upper * 1.15,
      
      label = Text
      
    ),
    
    hjust = 0,
    
    size = 3.5
    
  ) +
  
  scale_x_log10(
    
    breaks = c(
      
      0.5,
      
      1,
      
      1.5,
      
      2,
      
      3,
      
      4
      
    )
    
  ) +
  
  coord_cartesian(
    
    xlim = c(
      
      0.40,
      
      max(plot_df$Upper) * 2
      
    )
    
  ) +
  
  labs(
    
    title = "Sensitivity Analysis",
    
    subtitle = "HbA1c as a categorical predictor",
    
    x = "Odds Ratio (95% Confidence Interval)",
    
    y = NULL
    
  ) +
  
  theme_minimal(base_size = 13) +
  
  theme(
    
    plot.title = element_text(face = "bold"),
    
    panel.grid.minor = element_blank(),
    
    panel.grid.major.y = element_blank()
    
  )

ggsave(
  
  filename = "figures/sensitivity_hba1c_categorical.png",
  
  plot = forest_plot,
  
  width = 8,
  
  height = 4,
  
  dpi = 300
  
)

print(forest_plot)

cat("\nSensitivity analysis completed.\n")

cat("Results saved:\n")

cat("output/sensitivity_or_table.csv\n")

cat("output/logistic_model_categorical.rds\n")

cat("figures/sensitivity_hba1c_categorical.png\n")
