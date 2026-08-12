/*******************************************************************************
 PROJE: Instacart Market Analitiği & Müşteri Davranış Profilleme
 SORGU ADI: "Zamanın Sepeti" - Gün İçi Sipariş & Müşteri Davranış Matrisi
 AÇIKLAMA: 
   Bu sorgu; orders, order_products__prior, products, aisles ve departments 
   tablolarını birleştirerek müşterilerin günün farklı saat dilimlerindeki (Sabah, 
   Öğle, Akşam, Gece) alışveriş alışkanlıklarını, sepet derinliklerini ve 
   kategori bazlı sadakat (reorder) oranlarını analiz eder.
*******************************************************************************/

WITH base_data AS (
  -- 1. Aşama: Tüm Ham Tabloların Birleştirilmesi ve Saat Dilimlerinin Tanımlanması
  SELECT 
    o.user_id,
    o.order_id,
    o.order_dow,
    o.order_hour_of_day,
    
    -- Gün İçi Zaman Dilimi Kategorizasyonu
    CASE 
      WHEN o.order_hour_of_day BETWEEN 6 AND 11 THEN '1. Sabah (06:00 - 11:59)'
      WHEN o.order_hour_of_day BETWEEN 12 AND 16 THEN '2. Öğle / Öğleden Sonra (12:00 - 16:59)'
      WHEN o.order_hour_of_day BETWEEN 17 AND 21 THEN '3. Akşam (17:00 - 21:59)'
      ELSE '4. Gece / Gece Yarısı (22:00 - 05:59)'
    END AS zaman_dilimi,
    
    p.product_id,
    p.product_name,
    a.aisle,
    d.department,
    op.reordered
  FROM `project-84485539-b01a-418a-932.Instacart_Raw_Dataset.orders` o
  JOIN `project-84485539-b01a-418a-932.Instacart_Raw_Dataset.order_products__prior` op 
    ON o.order_id = op.order_id
  JOIN `project-84485539-b01a-418a-932.Instacart_Raw_Dataset.products` p 
    ON op.product_id = p.product_id
  JOIN `project-84485539-b01a-418a-932.Instacart_Raw_Dataset.aisles` a 
    ON p.aisle_id = a.aisle_id
  JOIN `project-84485539-b01a-418a-932.Instacart_Raw_Dataset.departments` d 
    ON p.department_id = d.department_id
),

aisle_rankings AS (
  -- 2. Aşama: Her Zaman Diliminde En Çok Satılan 1. Reyonun Sıralanması
  SELECT 
    zaman_dilimi,
    aisle AS en_populer_reyon,
    COUNT(*) AS reyon_urun_sayisi,
    ROW_NUMBER() OVER(PARTITION BY zaman_dilimi ORDER BY COUNT(*) DESC) AS rnk
  FROM base_data
  GROUP BY zaman_dilimi, aisle
),

department_rankings AS (
  -- 3. Aşama: Her Zaman Diliminde En Çok Satılan 1. Departmanın Sıralanması
  SELECT 
    zaman_dilimi,
    department AS en_populer_departman,
    COUNT(*) AS dept_urun_sayisi,
    ROW_NUMBER() OVER(PARTITION BY zaman_dilimi ORDER BY COUNT(*) DESC) AS rnk
  FROM base_data
  GROUP BY zaman_dilimi, department
),

time_slot_metrics AS (
  -- 4. Aşama: Zaman Dilimi Bazlı Genel Metrik Hesaplamaları
  SELECT 
    zaman_dilimi,
    COUNT(DISTINCT user_id) AS tekil_musteri_sayisi,
    COUNT(DISTINCT order_id) AS toplam_siparis_sayisi,
    COUNT(product_id) AS toplam_satilan_urun,
    
    -- Sipariş Başına Ortalama Sepet Boyutu
    ROUND(COUNT(product_id) / COUNT(DISTINCT order_id), 1) AS ort_sepet_urun_adedi,
    
    -- Tekrar Satın Alınma Oranı (%)
    ROUND(100.0 * SUM(reordered) / COUNT(*), 1) AS tekrar_siparis_orani_yuzde
  FROM base_data
  GROUP BY zaman_dilimi
)

-- 5. Aşama: Nihai Analitik Rapor Tablosu
SELECT 
  tm.zaman_dilimi AS Zaman_Dilimi,
  tm.tekil_musteri_sayisi AS Aktif_Musteri_Sayisi,
  tm.toplam_siparis_sayisi AS Toplam_Siparis,
  tm.ort_sepet_urun_adedi AS Sepet_Basi_Ort_Urun,
  tm.tekrar_siparis_orani_yuzde AS Tekrar_Siparis_Orani_Pct,
  dr.en_populer_departman AS En_Cok_Satan_Departman,
  ar.en_populer_reyon AS En_Cok_Satan_Reyon,
  
  -- Toplam Sipariş Hacmindeki Payı (%)
  ROUND(100.0 * tm.toplam_siparis_sayisi / SUM(tm.toplam_siparis_sayisi) OVER(), 2) AS Siparis_Hacmi_Payi_Pct

FROM time_slot_metrics tm
JOIN aisle_rankings ar ON tm.zaman_dilimi = ar.zaman_dilimi AND ar.rnk = 1
JOIN department_rankings dr ON tm.zaman_dilimi = dr.zaman_dilimi AND dr.rnk = 1
ORDER BY tm.zaman_dilimi;