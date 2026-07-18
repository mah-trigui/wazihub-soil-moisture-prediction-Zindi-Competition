# Soil Moisture Prediction — Time Series Forecasting Pipeline

This competition is hosted on Zindi, a machine learning platform for data science challenges.  
Here is the link to the competition: [Wazihub Soil Moisture Prediction 🌾 - $8 000 USD](https://zindi.africa/competitions/wazihub-soil-moisture-prediction-challenge)

Ranked in the TOP 40%
---

Zindi competition · Irrigation field monitoring · Hourly soil humidity forecasting.

---

## Competition Overview

| Item | Details |
|---|---|
| Task | Predict **hourly soil moisture levels** for 4 irrigation fields |
| Target Variables | `Soil.humidity.1` through `Soil.humidity.4` (% moisture) |
| Data | Hourly time series observations with environmental & irrigation context |
| Horizon | 24-hour and 6-day forecasts |
| Metric | RMSE (Root Mean Squared Error) and MAE (Mean Absolute Error) |
| Models | XGBoost (primary), Neural Networks (GRU/LSTM, optional) |
| Submission | CSV with predictions per field and timestamp |

---

## Dataset

| File | Rows | Purpose |
|---|---|---|
| `Train.csv` | ~30,000+ | Main training data (hourly observations) |
| `Context_Data.csv` | Historical | Seasonal/temporal context |
| `Context_Data_Maize.csv` | - | Crop-specific (Maize) context |
| `Context_Data_Peanuts.csv` | - | Crop-specific (Peanuts) context |
| `test_24.csv` | ~100 | Test set for 24-hour forecast |
| `t1_6d.csv` | ~150 | Test set for 6-day forecast |

**Key Features:**
- **Timestamps:** UTC datetime, hourly frequency
- **Environmental:** Air temperature (°C), air humidity (%)
- **Irrigation:** Binary irrigation status (0/1) per field
- **Soil moisture:** Target variable (% moisture)

**Data by Field:**
| Field | Train Observations | Characteristics |
|---|---|---|
| Field 1 | ~8,914 | Primary irrigated field |
| Field 2 | ~1,747 | Secondary field |
| Field 3 | ~1,153 | Sparse observations |
| Field 4 | ~1,729 | Medium coverage |

---

## Pipeline Structure

```
pipeline_soil/
├── 00_config.r                    # Configuration, libraries, paths, utilities
├── 01_data_loading.r              # Load Train.csv, context files, test sets
├── 02_data_preparation.r          # Split by field, clean time gaps, derive features
├── 03_feature_engineering.r       # Create lag, rolling stats, temporal features
├── 04_exploratory_analysis.r      # EDA plots, correlations, hourly patterns
├── 05_models_xgboost.r            # Train XGBoost regressors per field
├── 06_models_neural_networks.r    # Train GRU/LSTM models (optional, if Keras available)
├── 07_predictions.r               # Generate test predictions
├── 08_submission.r                # Format and save submission CSVs
├── MAIN.r                         # Orchestration — run this for full pipeline
└── README.md                      # This file
```

---

## Quick Start

```r
# Run the full pipeline
setwd("path/to/pipeline_soil")
source("MAIN.r")
```

Outputs are saved to `./submissions/`:
- `submission_f1.csv`, `submission_f2.csv`, `submission_f3.csv`, `submission_f4.csv`
- `submission_combined.csv` (all fields, sorted by field/timestamp)
- `model_performance_summary.csv` (RMSE, MAE per field)

---

## Pipeline Stages

### **00 — Configuration** (`00_config.r`)
- Load all ML/TS libraries (dplyr, xgboost, forecast, keras, ggplot2, etc.)
- Set paths: `DATA_DIR="."`, `MODELS_DIR="./models"`, `SUBMIT_DIR="./submissions"`
- Define constants: `FIELDS`, `LAG_WINDOWS=[1,3,6,12]`, `ROLLING_WINDOWS=[3,6,12]`
- Register parallel processing (detectCores - 1)

### **01 — Data Loading** (`01_data_loading.r`)
- Load `Train.csv` → `df_tot_tot` (all fields combined)
- Load context files: `context`, `maize`, `peanuts`
- Load test sets: `test` (24h), `t1_6d` (6d)
- Parse timestamps to datetime, extract month/day_year/hour/minutes

### **02 — Data Preparation** (`02_data_preparation.r`)
- Split by field: `field1`, `field2`, `field3`, `field4`
- Clean time gaps (remove discontinuous observations)
- Add derived features: id, hour_of_day, day_of_week
- Remove rows with NA in target variable

### **03 — Feature Engineering** (`03_feature_engineering.r`)
Create lag-based + rolling statistics features:

**Lag Features:**
- `lag_1`, `lag_3`, `lag_6`, `lag_12` (past soil moisture)
- `lag_irr_1`, `lag_irr_3`, `lag_irr_6` (irrigation status lags)

**Rolling Windows (3, 6, 12 hours):**
- `avg_3/6/12` — Rolling mean
- `sd_3/6/12` — Rolling std dev
- `med_3/6/12` — Rolling median
- `var_3/6/12` — Rolling variance
- `med_irr_3/6/12` — Rolling median irrigation

**Total features per field:** 25+

### **04 — Exploratory Analysis** (`04_exploratory_analysis.r`)
- Correlation heatmaps (feature-feature, feature-target)
- Time series plots (full series visualization)
- Hourly patterns (average moisture by hour-of-day)
- Summary statistics per field
- Plots saved to `./plots/`

### **05 — XGBoost Models** (`05_models_xgboost.r`)
Train one XGBoost regressor per field:

**Configuration:**
- Objective: `reg:squarederror`
- Hyperparameters:
  - learning_rate (eta): 0.01
  - max_depth: 12
  - subsample: 0.75
  - min_child_weight: 3
- Cross-validation: 2-fold
- Training: 80/20 train/test split
- Early stopping: 10 rounds without improvement
- Max rounds: 3,000

**Outputs:**
- Models saved as `.rds` in `./models/`
- Feature importance rankings
- RMSE/MAE on test set

### **06 — Neural Networks** (`06_models_neural_networks.r`)
Train alternative NN models (if Keras installed):

**GRU Architecture:**
- Input: 288-step lookback window (12 hours)
- GRU layer: 32 units
- Dropout: 0.2
- Output: Single neuron (regression)
- Optimizer: RMSprop
- Loss: MAE

**NNETAR (forecast package):**
- AutoRegressive neural network
- p=12 lags, P=1 seasonal
- size=10 hidden units
- 10 training repeats

### **07 — Predictions** (`07_predictions.r`)
- Load trained XGBoost models per field
- Prepare test data with engineered features
- Generate predictions on `test` (24h) or `t1_6d` (6d)
- Combine into `predictions_df`

### **08 — Submission** (`08_submission.r`)
- Save per-field predictions: `submission_f1/2/3/4.csv`
- Create combined file: `submission_combined.csv`
- Save performance summary: `model_performance_summary.csv`
- Format: `id`, `timestamp`, `prediction` (or alternative per competition)

---

## Key Design Decisions

### Feature Engineering
- **Lag windows:** 1, 3, 6, 12 hours (capture immediate & medium-term patterns)
- **Rolling windows:** 3, 6, 12 hours (smooth trends & capture volatility)
- **Removal:** Rows with NA in lag_12 (requires ≥12 historical observations)

### XGBoost Hyperparameters
- **Low learning rate (0.01):** Improve generalization
- **Deep trees (max_depth=12):** Capture complex TS patterns
- **Early stopping:** Prevent overfitting (10 rounds patience)
- **Train/test split:** 80/20 chronological (respect temporal order)

### Validation Strategy
- **Chronological split:** No data leakage from future to past
- **Per-field models:** Account for field-specific irrigation & soil properties
- **Cross-validation:** 2-fold CV within training set for stability

---

## Submission Format

### Individual Field Submission:
```
id                                   | timestamp | prediction
Soil.humidity.1_row_1                | 2019-01-01 12:00:00 | 45.3
Soil.humidity.1_row_2                | 2019-01-01 13:00:00 | 44.8
...
```

### Combined Submission:
```
field | timestamp           | prediction
F1    | 2019-01-01 12:00:00 | 45.3
F1    | 2019-01-01 13:00:00 | 44.8
F2    | 2019-01-01 12:00:00 | 52.1
...
```

---

## Requirements

```r
install.packages(c(
    # Core
    "data.table", "dplyr", "tidyverse", "here",
    # Time Series
    "lubridate", "xts", "forecast", "tseries", "timetk", "TTR",
    # ML
    "xgboost", "Matrix", "caret", "recipes",
    # Visualization
    "ggplot2", "corrplot", "GGally", "cowplot",
    # Utilities
    "RcppRoll", "doParallel", "gridExtra"
))

# Optional: Neural Networks
# install.packages("keras")
# keras::install_keras()
```

---

## Output Artifacts

### Saved Models:
- `models/xgboost_f1.rds` through `models/xgboost_f4.rds`
- (Optional) `models/nn_gru_f1.h5` etc. if Keras trained

### Predictions:
- `submissions/submission_f1/2/3/4.csv` (per-field)
- `submissions/submission_combined.csv` (all fields)

### Evaluation:
- `submissions/model_performance_summary.csv`
- `plots/correlation_field1-4.png`
- `plots/timeseries_field1-4.png`
- `plots/hourly_pattern_field1-4.png`

---

## Running Individual Stages

To run stages interactively:

```r
# Load configuration
source("00_config.r")

# Then run individually:
source("01_data_loading.r")
source("02_data_preparation.r")
source("03_feature_engineering.r")
source("04_exploratory_analysis.r")
source("05_models_xgboost.r")
source("07_predictions.r")
source("08_submission.r")
```

---

## Notes

- **Reproducibility:** Seeds set (123, 45) but parallel processing may introduce minor variations
- **Computation time:** ~10-20 minutes on standard hardware
- **Memory:** Keep all field datasets in RAM (~100-200MB typical)
- **Timezone:** Assumes UTC timestamps; adjust if local time in input files
- **Missing data:** Handled via feature lag removal; no explicit imputation
