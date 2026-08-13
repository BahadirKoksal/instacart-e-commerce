# Linear Regression - Basket Size Prediction

This folder contains the linear regression model for predicting basket size 
(item_count) per order, built on the `order_features_linreg` table.

## Data Used
- Source table: `order_features_linreg` (BigQuery)
- Target variable: `item_count` (outliers capped at the 99th percentile → `item_count_capped`)
- Predictors: order_dow, order_hour_of_day, days_since_prior_order, 
  distinct_department_count, avg_days_between_orders, distinct_aisle_count, 
  reorder_rate, is_first_order

## Preprocessing
- Missing `days_since_prior_order` values (206,209 rows, first-time orders) 
  were imputed with the median, and flagged with a new `is_first_order` indicator.
- Outliers in `item_count` were capped at the 99th percentile (35 items) to 
  reduce the influence of extreme values on the linear model.
- Features were standardized (StandardScaler) before training.
- Data was split 80/20 into train and test sets.

## Model Performance
| Metric | Value |
|---|---|
| R² | 0.6985 |
| RMSE | 3.99 |
| MAE | 2.92 |

The model explains ~70% of the variance in basket size. On average, 
predictions deviate from the actual basket size by ~3 items.

## Key Findings
- **Purchase diversity is the strongest driver of basket size.** 
  `distinct_department_count` (coef. 5.77) and `distinct_aisle_count` 
  (coef. 0.45) are by far the most influential predictors — customers who 
  shop across more departments and aisles place significantly larger orders.
- **Timing has almost no effect.** `order_dow` and `order_hour_of_day` show 
  negligible coefficients (-0.06 and -0.12). A controlled scenario test 
  (same customer profile, different day/hour) produced basket size 
  predictions within ~0.7 items of each other, confirming timing is not a 
  meaningful driver.
- **Residual analysis** revealed mild heteroscedasticity: the model tends to 
  overestimate very small baskets and underestimate very large ones 
  (regression to the mean), a known limitation of linear models on 
  right-skewed targets.

## Business Implication
Strategies aimed at increasing basket size should focus on encouraging 
category/aisle exploration (cross-selling, product discovery) rather than 
time-based promotions, which show negligible impact on order size.

## Contents
- `linear_regression.ipynb`: EDA, preprocessing, model training, and evaluation
