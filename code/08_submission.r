# ============================================================
# 08_submission.r
# Project : Soil Moisture Prediction (Irrigation Forecasting)
# Purpose : Save predictions in competition-required format.
# Requires: predictions_df, test_predictions
# Outputs : submission CSV files in SUBMIT_DIR
# ============================================================

cat("\n========== 08: SUBMISSION ==========\n\n")

# ============================================================
# SAVE PREDICTIONS BY FIELD
# ============================================================
cat("Saving field-specific predictions...\n")

field_names_full <- c(
    "Soil.humidity.1", "Soil.humidity.2",
    "Soil.humidity.3", "Soil.humidity.4"
)

submission_files <- list()

for (i in 1:4) {
    abbr <- FIELD_ABBR[i]
    field_full <- field_names_full[i]

    # Create field-specific submission
    field_submission <- data.frame(
        id = paste(field_full, rownames(test), sep = "_"),
        timestamp = if ("timestamp" %in% names(test)) test$timestamp
                    else paste("row", 1:nrow(test), sep = "_"),
        prediction = test_predictions[[abbr]],
        stringsAsFactors = FALSE
    )

    # Save
    file_name <- paste0("submission_", tolower(abbr), ".csv")
    file_path <- file.path(SUBMIT_DIR, file_name)
    write.csv(field_submission, file_path, row.names = FALSE)

    submission_files[[abbr]] <- field_submission
    cat("  Saved:", file_name, "(", nrow(field_submission), "rows )\n")
}

cat("\n")

# ============================================================
# CREATE COMBINED SUBMISSION
# ============================================================
cat("Creating combined submission...\n")

combined_submission <- data.frame(
    field = rep(FIELD_ABBR, each = nrow(test)),
    timestamp = rep(if ("timestamp" %in% names(test)) test$timestamp
                    else paste("row", 1:nrow(test), sep = "_"),
                    times = 4),
    prediction = c(test_predictions$F1,
                   test_predictions$F2,
                   test_predictions$F3,
                   test_predictions$F4),
    stringsAsFactors = FALSE
)

# Sort by field and timestamp
combined_submission <- combined_submission %>%
    arrange(field, timestamp)

# Save combined
file_path_combined <- file.path(SUBMIT_DIR, "submission_combined.csv")
write.csv(combined_submission, file_path_combined, row.names = FALSE)

cat("  Saved: submission_combined.csv (", nrow(combined_submission), "rows )\n\n")

# ============================================================
# SAVE MODEL PERFORMANCE SUMMARY
# ============================================================
cat("Saving model performance summary...\n")

performance_summary <- data.frame(
    field = FIELD_ABBR,
    field_name = FIELD_NAMES,
    n_train_obs = sapply(1:4, function(i) nrow(get(paste0("field", i, "_fe")))),
    rmse = sapply(1:4, function(i) xgb_models[[FIELD_ABBR[i]]]$metrics$rmse),
    mae = sapply(1:4, function(i) xgb_models[[FIELD_ABBR[i]]]$metrics$mae),
    best_rounds = sapply(1:4, function(i) xgb_models[[FIELD_ABBR[i]]]$n_rounds),
    stringsAsFactors = FALSE
)

perf_file <- file.path(SUBMIT_DIR, "model_performance_summary.csv")
write.csv(performance_summary, perf_file, row.names = FALSE)

cat("  Saved: model_performance_summary.csv\n\n")
print(performance_summary)
cat("\n")

# ============================================================
# SUMMARY
# ============================================================
cat("✓ 08_submission.r complete\n")
cat("  Files saved to:", SUBMIT_DIR, "\n")
cat("    - submission_f1.csv, submission_f2.csv, etc.\n")
cat("    - submission_combined.csv\n")
cat("    - model_performance_summary.csv\n\n")
