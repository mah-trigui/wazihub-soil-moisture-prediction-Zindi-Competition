# ============================================================
# MAIN.r
# Project : Soil Moisture Prediction (Irrigation Forecasting)
# Purpose : Full end-to-end pipeline orchestrator.
#           Run this file to reproduce all results from
#           raw data to final submission CSV.
# ============================================================

cat("╔════════════════════════════════════════════════════════╗\n")
cat("║  SOIL MOISTURE PREDICTION — TIME SERIES FORECASTING   ║\n")
cat("║  Complete ML Pipeline                                 ║\n")
cat("╚════════════════════════════════════════════════════════╝\n\n")

# Locate the pipeline directory
PIPELINE_DIR <- dirname(sys.frame(1)$ofile)
if (!nchar(PIPELINE_DIR)) PIPELINE_DIR <- getwd()  # fallback (interactive)

source_step <- function(file, step_label) {
    cat(strrep("═", 58), "\n")
    cat("  STEP:", step_label, "\n")
    cat(strrep("═", 58), "\n")
    t0 <- proc.time()
    source(file.path(PIPELINE_DIR, file), echo = FALSE)
    elapsed <- (proc.time() - t0)["elapsed"]
    cat("  ↳ Completed in", round(elapsed, 1), "seconds\n\n")
}

# ── 00 Configuration ─────────────────────────────────────
source_step("00_config.r",             "00 · Configuration & libraries")

# ── 01 Data Loading ──────────────────────────────────────
source_step("01_data_loading.r",       "01 · Load raw data & context")

# ── 02 Data Preparation ──────────────────────────────────
source_step("02_data_preparation.r",   "02 · Field-specific data prep")

# ── 03 Feature Engineering ───────────────────────────────
source_step("03_feature_engineering.r", "03 · Create lag & rolling features")

# ── 04 Exploratory Analysis ──────────────────────────────
source_step("04_exploratory_analysis.r", "04 · EDA & visualization")

# ── 05 XGBoost Models ────────────────────────────────────
source_step("05_models_xgboost.r",     "05 · Train XGBoost models")

# ── 06 Neural Network Models (optional) ──────────────────
source_step("06_models_neural_networks.r", "06 · Train neural networks")

# ── 07 Predictions ───────────────────────────────────────
source_step("07_predictions.r",        "07 · Generate test predictions")

# ── 08 Submission ────────────────────────────────────────
source_step("08_submission.r",         "08 · Save submission files")

# ── Done ─────────────────────────────────────────────────
cat("╔════════════════════════════════════════════════════════╗\n")
cat("║                  PIPELINE COMPLETE                    ║\n")
cat("╚════════════════════════════════════════════════════════╝\n\n")
cat("Submissions saved to:", SUBMIT_DIR, "\n\n")
