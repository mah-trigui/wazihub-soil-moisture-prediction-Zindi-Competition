# ============================================================
# 01_data_loading.r
# Project : Soil Moisture Prediction (Irrigation Forecasting)
# Purpose : Load training data, context data, and test files.
# Requires: 00_config.r
# Outputs : df_tot_tot, maize, peanuts, context, test, t1_6d
# ============================================================

cat("\n========== 01: DATA LOADING ==========\n\n")

# ============================================================
# LOAD MAIN TRAINING DATA
# ============================================================
cat("Loading main training dataset...\n")
df_tot_tot <- as.data.frame(read.csv(file.path(DATA_DIR, "Train.csv")))
cat("  ", nrow(df_tot_tot), "rows ×", ncol(df_tot_tot), "columns\n")

# ============================================================
# LOAD CONTEXT DATA
# ============================================================
cat("Loading context data files...\n")
maize <- as.data.frame(read.csv(file.path(DATA_DIR, "Context_Data_Maize.csv")))
peanuts <- as.data.frame(read.csv(file.path(DATA_DIR, "Context_Data_Peanuts.csv")))
context <- as.data.frame(read.csv(file.path(DATA_DIR, "Context_Data.csv")))
cat("  Context: ", nrow(context), "rows | Maize:", nrow(maize),
    "rows | Peanuts:", nrow(peanuts), "rows\n")

# ============================================================
# LOAD TEST DATA
# ============================================================
cat("Loading test datasets...\n")
test <- as.data.frame(read.csv(file.path(DATA_DIR, "test_24.csv"), sep = ";"))
t1_6d <- as.data.frame(read.csv(file.path(DATA_DIR, "t1_6d.csv"), sep = ";"))
cat("  Test (24h):", nrow(test), "rows | Test (6d):", nrow(t1_6d), "rows\n\n")

# ============================================================
# CONVERT DATA TYPES
# ============================================================
cat("Converting data types...\n")

# Irrigation fields as factors
for (irr_field in IRRIGATION_FIELDS) {
    if (irr_field %in% names(df_tot_tot)) {
        df_tot_tot[[irr_field]] <- as.factor(df_tot_tot[[irr_field]])
    }
}

# Parse timestamps
df_tot_tot$time <- ymd_hms(df_tot_tot$timestamp)
if ("timestamp" %in% names(test)) test$time <- ymd_hms(test$timestamp)
if ("timestamp" %in% names(t1_6d)) t1_6d$time <- ymd_hms(t1_6d$timestamp)
if ("Date" %in% names(context)) {
    context$date_real <- lubridate::parse_date_time(
        paste(context$Date, "-2019", sep = ""),
        orders = "d-b-Y",
        locale = "us"
    )
}

cat("✓ Data types converted\n\n")

# ============================================================
# EXTRACT TEMPORAL FEATURES
# ============================================================
cat("Extracting temporal features...\n")

df_tot_tot$month     <- month(df_tot_tot$time)
df_tot_tot$day_year  <- as.numeric(strftime(df_tot_tot$timestamp, format = "%j"))
df_tot_tot$hour      <- hour(df_tot_tot$time)
df_tot_tot$minutes   <- hour(df_tot_tot$time) * 60 + minute(df_tot_tot$time)

if (!is.null(context$date_real)) {
    context$day_year <- as.numeric(strftime(context$date_real, format = "%j"))
}

cat("✓ 01_data_loading.r complete\n")
cat("  Objects: df_tot_tot, test, t1_6d, context, maize, peanuts\n\n")
