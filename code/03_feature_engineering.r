# ============================================================
# 03_feature_engineering.r
# Project : Soil Moisture Prediction (Irrigation Forecasting)
# Purpose : Create lag features, rolling statistics, temporal
#           features for time series prediction.
# Requires: field1, field2, field3, field4  (02_data_preparation.r)
# Outputs : field1_fe, field2_fe, field3_fe, field4_fe (with features)
# ============================================================

cat("\n========== 03: FEATURE ENGINEERING ==========\n\n")

# ============================================================
# HELPER FUNCTION: CREATE LAG & ROLLING FEATURES
# ============================================================
create_lag_features <- function(data, target_col = "target") {
    data <- data %>% arrange(timestamp)
    n <- nrow(data)

    # Initialize feature matrix
    features <- data.frame(
        id = data$id,
        target = data[[target_col]],
        irrigation = data$irrigation,
        temperature = data$temperature,
        humidity = data$humidity,
        hour = data$hour_of_day,
        day_week = data$day_of_week
    )

    # ──────────────────────────────────────────────────────
    # LAG FEATURES
    # ──────────────────────────────────────────────────────
    for (lag in LAG_WINDOWS) {
        features[[paste0("lag_", lag)]] <- c(
            rep(NA, lag),
            data[[target_col]][1:(n - lag)]
        )
    }

    # Lagged irrigation
    for (lag in LAG_WINDOWS) {
        features[[paste0("lag_irr_", lag)]] <- c(
            rep(NA, lag),
            as.numeric(data$irrigation[1:(n - lag)])
        )
    }

    # ──────────────────────────────────────────────────────
    # ROLLING MEAN
    # ──────────────────────────────────────────────────────
    for (w in ROLLING_WINDOWS) {
        features[[paste0("avg_", w)]] <- RcppRoll::roll_mean(
            data[[target_col]], n = w, fill = NA, align = "right"
        )
    }

    # ──────────────────────────────────────────────────────
    # ROLLING STANDARD DEVIATION
    # ──────────────────────────────────────────────────────
    for (w in ROLLING_WINDOWS) {
        features[[paste0("sd_", w)]] <- RcppRoll::roll_sd(
            data[[target_col]], n = w, fill = NA, align = "right"
        )
    }

    # ──────────────────────────────────────────────────────
    # ROLLING MEDIAN
    # ──────────────────────────────────────────────────────
    for (w in ROLLING_WINDOWS) {
        features[[paste0("med_", w)]] <- zoo::rollmedian(
            data[[target_col]], k = w, fill = NA, align = "right"
        )
    }

    # ──────────────────────────────────────────────────────
    # ROLLING VARIANCE
    # ──────────────────────────────────────────────────────
    for (w in ROLLING_WINDOWS) {
        features[[paste0("var_", w)]] <- RcppRoll::roll_var(
            data[[target_col]], n = w, fill = NA, align = "right"
        )
    }

    # ──────────────────────────────────────────────────────
    # ROLLING MEDIAN IRRIGATION
    # ──────────────────────────────────────────────────────
    for (w in ROLLING_WINDOWS) {
        features[[paste0("med_irr_", w)]] <- zoo::rollmedian(
            as.numeric(data$irrigation), k = w, fill = NA, align = "right"
        )
    }

    # Remove rows with NA in lag_12 (requires 12+ observations)
    valid_idx <- !is.na(features$avg_12)
    features <- features[valid_idx, ]

    features
}

# ============================================================
# CREATE FEATURES FOR EACH FIELD
# ============================================================
cat("Creating lag and rolling features...\n\n")

field1_fe <- create_lag_features(field1)
field2_fe <- create_lag_features(field2)
field3_fe <- create_lag_features(field3)
field4_fe <- create_lag_features(field4)

cat("Features created per field:\n")
cat("  Field 1:", nrow(field1_fe), "rows ×", ncol(field1_fe), "features\n")
cat("  Field 2:", nrow(field2_fe), "rows ×", ncol(field2_fe), "features\n")
cat("  Field 3:", nrow(field3_fe), "rows ×", ncol(field3_fe), "features\n")
cat("  Field 4:", nrow(field4_fe), "rows ×", ncol(field4_fe), "features\n\n")

cat("✓ 03_feature_engineering.r complete\n")
cat("  Objects: field1_fe, field2_fe, field3_fe, field4_fe\n\n")
