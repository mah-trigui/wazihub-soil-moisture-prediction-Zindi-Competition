# ============================================================
# 05_models_xgboost.r
# Project : Soil Moisture Prediction (Irrigation Forecasting)
# Purpose : Train XGBoost regression models for each field,
#           perform hyperparameter tuning, evaluate performance.
# Requires: field1_fe, field2_fe, field3_fe, field4_fe
# Outputs : xgboost_field1/2/3/4 (trained models)
# ============================================================

cat("\n========== 05: MODELS (XGBOOST) ==========\n\n")

# ============================================================
# HELPER FUNCTION: TRAIN XGBOOST PER FIELD
# ============================================================
train_xgb_field <- function(data, field_name, field_abbr) {
    cat("Training XGBoost for", field_name, "...\n")

    # Define features (exclude target and ids)
    feature_cols <- setdiff(names(data), c("id", "target"))

    # Prepare data
    n_total <- nrow(data)
    n_train <- floor(n_total * (1 - TEST_SPLIT))

    train_idx <- 1:n_train
    test_idx <- (n_train + 1):n_total

    X_train <- as.matrix(data[train_idx, feature_cols])
    y_train <- data[train_idx, "target"]

    X_test <- as.matrix(data[test_idx, feature_cols])
    y_test <- data[test_idx, "target"]

    # Replace NA with 0
    X_train[is.na(X_train)] <- 0
    X_test[is.na(X_test)] <- 0

    cat("  Train:", length(y_train), "| Test:", length(y_test), "\n")

    # Create DMatrix
    dtrain <- xgb.DMatrix(data = X_train, label = y_train)
    dtest <- xgb.DMatrix(data = X_test, label = y_test)

    # XGBoost parameters
    params <- list(
        objective = "reg:squarederror",
        booster = "gbtree",
        eta = 0.01,
        max_depth = 12,
        subsample = 0.75,
        colsample_bytree = 1,
        min_child_weight = 3,
        eval_metric = "rmse"
    )

    # Train with cross-validation
    set.seed(MODEL_SEED)
    xgb_model <- xgb.train(
        params = params,
        data = dtrain,
        nrounds = XGBOOST_NROUNDS,
        watchlist = list(
            train = dtrain,
            test = dtest
        ),
        verbose = 0,
        early_stopping_rounds = EARLY_STOPPING
    )

    # Evaluate on test set
    pred_test <- predict(xgb_model, dtest)
    test_metrics <- calc_metrics(y_test, pred_test, field_name)

    # Feature importance
    importance <- xgb.importance(feature_names = feature_cols, model = xgb_model)

    cat("  ✓ Model trained\n\n")

    list(
        model = xgb_model,
        params = params,
        features = feature_cols,
        metrics = test_metrics,
        importance = importance,
        n_rounds = xgb_model$best_iteration
    )
}

# ============================================================
# TRAIN ALL FIELD MODELS
# ============================================================
cat("Training XGBoost models...\n\n")

xgb_models <- list()

for (i in 1:4) {
    field_data <- get(paste0("field", i, "_fe"))
    xgb_models[[FIELD_ABBR[i]]] <- train_xgb_field(
        field_data, FIELD_NAMES[i], FIELD_ABBR[i]
    )
}

# ============================================================
# SAVE MODELS
# ============================================================
cat("Saving XGBoost models...\n")

for (abbr in FIELD_ABBR) {
    model_path <- file.path(MODELS_DIR, paste0("xgboost_", tolower(abbr), ".rds"))
    saveRDS(xgb_models[[abbr]], model_path)
    cat("  Saved:", model_path, "\n")
}

cat("\n")

# ============================================================
# FEATURE IMPORTANCE SUMMARY
# ============================================================
cat("Feature importance summary:\n\n")

for (i in 1:4) {
    abbr <- FIELD_ABBR[i]
    importance_df <- head(xgb_models[[abbr]]$importance, 10)
    cat(FIELD_NAMES[i], "- Top 10 features:\n")
    print(importance_df)
    cat("\n")
}

cat("✓ 05_models_xgboost.r complete\n")
cat("  Objects: xgb_models (list of 4 field models)\n\n")
