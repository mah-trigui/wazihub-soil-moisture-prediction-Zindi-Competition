# ============================================================
# 00_config.r
# Project : Soil Moisture Prediction (Irrigation Forecasting)
# Purpose : Load all libraries, set paths, seeds, constants,
#           and utility functions used throughout the pipeline.
# ============================================================

cat("\n========== 00: CONFIGURATION ==========\n\n")

# ============================================================
# DIRECTORIES & FILE PATHS
# ============================================================
DATA_DIR     <- "."              # CSV files (Train.csv, test_24.csv, context files)
MODELS_DIR   <- "./models"       # Save trained models
PLOTS_DIR    <- "./plots"        # Save visualizations
SUBMIT_DIR   <- "./submissions"  # Output submission CSV

for (dir in c(MODELS_DIR, PLOTS_DIR, SUBMIT_DIR)) {
    if (!dir.exists(dir)) dir.create(dir, showWarnings = FALSE)
}

# ============================================================
# SEEDS & RANDOMIZATION
# ============================================================
PRIMARY_SEED <- 123
MODEL_SEED   <- 45
set.seed(PRIMARY_SEED)

# ============================================================
# DISPLAY OPTIONS
# ============================================================
options(scipen = 999, digits = 10)

# ============================================================
# LIBRARIES — CORE DATA MANIPULATION
# ============================================================
library(data.table)
library(dplyr)
library(tidyverse)
library(here)

# ============================================================
# LIBRARIES — DATE & TIME HANDLING
# ============================================================
library(lubridate)

# ============================================================
# LIBRARIES — TIME SERIES ANALYSIS
# ============================================================
library(xts)
library(forecast)
library(tseries)
library(timetk)
library(tidyquant)
library(TTR)

# ============================================================
# LIBRARIES — MACHINE LEARNING
# ============================================================
library(xgboost)
library(Matrix)
library(caret)
library(recipes)

# ============================================================
# LIBRARIES — NEURAL NETWORKS (optional)
# ============================================================
tryCatch({
    library(keras)
    library(tensorflow)
}, error = function(e) {
    cat("⚠ Keras/TensorFlow not available (neural networks skipped)\n")
})

# ============================================================
# LIBRARIES — VISUALIZATION
# ============================================================
library(ggplot2)
library(gridExtra)
library(corrplot)
library(GGally)
library(cowplot)

# ============================================================
# LIBRARIES — UTILITIES
# ============================================================
library(RcppRoll)
library(doParallel)

# Detect cores for parallel processing
n_cores <- parallel::detectCores() - 1
registerDoParallel(cores = n_cores)

# ============================================================
# GLOBAL CONSTANTS
# ============================================================
FIELDS            <- c("Soil.humidity.1", "Soil.humidity.2",
                       "Soil.humidity.3", "Soil.humidity.4")
FIELD_NAMES       <- c("Field 1", "Field 2", "Field 3", "Field 4")
FIELD_ABBR        <- c("F1", "F2", "F3", "F4")
IRRIGATION_FIELDS <- c("Irrigation.field.1", "Irrigation.field.2",
                       "Irrigation.field.3", "Irrigation.field.4")
LAG_WINDOWS       <- c(1, 3, 6, 12)  # Hours
ROLLING_WINDOWS   <- c(3, 6, 12)     # Hours
TEST_SPLIT        <- 0.2
CV_FOLDS          <- 2
XGBOOST_NROUNDS   <- 3000
EARLY_STOPPING    <- 10

# ============================================================
# UTILITY FUNCTIONS
# ============================================================

# Calculate regression metrics
calc_metrics <- function(actual, predicted, name = "Model") {
    rmse <- sqrt(mean((actual - predicted)^2, na.rm = TRUE))
    mae  <- mean(abs(actual - predicted), na.rm = TRUE)

    cat(sprintf("  %s | RMSE: %.4f | MAE: %.4f\n", name, rmse, mae))
    list(rmse = rmse, mae = mae)
}

# Safe model training wrapper
safe_train <- function(expr, model_name) {
    tryCatch(expr,
        error = function(e) {
            cat("✗", model_name, ":", e$message, "\n")
            NULL
        }
    )
}

cat("✓ 00_config.r complete\n")
cat("  Libraries loaded, paths configured, seeds set\n\n")
