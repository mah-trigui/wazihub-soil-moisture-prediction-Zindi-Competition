# ============================================================
# 04_exploratory_analysis.r
# Project : Soil Moisture Prediction (Irrigation Forecasting)
# Purpose : Visualize data distributions, correlations,
#           temporal patterns, and field-specific insights.
# Requires: field1_fe, field2_fe, field3_fe, field4_fe
# Outputs : Visualization files in PLOTS_DIR
# ============================================================

cat("\n========== 04: EXPLORATORY ANALYSIS ==========\n\n")

# ============================================================
# CORRELATION ANALYSIS
# ============================================================
cat("Generating correlation matrices...\n")

for (i in 1:4) {
    field_data <- get(paste0("field", i, "_fe"))

    # Select numeric columns
    numeric_cols <- sapply(field_data, is.numeric)
    corr_matrix <- cor(field_data[, numeric_cols], use = "complete.obs")

    # Plot correlation heatmap
    png(file.path(PLOTS_DIR, paste0("correlation_field", i, ".png")),
        width = 800, height = 800)
    corrplot(corr_matrix, method = "circle", type = "lower",
             main = paste("Feature Correlations -", FIELD_NAMES[i]))
    dev.off()

    cat("  Field", i, "correlation plot saved\n")
}

cat("\n")

# ============================================================
# TEMPORAL PATTERNS
# ============================================================
cat("Generating temporal pattern plots...\n")

for (i in 1:4) {
    field_data <- get(paste0("field", i, "_fe"))

    # Time series plot
    p_ts <- ggplot(field_data, aes(x = row_number(), y = target)) +
        geom_line(alpha = 0.7, color = "steelblue") +
        labs(title = paste("Soil Moisture Time Series -", FIELD_NAMES[i]),
             x = "Observation", y = "Soil Moisture") +
        theme_minimal()

    ggsave(file.path(PLOTS_DIR, paste0("timeseries_field", i, ".png")),
           p_ts, width = 10, height = 5)

    cat("  Field", i, "time series plot saved\n")
}

cat("\n")

# ============================================================
# HOURLY PATTERNS
# ============================================================
cat("Generating hourly pattern plots...\n")

for (i in 1:4) {
    field_data <- get(paste0("field", i, "_fe"))

    # Hourly average
    hourly_avg <- field_data %>%
        group_by(hour) %>%
        summarise(mean_target = mean(target, na.rm = TRUE),
                  .groups = "drop")

    p_hourly <- ggplot(hourly_avg, aes(x = hour, y = mean_target)) +
        geom_line(color = "steelblue", size = 1) +
        geom_point(size = 3) +
        labs(title = paste("Average Hourly Soil Moisture -", FIELD_NAMES[i]),
             x = "Hour of Day", y = "Average Soil Moisture") +
        scale_x_continuous(breaks = 0:23) +
        theme_minimal()

    ggsave(file.path(PLOTS_DIR, paste0("hourly_pattern_field", i, ".png")),
           p_hourly, width = 10, height = 5)

    cat("  Field", i, "hourly pattern plot saved\n")
}

cat("\n")

# ============================================================
# SUMMARY STATISTICS
# ============================================================
cat("Summary statistics by field:\n\n")

for (i in 1:4) {
    field_data <- get(paste0("field", i, "_fe"))
    cat(FIELD_NAMES[i], ":\n")
    print(summary(field_data$target))
    cat("\n")
}

cat("✓ 04_exploratory_analysis.r complete\n")
cat("  Plots saved to", PLOTS_DIR, "\n\n")
