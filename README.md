# 🧾 CepSepeti — On-Device Akıllı Fiş Okuma ve Harcama Analitiği

[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2018%2B-lightgrey?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![UI](https://img.shields.io/badge/UI-SwiftUI-007AFF?logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![Database](https://img.shields.io/badge/Persistence-SwiftData-5856D6)](https://developer.apple.com/xcode/swiftdata/)
[![AI/ML](https://img.shields.io/badge/AI-VisionKit%20%2B%20CoreML-34C759)](https://developer.apple.com/documentation/coreml)
[![Privacy](https://img.shields.io/badge/Privacy-100%25%20On--Device-32ADE6)](https://apple.com/privacy)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**CepSepeti**, market ve perakende alışveriş fişlerini akıllı telefon kamerasıyla tarayarak saniyeler içinde dijitalleştiren, harcamaları 20 temel kategoride etiketleyen ve kişisel enflasyon/fiyat trend analitiği sunan **gizlilik odaklı (privacy-first), tamamen cihaz üzerinde çalışan (on-device)** yeni nesil bir iOS uygulamasıdır.

Bulut sunucularına veri göndermez; tüm OCR, doğal dil işleme, makine öğrenimi sınıflandırması ve analitik hesaplamaları yerel donanım (Apple Neural Engine ve GPU) üzerinde koşturulur.

---

## 📌 İçindekiler
- [Öne Çıkan Özellikler](#-öne-çıkan-özellikler)
- [Teknoloji Mimarisi](#-teknoloji-mimarisi)
- [Uygulama Mimarisi ve Klasör Yapısı](#-uygulama-mimarisi-ve-klasör-yapısı)
- [Projenin Mevcut Durumu](#-projenin-mevcut-durumu)
- [Son Geliştirmeler ve Bilinen Uç Durumlar / Hatalar](#-son-geliştirmeler-ve-bilinen-uç-durumlar--hatalar)
- [Yapılacaklar ve Yol Haritası (Roadmap)](#-yapılacaklar-ve-yol-haritası-roadmap)
- [Kurulum ve Çalıştırma](#-kurulum-ve-çalıştırma)
- [Gizlilik Manifestosu](#-gizlilik-manifestosu)

---

## 🌟 Öne Çıkan Özellikler

### 1. VisionKit & Metal Destekli Tarama
- **Otomatik Belge Tespiti:** VisionKit `VNDocumentCameraViewController` ile fiş kenarlarının otomatik algılanması ve perspektif kırpması.
- **Metal Destekli Görsel İyileştirme:** Düşük ışıklı ortamlarda taranan termal fişler için adaptif kontrast artırımı ve gürültü temizleme filtresi (`ReceiptImagePreprocessor`).

### 2. Çift Hatlı Hibrit OCR ve Ayrıştırma Motoru (Hybrid Parsing Pipeline)
- **Apple Vision OCR:** Yüksek hassasiyetli metin ve geometri (bounding box) çıkarımı.
- **Geometrik Satır Gruplama:** Yatay ve dikey koordinatları baz alarak dağınık kelime kutularını mantıksal fiş satırlarına dönüştüren `ReceiptLineSegmenter`.
- **Kural Tabanlı & CoreML Hibrit Motor:** Türkiye perakende formatlarına (BİM, A101, Migros, ŞOK vb.) özel regex kütüphaneleri (`ReceiptRegexLibrary`) ile CoreML token sınıflandırıcı (`Alisveris_Fis_Takip_Classifier1` & `tagger1`) hibrit çalışması.
- **Stack Tabanlı Çok Satırlı Çözücü:** Fişte ürün adı ile fiyatı ayrı satırlara basıldığında oluşan fiyat kaymalarını engelleyen akıllı yığın (stack) algoritması.

### 3. Yapılandırılmış Ambalaj ve Gramaj Ayrıştırma
- Ürün adının içine gömülü gelen `1L`, `500 GR`, `6X200ML`, `4x1 KG` gibi karmaşık paket desenlerini ayrıştırır (`ProductPackagingParser`).
- Birim fiyatları hatasız hesaplar; ürün adını sadeleştirirken ambalaj bilgisini yapısal veri olarak saklar.

### 4. 20 Standart Perakende Kategorisi & CoreML Sınıflandırma
- Eğitilmiş Maximum Entropy modeli (`Alisveris_Fis_takip_kategori_classifier1.mlmodel`) ile ürünleri Süt & Kahvaltılık, Temizlik, Meyve & Sebze gibi 20 standart kategoriye otomatik atar.
- İnceleme ekranında kullanıcıya manuel kategori düzeltme menüsü sunar.

### 5. Deterministik Analitik ve Kişisel Enflasyon Takipçisi
- **Laspeyres Fiyat Endeksi:** Kullanıcının sepetindeki ürünlerin geçmişe göre fiyat artış oranını ölçen enflasyon motoru (`PersonalInflationEngine`).
- **Tasarruf ve Fiyat Sıçrama Kuralları:** Ani fiyat artışlarını ve marketler arası arbitraj fırsatlarını tespit eden kural motoru (`DeterministicInsightEngine`).

### 6. Swift 6 ve SwiftData Eşzamanlılık Disiplini
- UI tarafı `@MainActor`, arkaplan veritabanı yazma operasyonları `@ModelActor` (`ReceiptPersistenceActor`) ile izole edilmiştir.
- Sınırlar arası yalnızca `Sendable` DTO'lar taşınarak veri yarışları (data races) derleme zamanında engellenir.

---

## 🏗 Teknoloji Mimarisi

| Katman | Teknoloji / Kütüphane | Kullanım Amacı |
| :--- | :--- | :--- |
| **Dil** | **Swift 6.0** | Strict Concurrency, Modern Typed Throws, Sendable DTOs |
| **Kullanıcı Arayüzü** | **SwiftUI (iOS 18+)** | Reaktif, bileşen bazlı ve modern UI mimarisi |
| **Kalıcılık** | **SwiftData** | `@ModelActor` tabanlı ilişkisel yerel veri yönetimi |
| **Kamera & Görsel** | **VisionKit & Metal (CI/CoreImage)** | Otomatik doküman tarama ve görsel ön işleme |
| **Metin Tanıma** | **Apple Vision Framework** | On-device yerel OCR ve geometrik koordinat çıkarımı |
| **Makine Öğrenimi** | **CoreML & CreateML** | Token Tagger, Satır Rol Sınıflandırıcı ve Kategori Modeli |
| **Mimari Model** | **Clean Architecture + Actor-Driven MVVM** | Katı katman ayrımı, test edilebilirlik ve protokol tabanlı DI |

---

## 📂 Uygulama Mimarisi ve Klasör Yapısı

```text
Alisveris-fisTarama/
├── App/
│   ├── Alisveris_fisTaramaApp.swift     # Uygulama giriş noktası
│   └── AppContainer.swift              # SwiftData ModelContainer & Servis DI Container
├── Core/
│   ├── DTOs/                           # Sendable ve tip güvenli sınır veri modelleri
│   ├── Models/Enums/                   # StandardCategory, PaymentMethod, UnitType vb.
│   ├── Formatters/                     # CurrencyNormalizer ve metin biçimlendiriciler
│   ├── Utilities/                      # ProductPackagingParser, UnitConverter
│   └── Debug/                          # ReceiptDevLogger ve pipeline telemetri araçları
├── Data/
│   ├── Persistence/                    # SwiftData modelleri (Store, ShoppingTrip, Item)
│   │   ├── Models/
│   │   └── ReceiptPersistenceActor.swift # @ModelActor tabanlı güvenli veritabanı aktörü
│   └── Storage/                        # Fiş fotoğrafları disk deposu & taslak yönetimi
├── Features/
│   ├── Scan/                           # VisionKit tarama arayüzü
│   ├── Review/                         # Ayrıştırma düzeltme, doğrulama ve kategori seçimi
│   ├── Dashboard/                      # Harcama grafikleri, içgörü kartları
│   └── History/                        # Geçmiş alışveriş seyahatleri ve fiş detayları
├── Services/
│   ├── OCR/                            # Apple Vision entegrasyonu & LineSegmenter
│   ├── ImageProcessing/                # Metal tabanlı görsel kontrast ve gri tonlama
│   ├── Parser/                         # Fiş çözümleme motoru, regex ve ML çıkarım servisi
│   └── Analytics/                      # Laspeyres enflasyon endeksi ve kural motoru
├── CreateML models/                    # .mlmodel dosyaları ve eğitim veri setleri (JSON)
└── Alisveris-fisTaramaTests/           # Birim ve entegrasyon testleri (Swift Testing)
```

---

## 📊 Projenin Mevcut Durumu

Proje şu anda planlanan 6 geliştirme fazından **Faz 5'i başarıyla tamamlamış**, **Faz 6 (Doğrulama, ML Kararlılığı ve Model Entegrasyonu)** test ve iyileştirme aşamasındadır:

- [x] **Faz 1: Çekirdek Veri Mimarisi ve Kalıcılık** (SwiftData modelleri, Swift 6 Persistence Actor, N+1 optimizasyonu).
- [x] **Faz 2: VisionKit Tarama & Görsel Ön İşleme** (Doküman yakalama, satır segmentasyonu).
- [x] **Faz 3: Pazar Profili & Regex Fiş Ayrıştırma Motoru** (Türkiye perakende profili, KDV & toplam hesaplama).
- [x] **Faz 4: İnceleme ve Düzeltme Arayüzü (Review UI)** (Kullanıcı doğrulama ekranı, canlı bakiye dengeleme çubuğu).
- [x] **Faz 5: Deterministik Analitik & Kişisel Enflasyon Motoru** (Fiyat sıçrama alarmları, Laspeyres endeksi).
- [ ] **Faz 6: CoreML Entegrasyonu, Kategori Sınıflandırma ve Model İyileştirme** *(Aktif İlerleme)*.

---

## 🔍 Son Geliştirmeler ve Bilinen Uç Durumlar / Hatalar

`AdTemizliği_kategorizasyon` geliştirme dalında projeye 20 perakende kategorisi, CoreML Maximum Entropy sınıflandırıcısı ve temiz ürün ismi standardı kazandırılmıştır. Test aşamasında tespit edilen ve çözümü üzerinde çalışılan uç durumlar şunlardır:

### 1. Kategori Sınıflandırma Modeli Kapsamı
- **Durum:** Model 2.000 adet perakende satırından oluşan veri setiyle eğitilmiştir. Maximum Entropy algoritması ASCII normalizasyonu (`replace "ı" -> "i"`) ile çalışmaktadır.
- **Uç Durum:** Çok nadir geçen, aşırı kısaltılmış veya yabancı menşeili ürünlerde modelin güven skoru düşebilmekte ve varsayılan olarak `Diğer (Gıda Dışı)` kategorisine fallback yapabilmektedir. Kullanıcının Review ekranından manuel seçim yapması gerekebilir.

### 2. Çok Satırlı Ürünlerde Fiyat Domino Etkisi (Stack Sınır Durumları)
- **Durum:** Fişlerde ürün ismi ile fiyatı aynı satırda olmadığında ürünler stack'e atılır ve fiyat gelene kadar tamponlanır.
- **Uç Durum:** Fiş üzerinde araya 3'ten fazla alakasız açıklama/kampanya satırı girmesi durumunda tamponda aşırı yığılma yaşanabilmektedir. `TurkishReceiptParserEngine` içindeki yığın boşaltma eşiği optimize edilmektedir.

### 3. Swift 6 Concurrency & Strict Concurrency Uyarıları
- **Durum:** Kod tabanı Swift 6 dil modunda derlenmektedir.
- **İyileştirme Alanı:** `ReceiptPersistenceActor`, `ReceiptDraftStore` ve `ReceiptDevLogger` içindeki bazı senkron başlatıcı ve JSON dönüşümlerinde Xcode derleyicisi tarafından üretilen actor isolation uyarıları (`IsolatedConformances`, `ActorIsolatedCall`) bulunmaktadır. Bunlar çalışma zamanında çökme üretmemekle birlikte Swift 6 standartlarına tam uyum için modernize edilmektedir.

### 4. Buruşuk ve Düşük Işıklı Fişlerde OCR Eşik Değeri
- **Durum:** Aşırı yıpranmış, solmuş termal fişlerde Apple Vision OCR kelime güven skoru zaman zaman 0.85 eşiğinin altında kalabilmektedir. Metal görsel filtre parametrelerinin dinamik adaptasyonu üzerinde çalışılmaktadır.

---

## 🗺 Yapılacaklar ve Yol Haritası (Roadmap)

- [ ] **Model Veri Setinin Büyütülmesi:** Kategori sınıflandırma veri setinin 2.000 satırdan 10.000+ satıra çıkarılması ve CreateML üzerinde Text Classifier modeliyle yeniden eğitilmesi.
- [ ] **Swift 6 Strict Concurrency Temizliği:** Derleyici uyarılarının (warnings) sıfıra indirilmesi için DTO ve aktör protokollerinin modernize edilmesi.
- [ ] **Genişletilmiş Market Profilleri:** CarrefourSA, A101 ve yerel zincirler için spesifik regex şablonlarının eklenmesi.
- [ ] **Widget & Dynamic Island:** Fiş tarama işlemini kilit ekranından tek tıkla başlatan iOS 18 Control Widget entegrasyonu.
- [ ] **Veri Dışa Aktarımı:** Aylık harcama ve KDV dökümlerini CSV ve PDF formatında dışa aktarma (Export) yeteneği.

---

## 💻 Kurulum ve Çalıştırma

Projeyi yerel ortamınızda derleyip çalıştırmak için:

### Gereksinimler
- macOS 15.0+ (Sequoia)
- Xcode 16.0 veya üzeri
- iOS 18.0+ Simulator veya Fiziksel Cihaz

### Adımlar
1. Depoyu klonlayın:
   ```bash
   git clone https://github.com/kullanici-adiniz/Alisveris-fisTarama.git
   cd Alisveris-fisTarama
   ```
2. Projeyi Xcode ile açın:
   ```bash
   open Alisveris-fisTarama.xcodeproj
   ```
3. Target olarak `Alisveris-fisTarama` şemasını ve bir iOS 18+ simülatörünü seçin.
4. **Cmd + B** ile derleyin, **Cmd + R** ile çalıştırın. Testleri koşturmak için **Cmd + U** kısayolunu kullanın.

---

## 🔒 Gizlilik Manifestosu

- **Kamera ve Fotoğraflar:** Taranan fiş fotoğrafları yalnızca kullanıcının cihazındaki yerel uygulama dizininde saklanır.
- **Finansal Bilgiler:** Fiş üzerindeki kredi kartı son 4 hanesi veya müşteri isimleri analiz edilmez, hiçbir üçüncü taraf analitik veya reklam SDK'sı ile paylaşılmaz.
- **İnternet İzni:** Uygulama çalışmak için internet bağlantısına ihtiyaç duymaz; uçak modunda dahi tüm yapay zeka özellikleri eksiksiz çalışır.

---

## 📄 Lisans

Bu proje [MIT Lisansı](LICENSE) kapsamında açık kaynak olarak sunulmaktadır.
