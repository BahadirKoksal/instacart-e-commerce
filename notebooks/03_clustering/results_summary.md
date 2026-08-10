# 🛒 Instacart Müşteri Segmentasyon Projesi (K-Means)

Bu projede Instacart veri seti kullanılarak müşterilerin alışveriş davranışları (sipariş sıklığı, sipariş zamanı ve hacmi) analiz edilmiş ve **K-Means Kümeleme Algoritması** ile 4 ana müşteri segmenti oluşturulmuştur.

## 📊 Öne Çıkan Bulgular ve Segmentler

| Küme | Segment Adı | Müşteri Payı | Ort. Sipariş Aralığı | Ort. Toplam Sipariş | Öne Çıkan Davranış |
| :---: | :--- | :---: | :---: | :---: | :--- |
| **0** | **Sadık & Yüksek Hacimli** | %27.97 | 8.25 Gün | 35.81 | En aktif grup, yüksek bağlılık |
| **1** | **Akşamüstü Alışverişçileri** | %23.72 | 17.81 Gün | 9.20 | Sipariş saatleri 15:00 - 16:00 yoğunluklu |
| **2** | **Sabah Alışverişçileri** | %24.68 | 18.24 Gün | 9.23 | Sipariş saatleri 11:00 - 12:00 yoğunluklu |
| **3** | **Hafta Başı Alışverişçileri** | %23.63 | 18.68 Gün | 8.95 | Siparişler Pazar/Pazartesi günleri yoğunlaşır |

## 🛠️ Kullanılan Teknolojiler
* **Python** (Pandas, NumPy, Scikit-Learn, Plotly, Seaborn)
* **Google BigQuery** (Veri Depolama ve Sorgulama)
* **Google Colab** (Model Eğitimi)

## 🚀 Çalıştırma
1. Depoyu klonlayın: `git clone https://github.com/KULLANICI_ADI/REPO_ADI.git`
2. Gereksinimleri yükleyin: `pip install -r requirements.txt`
3. `notebook.ipynb` dosyasını çalıştırın.
