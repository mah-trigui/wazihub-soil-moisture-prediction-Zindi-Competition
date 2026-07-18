# ============================================================
# 02_data_preparation.r
# Project : Soil Moisture Prediction (Irrigation Forecasting)
# Purpose : Clean data, split by field, handle time gaps,
#           add derived features.
# Requires: df_tot_tot  (01_data_loading.r)
# Outputs : field1, field2, field3, field4 (clean per-field data)
# ============================================================

cat("\n========== 02: DATA PREPARATION ==========\n\n")

# ============================================================
# HELPER FUNCTION: CLEAN TIME GAPS
# ============================================================
clean_time_gaps <- function(data) {
    data <- data %>% arrange(timestamp)

    # Check for continuous hourly timestamps
    time_diff <- diff(as.numeric(data$time), units = "hours")
    valid_idx <- c(TRUE, time_diff <= 1.5)  # Allow up to 1.5 hours gap

    data[valid_idx, ]
}

# ============================================================
# HELPER FUNCTION: ADD DERIVED FEATURES
# ============================================================
add_derived_features <- function(data) {
    data <- data %>%
        mutate(
            id = row_number(),
            hour_of_day = hour(time),
            day_of_week = wday(time)
        )
    data
}

# ============================================================
# SPLIT DATA BY FIELD
# ============================================================
cat("Splitting data by field...\n")

# Initialize field datasets
field_data <- list()

for (i in 1:4) {
    field_col <- FIELDS[i]
    irr_col   <- IRRIGATION_FIELDS[i]

    cat("  Processing", FIELD_NAMES[i], "...\n")

    # Filter to non-NA observations
    field_df <- df_tot_tot %>%
        filter(!is.na(.data[[field_col]])) %>%
        select(timestamp, time, all_of(field_col), all_of(irr_col),
               Air.temperature..C., Air.humidity....,
               month, day_year, hour, minutes)

    # Rename columns for consistency
    names(field_df)[names(field_df) == field_col] <- "target"
    names(field_df)[names(field_df) == irr_col] <- "irrigation"
    names(field_df)[names(field_df) == "Air.temperature..C."] <- "temperature"
    names(field_df)[names(field_df) == "Air.humidity...."] <- "humidity"

    # Clean time gaps
    field_df <- clean_time_gaps(field_df)

    # Add derived features
    field_df <- add_derived_features(field_df)

    field_data[[FIELD_ABBR[i]]] <- field_df

    cat("    ", nrow(field_df), "valid observations\n")
}

cat("\n✓ Field data summary:\n")
for (abbr in FIELD_ABBR) {
    cat("  ", abbr, ":", nrow(field_data[[abbr]]), "rows\n")
}

# Assign to global environment
field1 <- field_data$F1
field2 <- field_data$F2
field3 <- field_data$F3
field4 <- field_data$F4

cat("\n✓ 02_data_preparation.r complete\n")
cat("  Objects: field1, field2, field3, field4\n\n")
