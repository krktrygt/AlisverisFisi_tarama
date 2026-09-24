# CepSepeti — Geliştirme Görev Listesi ve Adım Adım Takip Dokümanı

Bu doküman, [`mimari_tasarim.md`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md) dosyasında tanımlanan mimari kararları, modelleri, algoritmaları ve akışları **solo geliştirici + yapay zeka yardımcı pilotu (agent co-pilot)** formatında, tek oturumluk (1-2 saatlik) küçük parçalar halinde hayata geçirmek için hazırlanmıştır.

Her adımın karşısında [`mimari_tasarim.md`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md) içindeki **kesin satır referansları** yer almaktadır. Böylece kod yazarken veya ajandan kod isterken ilgili mimari spesifikasyona anında ulaşabilirsiniz.

---

## 🛠️ Nasıl Kullanılır?
* **Adım Adım İlerleme:** Her mikro-adım tek bir hedefe odaklanır. Bir adımın testi geçmeden bir sonrakine geçmeyin.
* **Ajan ile Çalışma:** Geliştirme yaparken ajana doğrudan:  
  * *"Şimdi gorev_listesi.md dosyasındaki Mikro-Adım 1.1'i kodlayalım"* diyebilirsiniz. Ajan doğrudan ilgili satır referansındaki spesifikasyonları alıp kodları Xcode projenize üretecektir.
* **İlerleme Takibi:** Tamamladığınız maddelerin yanındaki kutucukları `- [x]` olarak işaretleyiniz.

---

## 📁 Modüler Klasör Mimarisi ve Temiz Kod Standartları Referansı
* **Detaylı Klasör Ağacı ve Standartlar:** [`mimari_tasarim.md#L550-L700`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L550-L700)
* **Temiz Kod Kuralları (Clean Code Guidelines):**
  1. *Dosya Başına Tek Tip:* Her `.swift` dosyası tek bir class/struct/actor/enum barındırır.
  2. *Protokol Odaklılık:* Servisler concrete class'lara değil, protokollere bağlanır (`ReceiptPersistenceServiceProtocol`, `RetailMarketProfile`).
  3. *Swift 6 Aktör Disiplini:* UI daima `@MainActor`, kalıcılık `@ModelActor`, sınırlar arası sadece `Sendable` DTO.
  4. *150 Satır Kuralı:* 150 satırı aşan SwiftUI View'ları `Components/` altına bölünür.
  5. *Tip Güvenli Hatalar:* `LocalizedError` uyumlu spesifik domain hata enum'ları kullanılır.

---

## 🧭 Genel İlerleme Özeti

- [x] **FAZ 1: Çekirdek Veri Mimarisi ve Kalıcılık Temeli (4 / 4 Tamamlandı)**
  - [x] [1.1: Değer Tipleri, Enum'lar ve DTO Katmanı](#mikro-ad\u0131m-11-de\u011fer-tipleri-enumlar-ve-dto-katman\u0131)
  - [x] [1.2: SwiftData Entity Şeması ve Para Formatlayıcılar](#mikro-ad\u0131m-12-swiftdata-entity-\u015femas\u0131-ve-para-formatlay\u0131c\u0131lar)
  - [x] [1.3: Dosya Sistemi Tabanlı Görüntü Deposu](#mikro-ad\u0131m-13-dosya-sistemi-tabanl%C4%B1-g%C3%B6r%C3%BCnt%C3%BC-deposu-receiptimagediskmanager)
  - [x] [1.4: Swift 6 Eşzamanlı Kalıcılık Aktörü](#mikro-ad\u0131m-14-swift-6-e%C5%9Fzamanl%C4%B1-kal%C4%B1c%C4%B1l%C4%B1k-akt%C3%B6r%C3%BC-receiptpersistenceactor)
- [x] **FAZ 2: VisionKit Tarama ve Görüntü İyileştirme (3 / 3 Tamamlandı)**
  - [x] [2.1: VisionKit Doküman Tarayıcısı Sarmalayıcısı](#mikro-ad\u0131m-21-visionkit-dok%C3%BCman-taray%C3%BDc%C4%B1-sarmalay%C3%BDc%C4%B1s%C4%B1-documentscannerview)
  - [x] [2.2: Metal Destekli Görsel Ön İşleme Motoru](#mikro-ad\u0131m-22-metal-destekli-g%C3%B6rsel-%C3%B6n-i%C5%9Fleme-motoru-receiptimagepreprocessor)
  - [x] [2.3: Apple Vision OCR ve Geometrik Satır Gruplayıcı](#mikro-ad\u0131m-23-apple-vision-ocr-ve-geometrik-sat%C4%B1r-gruplay%C4%B1c%C4%B1-receiptlinesegmenter)
- [x] **FAZ 3: Genişletilebilir Pazar Profili ve Fiş Ayrıştırma (2 / 2 Tamamlandı)**
  - [x] [3.1: Pazar Stratejisi Altyapısı ve Regex Kütüphaneleri](#mikro-ad\u0131m-31-pazar-stratejisi-altyap%C4%B1s%C4%B1-ve-regex-k%C3%BCt%C3%BCphaneleri)
  - [x] [3.2: Ayrıştırıcı Motor ve Güven Skorlama](#mikro-ad\u0131m-32-ayr%C4%B1%C5%9Ft%C4%B1r%C4%B1c%C4%B1-motor-ve-g%C3%BCven-skorlama-receiptparserengine)
- [x] **FAZ 4: İnteraktif Doğrulama Ekranı ve Taslak Güvenliği (3 / 3 Tamamlandı)**
  - [x] [4.1: İki Parçalı Bölünmüş Ekran ve Durum Makinesi](#mikro-ad\u0131m-41-iki-par%C3%A7al%C4%B1-b%C3%B6l%C3%BCnm%C3%BC%C5%9F-ekran-ve-durum-makinesi-reviewcorrectionview)
  - [x] [4.2: Dokun-İncele ve Canlı Sağlama Çubuğu](#mikro-ad\u0131m-42-dokun-incele-tap-to-inspect-ve-canl%C4%B1-sa%C4%9Flama-%C3%A7ubu%C4%9Fu)
  - [x] [4.3: Kaza Kurtarma ve Taslak Deposu](#mikro-ad\u0131m-43-kaza-kurtarma-ve-taslak-deposu-receiptdraftstore)
- [x] **FAZ 5: Gösterge Paneli ve Analitik Motoru (3 / 3 Tamamlandı)**
  - [x] [5.1: Ana Gösterge Paneli ve Fiş Geçmişi Listesi](#mikro-ad\u0131m-51-ana-g%C3%B6sterge-paneli-ve-fi%C5%9F-ge%C3%A7mi%C5%9Fi-listesi)
  - [x] [5.2: Fiyat ve Harcama Analitiği Motoru](#mikro-ad\u0131m-52-fiyat-ve-harcama-analiti%C4%9Fi-motoru-swift-charts)
  - [x] [5.3: Deterministik Harcama İçgörü Motoru](#mikro-ad\u0131m-53-deterministik-harcama-i%C3%A7g%C3%B6r%C3%BC-motoru-deterministicinsightengine)
- [ ] **FAZ 6: Çok Parçalı Fiş Birleştirme, Erişilebilirlik ve Yayın (0 / 2 Tamamlandı)**
