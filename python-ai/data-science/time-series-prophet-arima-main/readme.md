# 📈 Time Series with Prophet & ARIMA — Forecasting Temporal Patterns

## What is Time Series Forecasting?
Time series forecasting predicts future values from historical, time-ordered data. Classical methods like ARIMA model autocorrelation and differencing, while Facebook Prophet handles trend, seasonality, and holidays automatically. Together they cover everything from demand forecasting to anomaly detection.

## Why Learn It?
- Forecast revenue, demand, traffic, and sensor readings
- Detect anomalies in metrics and operational data
- Build production forecasting pipelines with confidence intervals
- Understand when to use statistical vs ML-based approaches
- Combine domain knowledge (holidays, events) with learned patterns

## Key Concepts
```python
import pandas as pd
import numpy as np
from statsmodels.tsa.stattools import adfuller
from statsmodels.graphics.tsaplots import plot_acf, plot_pacf
from statsmodels.tsa.arima.model import ARIMA
from pmdarima import auto_arima
from prophet import Prophet
from sklearn.metrics import mean_absolute_error, mean_squared_error

# --- Stationarity Check (ADF Test) ---
series = pd.read_csv("sales.csv", index_col="date", parse_dates=True)["sales"]
result = adfuller(series.dropna())
print(f"ADF Statistic: {result[0]:.4f}, p-value: {result[1]:.4f}")
print("Stationary" if result[1] < 0.05 else "Non-stationary — apply differencing")

# --- ARIMA with statsmodels ---
model  = ARIMA(series, order=(1, 1, 1))          # p=1, d=1, q=1
fitted = model.fit()
print(fitted.summary())
forecast = fitted.forecast(steps=30)

# --- Auto ARIMA (finds best p,d,q automatically) ---
auto_model = auto_arima(series, seasonal=True, m=12,   # m=12 for monthly seasonality
                        stepwise=True, suppress_warnings=True)
print(auto_model.summary())
auto_forecast = auto_model.predict(n_periods=30)

# --- Facebook Prophet ---
df = series.reset_index().rename(columns={"date": "ds", "sales": "y"})
m  = Prophet(changepoint_prior_scale=0.05,   # flexibility of trend
             seasonality_mode="multiplicative")
m.add_seasonality(name="monthly", period=30.5, fourier_order=5)
m.add_country_holidays(country_name="US")
m.fit(df)

future   = m.make_future_dataframe(periods=90)
forecast = m.predict(future)
fig      = m.plot_components(forecast)          # trend + seasonality breakdown

# --- Anomaly Detection with Prophet ---
forecast["anomaly"] = (
    (df["y"] < forecast["yhat_lower"]) | (df["y"] > forecast["yhat_upper"])
).astype(int)
anomalies = forecast[forecast["anomaly"] == 1][["ds", "yhat", "yhat_lower", "yhat_upper"]]

# --- Evaluation Metrics ---
y_true = series[-30:].values
y_pred = forecast["yhat"].values[-30:]
mae    = mean_absolute_error(y_true, y_pred)
rmse   = np.sqrt(mean_squared_error(y_true, y_pred))
mape   = np.mean(np.abs((y_true - y_pred) / y_true)) * 100
print(f"MAE: {mae:.2f} | RMSE: {rmse:.2f} | MAPE: {mape:.2f}%")

# --- NeuralProphet (deep learning forecasting) ---
from neuralprophet import NeuralProphet
np_model = NeuralProphet(n_forecasts=30, n_lags=60)
metrics  = np_model.fit(df, freq="D")
future   = np_model.make_future_dataframe(df, periods=30)
forecast = np_model.predict(future)
```

## Learning Path
1. Understand time series components: trend, seasonality, noise, cycles
2. Learn stationarity and apply ADF test; practice differencing
3. Study ACF/PACF plots to manually select ARIMA(p,d,q) orders
4. Use `auto_arima` from pmdarima to automate model selection
5. Add seasonal components with SARIMA (p,d,q)(P,D,Q,m)
6. Learn Facebook Prophet API: fit, predict, add_seasonality, add_regressor
7. Implement changepoint detection and holiday effects in Prophet
8. Evaluate forecasts with MAE, RMSE, MAPE, and coverage of prediction intervals
9. Explore NeuralProphet for datasets requiring lagged features and deep patterns
10. Build end-to-end forecasting pipeline with retraining and monitoring

## What to Build
- [ ] ARIMA sales forecasting pipeline with auto model selection and evaluation
- [ ] Prophet forecast dashboard with trend + seasonality component plots
- [ ] Anomaly detection system for web traffic or metrics using Prophet intervals
- [ ] Multi-series forecasting pipeline (one model per SKU/product)
- [ ] Forecasting API endpoint that retrains weekly and serves predictions
- [ ] Comparison notebook: ARIMA vs Prophet vs NeuralProphet on the same dataset

## Related Folders
- `data-science/ab-testing-experimentation-main/` — validate forecasting model improvements
- `ml-engineering/mlflow-experiment-tracking-main/` — track and compare forecast experiments
- `databases/postgresql-pgvector-main/` — store time series data and forecasts at scale
