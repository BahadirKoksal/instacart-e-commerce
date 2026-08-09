# Linear Regression - Basket Size Prediction

   This folder contains the linear regression model for predicting 
   basket size (item_count) per order, built on the 
   `order_features_linreg` table.

   ## Data Used
   - Source table: `order_features_linreg` (BigQuery)
   - Target variable: `item_count`
   - Predictors: order_dow, order_hour_of_day, days_since_prior_order, 
     distinct_department_count, avg_days_between_orders, 
     distinct_aisle_count, reorder_rate

   ## Contents
   - `linear_regression.ipynb`: EDA, preprocessing, model training, and evaluation
