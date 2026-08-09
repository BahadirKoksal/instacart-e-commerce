# Project Overview

## Business Objective
Predict which products customers are likely to reorder, and understand 
customer purchasing behavior, in order to support personalized 
recommendations, marketing decisions, and inventory/supply planning.

## Business Context
- Business type: B2C (business-to-consumer)
- Relationship type: transaction-based (not subscription)
- Analysis type: Ad hoc

## Stakeholders
- Marketing team (personalized campaigns and recommendations)
- Product/growth team (in-app reorder suggestions)
- Supply chain / inventory planning (demand forecasting)
- Senior management (customer retention and loyalty metrics)

## Dataset
- Source: Kaggle — Instacart Market Basket Analysis
- Scope: ~3.4M orders, ~206K users, ~50K products, 21 departments, 
  134 aisles
- Raw tables: `orders`, `order_products__prior`, `order_products__train`, 
  `products`, `aisles`, `departments`
- Processed tables: `fact_order_products`, `dim_products`, `order_summary`, 
  `customer_performance`, `product_performance`, `category_performance`, 
  `customer_segments`, `customer_product_features`, `order_features_linreg`

## Architecture
1. **SQL (BigQuery):** data cleaning, joining, and feature engineering
2. **Python:** exploratory data analysis, statistical testing, and 
   machine learning modeling
3. **Power BI:** business KPI dashboards and model insight visualization

## Models

### 1. Logistic Regression — Reorder Prediction
- Table: `customer_product_features`
- Target: `will_reorder` (binary: 0/1)

### 2. Linear Regression — Basket Size Prediction
- Table: `order_features_linreg`
- Target: `item_count` (continuous)

### 3. Clustering — Customer Segmentation
- Table: `customer_performance`
- Unsupervised, behavior-based segmentation

## KPIs and Metrics

### Business KPIs (Power BI)
- Overall reorder rate
- Average order frequency per customer
- Reorder rate by department/aisle
- Reorder rate by customer segment
- Average basket size
- Top N products by reorder rate

### Model Performance KPIs (Python)
- Precision, Recall, F1-score, ROC-AUC (for classification)
- R², RMSE, MAE (for regression)
- Silhouette score (for clustering)
- Feature importance
