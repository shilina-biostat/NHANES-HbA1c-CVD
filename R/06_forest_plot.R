# =============================================================
# 06_forest_plot.R
# Forest plot of adjusted Odds Ratios (95% CI)
#
# Model:
# CVD ~ HbA1c + age + sex + BMI + smoking + hypertension
#
# NHANES 2017–2018
# =============================================================

library(ggplot2)

dir.create("figures", showWarnings = FALSE)

# -------------------------------------------------------------
# Load logistic regression results
# -------------------------------------------------------------

or_table <- read.csv(
  "output/logistic_or_table.csv",
  stringsAsFactors = FALSE,
  check.names = FALSE
)

# Rename columns
names(or_table) <- c(
  "Variable",
  "OR",
  "Lower",
  "Upper",
  "Pvalue"
)

# -------------------------------------------------------------
# Remove intercept
# -------------------------------------------------------------

plot_df <- subset(
  or_table,
  Variable != "(Intercept)"
)

# -------------------------------------------------------------
# Variable labels
# -------------------------------------------------------------

label_map <- c(
  
  hba1c           = "HbA1c (per 1% increase)",
  age             = "Age (per year)",
  sexFemale       = "Female (vs Male)",
  bmi             = "BMI (per 1 kg/m²)",
  smokingFormer   = "Former smoker (vs Never)",
  smokingCurrent  = "Current smoker (vs Never)",
  hypertensionYes = "Hypertension (Yes vs No)"
  
)

plot_df$Label <- label_map[plot_df$Variable]

# -------------------------------------------------------------
# Order variables by Odds Ratio
# -------------------------------------------------------------

plot_df <- plot_df[order(plot_df$OR), ]

plot_df$Label <- factor(
  plot_df$Label,
  levels = plot_df$Label
)

# -------------------------------------------------------------
# Text labels
# -------------------------------------------------------------

plot_df$Text <- sprintf(
  "%.2f (%.2f–%.2f)",
  plot_df$OR,
  plot_df$Lower,
  plot_df$Upper
)

# -------------------------------------------------------------
# Forest plot
# -------------------------------------------------------------

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
    linetype = "dashed",
    colour = "grey50"
  ) +
  
  geom_errorbar(
    
    aes(
      xmin = Lower,
      xmax = Upper
    ),
    
    orientation = "y",
    height = 0.20,
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
      0.75,
      1,
      1.5,
      2,
      3
    )
    
  ) +
  
  coord_cartesian(
    
    xlim = c(
      min(plot_df$Lower) * 0.8,
      max(plot_df$Upper) * 2.2
    )
    
  ) +
  
  labs(
    
    title = "Adjusted Odds Ratios for Cardiovascular Disease",
    
    subtitle =
      "Multivariable logistic regression | NHANES 2017–2018",
    
    x = "Odds Ratio (95% Confidence Interval)",
    
    y = NULL
    
  ) +
  
  theme_minimal(base_size = 13) +
  
  theme(
    
    plot.title = element_text(face = "bold"),
    
    panel.grid.minor = element_blank(),
    
    panel.grid.major.y = element_blank()
    
  )

# -------------------------------------------------------------
# Save figure
# -------------------------------------------------------------

ggsave(
  
  filename = "figures/forest_plot.png",
  
  plot = forest_plot,
  
  width = 9,
  
  height = 5,
  
  dpi = 300
  
)

print(forest_plot)

cat("\nForest plot saved:\n")
cat("figures/forest_plot.png\n")
