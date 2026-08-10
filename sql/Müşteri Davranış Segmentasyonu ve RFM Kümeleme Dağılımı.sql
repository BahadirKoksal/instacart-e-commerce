WITH customer_behavior AS (
  SELECT 
    user_id,
    COUNT(order_id) AS toplam_siparis_sayisi,
    AVG(days_since_prior_order) AS ortalama_siparis_araligi_gun
  FROM `project-84485539-b01a-418a-932.Instacart_Raw_Dataset.orders`
  GROUP BY user_id
),
segmented_customers AS (
  SELECT 
    user_id,
    CASE 
      WHEN toplam_siparis_sayisi >= 30 AND ortalama_siparis_araligi_gun <= 10 THEN '1. Sadık Müşteriler (VIP Cluster)'
      WHEN toplam_siparis_sayisi >= 10 AND ortalama_siparis_araligi_gun <= 15 THEN '2. Düzenli Müşteriler (Regular Cluster)'
      WHEN toplam_siparis_sayisi < 5 AND ortalama_siparis_araligi_gun > 20 THEN '3. Riskli / Terk Etmeye Yakın (Churned Cluster)'
      ELSE '4. Potansiyel / Yeni Müşteriler (Potential Cluster)'
    END AS musteri_kumesi
  FROM customer_behavior
)

SELECT 
  musteri_kumesi,
  COUNT(user_id) AS musteri_sayisi,
  ROUND(COUNT(user_id) * 100.0 / SUM(COUNT(user_id)) OVER(), 2) AS yuzdesel_pay
FROM segmented_customers
GROUP BY musteri_kumesi
ORDER BY musteri_sayisi DESC;