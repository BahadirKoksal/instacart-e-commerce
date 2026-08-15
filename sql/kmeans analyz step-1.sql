/*
### Prior Sipariş Tablosunun Oluşturulması

Instacart veri seti bir ürün tahmin yarışması için `prior`, `train` ve `test` gruplarına ayrılmıştır. KMeans çalışmasının amacı müşterinin son siparişindeki ürünleri tahmin etmek değil, müşterileri geçmiş alışveriş davranışlarına göre segmentlere ayırmaktır. Bu nedenle bütün müşteriler için ortak ve karşılaştırılabilir geçmişi içeren `prior` siparişleri kullanılmıştır.

Ham `orders` tablosundan yalnızca `eval_set = 'prior'` kayıtları seçilmiş ve `stg_orders_prior` tablosu oluşturulmuştur. Yeni tabloda sipariş kimliği, müşteri kimliği, müşterinin kaçıncı siparişi olduğu, sipariş günü, sipariş saati ve önceki siparişten sonra geçen gün sayısı tutulmuştur.

Oluşturulan tabloda bir satır bir siparişi temsil etmektedir. Tablo 3.214.874 farklı sipariş ve 206.209 farklı müşteri içermektedir. Sipariş kimliklerinde tekrarlı veya boş kayıt bulunmamaktadır. `days_since_prior_order` kolonundaki boş değerler, müşterilerin ilk siparişlerine aittir ve veri hatası olarak değerlendirilmemiştir.
*/

--1. Temel sipariş tablosunu oluşturma

CREATE OR REPLACE TABLE
  `wit-final-project-504621.instacart_team_project.stg_orders_prior` AS

SELECT
  order_id,
  user_id,
  order_number,
  order_dow,
  order_hour_of_day,
  days_since_prior_order
FROM
  `project-84485539-b01a-418a-932.Instacart_Raw_Dataset.orders`
WHERE
  eval_set = 'prior';

--2. Oluşturulan tabloyu kontrol etme
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT order_id) AS distinct_orders,
  COUNT(DISTINCT user_id) AS distinct_users,

  COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_order_count,

  COUNTIF(order_id IS NULL) AS null_order_id_count,
  COUNTIF(user_id IS NULL) AS null_user_id_count,

  COUNTIF(order_number = 1) AS first_order_count,
  COUNTIF(days_since_prior_order IS NULL) AS null_days_since_prior_count
FROM
  `wit-final-project-504621.instacart_team_project.stg_orders_prior`;




/*
Sipariş Bazlı Özelliklerin Oluşturulması

order_products__prior tablosunda bir satır, bir siparişte yer alan bir ürünü temsil etmektedir. KMeans modelinin nihai veri seviyesi müşteri olsa da müşteri özelliklerini doğru hesaplayabilmek için önce ürün satırları sipariş düzeyinde özetlenmiştir.

stg_orders_prior ile order_products__prior tabloları order_id üzerinden birleştirilmiş ve her sipariş için sepet büyüklüğü, yeniden satın alınan ürün sayısı ve sipariş bazlı yeniden satın alma oranı hesaplanmıştır.

Sepet büyüklüğü, siparişte bulunan ürün satırı sayısını ifade etmektedir. Veri setinde ürün miktarı bulunmadığından aynı üründen kaç adet satın alındığı hesaplanamamaktadır. Yeniden satın alma oranı ise daha önce satın alınmış ürünlerin siparişteki bütün ürünlere oranıdır.

Bu işlem sonucunda 32.434.489 ürün satırı, 3.214.874 siparişi temsil eden sipariş bazlı bir özellik tablosuna dönüştürülmüştür. Böylece bir sonraki aşamada siparişler müşteri düzeyinde özetlenebilecektir.*/

  --3. Sipariş bazlı özellik tablosu
  CREATE OR REPLACE TABLE
  `wit-final-project-504621.instacart_team_project.int_order_features_prior` AS

SELECT
  o.order_id,
  o.user_id,
  o.order_number,
  o.order_dow,
  o.order_hour_of_day,
  o.days_since_prior_order,

  COUNT(*) AS basket_size,
  SUM(op.reordered) AS reordered_item_count,
  AVG(op.reordered) AS order_reorder_rate

FROM
  `wit-final-project-504621.instacart_team_project.stg_orders_prior` AS o

INNER JOIN
  `project-84485539-b01a-418a-932.Instacart_Raw_Dataset.order_products__prior` AS op
ON
  o.order_id = op.order_id

GROUP BY
  o.order_id,
  o.user_id,
  o.order_number,
  o.order_dow,
  o.order_hour_of_day,
  o.days_since_prior_order;

--4. Kontrol sorgusu

SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT order_id) AS distinct_orders,
  COUNT(DISTINCT user_id) AS distinct_users,

  SUM(basket_size) AS total_product_rows,
  MIN(basket_size) AS min_basket_size,
  MAX(basket_size) AS max_basket_size,

  COUNTIF(basket_size <= 0) AS invalid_basket_count,
  COUNTIF(order_reorder_rate < 0 OR order_reorder_rate > 1)
    AS invalid_reorder_rate_count

FROM
  `wit-final-project-504621.instacart_team_project.int_order_features_prior`;


  /*
  Müşteri Bazlı Özellik Tablosunun Oluşturulması

KMeans müşteri segmentasyonunda her gözlemin bir müşteriyi temsil etmesi gerekir. Bu nedenle sipariş ve ürün düzeyindeki veriler müşteri bazında özetlenerek customer_features_raw tablosu oluşturulmuştur.

Öncelikle sipariş bazlı tablodan müşterilerin toplam sipariş sayısı, toplam ürün satırı, ortalama sepet büyüklüğü, sipariş aralığı ve yeniden satın alma oranı hesaplanmıştır. Daha sonra sipariş ürünleri, ürün kartlarıyla birleştirilerek her müşterinin satın aldığı farklı ürün, reyon ve departman sayıları belirlenmiştir. Ayrıca müşterinin alışverişlerinin en çok tercih ettiği departmanda ne ölçüde yoğunlaştığını göstermek amacıyla top_department_share değişkeni oluşturulmuştur.

Sipariş ve ürün özellikleri ayrı ayrı hesaplanmıştır. Bunun nedeni, siparişlerin ürün satırlarıyla birleştirildiğinde her ürün için tekrar etmesi ve doğrudan sayım yapılması hâlinde sipariş sayısının yanlış hesaplanabilecek olmasıdır. Ayrı ayrı oluşturulan özetler daha sonra user_id üzerinden birleştirilmiştir.

Sonuçta her satırı bir müşteriyi temsil eden 206.209 satırlık ham özellik tablosu elde edilmiştir. Bu tablodaki değişkenler KMeans için aday özelliklerdir. Henüz bütün değişkenlerin modele alınmasına karar verilmemiştir; eksik değer, dağılım, aykırı değer ve değişkenler arası benzerlik incelemelerinden sonra nihai model özellikleri belirlenecektir.
*/


--3. Müşteri bazlı özellik tablosunu oluşturma
CREATE OR REPLACE TABLE
  `wit-final-project-504621.instacart_team_project.customer_features_raw` AS

WITH order_features AS (
  SELECT
    user_id,

    COUNT(*) AS total_orders,
    SUM(basket_size) AS total_items,

    AVG(basket_size) AS avg_basket_size,
    STDDEV_SAMP(basket_size) AS basket_size_std,

    AVG(days_since_prior_order) AS avg_days_between_orders,
    STDDEV_SAMP(days_since_prior_order) AS days_between_orders_std,

    SAFE_DIVIDE(
      SUM(reordered_item_count),
      SUM(basket_size)
    ) AS reorder_rate

  FROM
    `wit-final-project-504621.instacart_team_project.int_order_features_prior`

  GROUP BY
    user_id
),

item_base AS (
  SELECT
    o.user_id,
    op.product_id,
    p.aisle_id,
    p.department_id

  FROM
    `wit-final-project-504621.instacart_team_project.stg_orders_prior` AS o

  INNER JOIN
    `project-84485539-b01a-418a-932.Instacart_Raw_Dataset.order_products__prior` AS op
      ON o.order_id = op.order_id

  INNER JOIN
    `project-84485539-b01a-418a-932.Instacart_Raw_Dataset.products` AS p
      ON op.product_id = p.product_id
),

product_features AS (
  SELECT
    user_id,
    COUNT(DISTINCT product_id) AS distinct_products,
    COUNT(DISTINCT aisle_id) AS distinct_aisles,
    COUNT(DISTINCT department_id) AS distinct_departments

  FROM
    item_base

  GROUP BY
    user_id
),

department_counts AS (
  SELECT
    user_id,
    department_id,
    COUNT(*) AS department_item_count

  FROM
    item_base

  GROUP BY
    user_id,
    department_id
),

department_features AS (
  SELECT
    user_id,

    SAFE_DIVIDE(
      MAX(department_item_count),
      SUM(department_item_count)
    ) AS top_department_share

  FROM
    department_counts

  GROUP BY
    user_id
)

SELECT
  off.user_id,
  off.total_orders,
  off.total_items,
  off.avg_basket_size,
  off.basket_size_std,
  off.avg_days_between_orders,
  off.days_between_orders_std,
  off.reorder_rate,

  pf.distinct_products,

  SAFE_DIVIDE(
    pf.distinct_products,
    off.total_items
  ) AS product_diversity_ratio,

  pf.distinct_aisles,
  pf.distinct_departments,
  df.top_department_share

FROM
  order_features AS off

INNER JOIN
  product_features AS pf
    ON off.user_id = pf.user_id

INNER JOIN
  department_features AS df
    ON off.user_id = df.user_id;


--Kontrol sorgusu
SELECT
  COUNT(*) AS total_rows,
  COUNT(DISTINCT user_id) AS distinct_users,

  COUNT(*) - COUNT(DISTINCT user_id)
    AS duplicate_user_count,

  SUM(total_orders) AS total_orders,
  SUM(total_items) AS total_product_rows,

  MIN(total_orders) AS min_orders_per_user,
  MAX(total_orders) AS max_orders_per_user,

  COUNTIF(
    avg_basket_size IS NULL
    OR avg_days_between_orders IS NULL
    OR reorder_rate IS NULL
    OR distinct_products IS NULL
    OR top_department_share IS NULL
  ) AS customers_with_missing_core_features,

  COUNTIF(
    reorder_rate < 0 OR reorder_rate > 1
  ) AS invalid_reorder_rate_count,

  COUNTIF(
    product_diversity_ratio < 0
    OR product_diversity_ratio > 1
  ) AS invalid_diversity_ratio_count,

  COUNTIF(
    top_department_share <= 0
    OR top_department_share > 1
  ) AS invalid_department_share_count

FROM
  `wit-final-project-504621.instacart_team_project.customer_features_raw`;


  /*
  ### Müşteri Özelliklerinin Dağılım Analizi

KMeans, gözlemler arasındaki uzaklıklara dayalı bir yöntem olduğu için değişkenlerin dağılımlarından, ölçek farklarından ve uç değerlerden etkilenmektedir. Bu nedenle müşteri özellikleri doğrudan modele verilmeden önce eksik değerleri ve dağılımları incelenmiştir.

Her özellik için minimum, maksimum, ortalama, medyan, standart sapma ve temel yüzdelik değerler hesaplanmıştır. Ortalama ile medyan arasındaki fark, dağılımın çarpıklığı hakkında ilk bilgi sağlamaktadır. Yüzde 95 ve yüzde 99 değerleri ise müşterilerin büyük çoğunluğunun bulunduğu aralık ile uç gözlemleri karşılaştırmak amacıyla kullanılmıştır.

Bu aşamada herhangi bir müşteri silinmemiş ve özelliklere dönüşüm uygulanmamıştır. Amaç, veri üzerinde işlem yapmadan önce özelliklerin gerçek yapısını görmek ve uygulanacak dönüşüm, aykırı değer yönetimi ve ölçeklendirme kararlarını veriye dayalı olarak belirlemektir.
*/

--4. Özellik dağılımlarının incelenmesi
WITH feature_long AS (
  SELECT
    user_id,
    feature.feature_name,
    feature.feature_value

  FROM
    `wit-final-project-504621.instacart_team_project.customer_features_raw`,

  UNNEST([
    STRUCT(
      'total_orders' AS feature_name,
      CAST(total_orders AS FLOAT64) AS feature_value
    ),
    STRUCT(
      'total_items',
      CAST(total_items AS FLOAT64)
    ),
    STRUCT(
      'avg_basket_size',
      CAST(avg_basket_size AS FLOAT64)
    ),
    STRUCT(
      'basket_size_std',
      CAST(basket_size_std AS FLOAT64)
    ),
    STRUCT(
      'avg_days_between_orders',
      CAST(avg_days_between_orders AS FLOAT64)
    ),
    STRUCT(
      'days_between_orders_std',
      CAST(days_between_orders_std AS FLOAT64)
    ),
    STRUCT(
      'reorder_rate',
      CAST(reorder_rate AS FLOAT64)
    ),
    STRUCT(
      'distinct_products',
      CAST(distinct_products AS FLOAT64)
    ),
    STRUCT(
      'product_diversity_ratio',
      CAST(product_diversity_ratio AS FLOAT64)
    ),
    STRUCT(
      'distinct_aisles',
      CAST(distinct_aisles AS FLOAT64)
    ),
    STRUCT(
      'distinct_departments',
      CAST(distinct_departments AS FLOAT64)
    ),
    STRUCT(
      'top_department_share',
      CAST(top_department_share AS FLOAT64)
    )
  ]) AS feature
)

SELECT
  feature_name,

  COUNT(*) AS customer_count,
  COUNTIF(feature_value IS NULL) AS null_count,
  COUNTIF(feature_value = 0) AS zero_count,

  MIN(feature_value) AS minimum,
  APPROX_QUANTILES(feature_value, 100)[OFFSET(25)] AS p25,
  APPROX_QUANTILES(feature_value, 100)[OFFSET(50)] AS median,
  AVG(feature_value) AS mean,
  APPROX_QUANTILES(feature_value, 100)[OFFSET(75)] AS p75,
  APPROX_QUANTILES(feature_value, 100)[OFFSET(95)] AS p95,
  APPROX_QUANTILES(feature_value, 100)[OFFSET(99)] AS p99,
  MAX(feature_value) AS maximum,

  STDDEV_SAMP(feature_value) AS standard_deviation

FROM
  feature_long

GROUP BY
  feature_name

ORDER BY
  feature_name;
