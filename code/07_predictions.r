# ============================================================
# 07_predictions.r
# Project : Soil Moisture Prediction (Irrigation Forecasting)
# Purpose : Generate predictions on test set using trained
#           XGBoost models, prepare submission.
# Requires: xgb_models, test, t1_6d
# Outputs : predictions_df, test_predictions
# ============================================================

cat("\n========== 07: PREDICTIONS ==========\n\n")

# ============================================================
# HELPER FUNCTION: PREDICT ON TEST SET
# ============================================================
predict_xgb_test <- function(model_obj, test_data, field_abbr) {
    cat("  Predicting for", field_abbr, "...\n")

    feature_cols <- model_obj$features

    # Prepare test data
    X_test <- as.matrix(test_data[, feature_cols])
    X_test[is.na(X_test)] <- 0

    # Create DMatrix
    dtest <- xgb.DMatrix(data = X_test)

    # Predict
    predictions <- predict(model_obj$model, dtest)

    predictions
}

# ============================================================
# GENERATE PREDICTIONS
# ============================================================
cat("Generating predictions for test set...\n\n")

test_predictions <- list()

for (i in 1:4) {
    abbr <- FIELD_ABBR[i]
    field_name <- FIELD_NAMES[i]

    # Use appropriate test data (here using 'test' by default)
    # Could switch to 't1_6d' for 6-day forecast
    test_to_use <- test

    cat("Field", i, ":\n")
    pred <- tryCatch({
        predict_xgb_test(xgb_models[[abbr]], test_to_use, field_name)
    }, error = function(e) {
        cat("    ✗ Prediction failed:", e$message, "\n")
        rep(NA, nrow(test_to_use))
    })

    test_predictions[[abbr]] <- pred
}

cat("\n")

# ============================================================
# CREATE SUBMISSION DATAFRAME
# ============================================================
cat("Creating submission dataframe...\n")

if ("timestamp" %in% names(test)) {
    predictions_df <- data.frame(
        timestamp = test$timestamp,
        field1_pred = test_predictions$F1,
        field2_pred = test_predictions$F2,
        field3_pred = test_predictions$F3,
        field4_pred = test_predictions$F4,
        stringsAsFactors = FALSE
    )
} else {
    predictions_df <- data.frame(
        row_id = 1:nrow(test),
        field1_pred = test_predictions$F1,
        field2_pred = test_predictions$F2,
        field3_pred = test_predictions$F3,
        field4_pred = test_predictions$F4,
        stringsAsFactors = FALSE
    )
}

cat("  Predictions shape:", nrow(predictions_df), "×", ncol(predictions_df), "\n")
cat("  Preview:\n")
print(head(predictions_df, 5))
cat("\n")

cat("✓ 07_predictions.r complete\n")
cat("  Objects: predictions_df, test_predictions\n\n")
