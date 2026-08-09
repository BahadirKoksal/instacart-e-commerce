# Clustering - Customer Segmentation

   This folder contains the clustering model for customer segmentation, 
   built on the `customer_performance` table.

   ## Data Used
   - Source table: `customer_performance` (BigQuery)
   - Features: total_orders, total_products_purchased, 
     distinct_products_purchased, reorder_rate, avg_add_to_cart_order, 
     avg_days_between_orders, distinct_department_count, distinct_aisle_count

   ## Contents
   - `clustering.ipynb`: EDA, preprocessing, model training, and cluster evaluation
