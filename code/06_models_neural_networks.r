# ============================================================
# 06_models_neural_networks.r
# Project : Soil Moisture Prediction (Irrigation Forecasting)
# Purpose : Train neural network models (GRU, LSTM, NNETAR)
#           as alternative to XGBoost.
# Requires: field1_fe, field2_fe, field3_fe, field4_fe
# Outputs : nn_models (optional, if Keras available)
# ============================================================

cat("\n========== 06: MODELS (NEURAL NETWORKS) ==========\n\n")

# ============================================================
# CHECK KERAS AVAILABILITY
# ============================================================
keras_available <- tryCatch({
    library(keras)
    TRUE
}, error = function(e) FALSE)

if (!keras_available) {
    cat("⚠ Keras/TensorFlow not installed.\n")
    cat("  To enable neural network models, run:\n")
    cat("    install.packages('keras')\n")
    cat("    keras::install_keras()\n\n")
    cat("✓ 06_models_neural_networks.r skipped (Keras unavailable)\n\n")
} else {

    # ========================================================
    # HELPER FUNCTION: PREPARE DATA FOR NEURAL NETWORKS
    # ========================================================
    prepare_nn_data <- function(data, lookback = 288, step = 12) {
        cat("    Preparing sequences (lookback=", lookback, ", step=",
            step, ")...\n", sep = "")

        target_values <- data$target
        n <- length(target_values)

        # Normalize
        mean_val <- mean(target_values, na.rm = TRUE)
        std_val <- sd(target_values, na.rm = TRUE)
        target_norm <- (target_values - mean_val) / std_val

        # Create sequences
        X <- list()
        y <- list()

        for (i in seq(1, n - lookback - step, by = step)) {
            X[[length(X) + 1]] <- target_norm[i:(i + lookback - 1)]
            y[[length(y) + 1]] <- target_norm[i + lookback + step - 1]
        }

        list(
            X = array(unlist(X), dim = c(length(X), lookback, 1)),
            y = array(unlist(y), dim = c(length(y), 1)),
            mean = mean_val,
            std = std_val
        )
    }

    # ========================================================
    # TRAIN GRU MODEL (per field)
    # ========================================================
    train_gru_field <- function(data, field_name) {
        cat("  Training GRU for", field_name, "...\n")

        # Prepare data
        nn_data <- prepare_nn_data(data)

        # Split train/val
        n_total <- dim(nn_data$X)[1]
        n_train <- floor(n_total * 0.7)

        X_train <- nn_data$X[1:n_train, , ]
        y_train <- nn_data$y[1:n_train, ]
        X_val <- nn_data$X[(n_train + 1):n_total, , ]
        y_val <- nn_data$y[(n_train + 1):n_total, ]

        # Build GRU model
        model <- keras_model_sequential() %>%
            layer_gru(units = 32, input_shape = list(288, 1)) %>%
            layer_dropout(rate = 0.2) %>%
            layer_dense(units = 1)

        model %>% compile(
            optimizer = optimizer_rmsprop(),
            loss = "mae"
        )

        # Train
        set.seed(MODEL_SEED)
        history <- model %>% fit(
            X_train, y_train,
            batch_size = 128,
            epochs = 20,
            validation_data = list(X_val, y_val),
            verbose = 0
        )

        cat("    ✓ GRU trained\n")
        list(model = model, history = history, nn_data = nn_data)
    }

    # ========================================================
    # TRAIN NNETAR MODEL (from forecast package)
    # ========================================================
    train_nnetar_field <- function(data, field_name) {
        cat("  Training NNETAR for", field_name, "...\n")

        # Convert to time series
        ts_data <- ts(data$target, frequency = 24)  # Hourly data

        # Train NNETAR
        tryCatch({
            set.seed(MODEL_SEED)
            nnetar_model <- forecast::nnetar(ts_data, p = 12, P = 1,
                                            size = 10, repeats = 10,
                                            maxit = 1000, trace = FALSE)
            cat("    ✓ NNETAR trained\n")
            nnetar_model
        }, error = function(e) {
            cat("    ✗ NNETAR failed:", e$message, "\n")
            NULL
        })
    }

    # ========================================================
    # TRAIN ALL NEURAL NETWORK MODELS
    # ========================================================
    nn_models <- list()

    for (i in 1:4) {
        field_data <- get(paste0("field", i, "_fe"))

        tryCatch({
            nn_models[[FIELD_ABBR[i]]] <- train_gru_field(
                field_data, FIELD_NAMES[i]
            )
        }, error = function(e) {
            cat("  ✗ GRU training failed for Field", i, "\n")
        })
    }

    cat("\n✓ 06_models_neural_networks.r complete\n")
    cat("  Objects: nn_models (list of GRU models)\n\n")
}
