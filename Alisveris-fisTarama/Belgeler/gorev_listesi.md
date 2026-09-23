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
  - [x] [1.1: Değer Tipleri, Enum'lar ve DTO Katmanı](#mikro-adım-11-değer-tipleri-enumlar-ve-dto-katmanı)
  - [x] [1.2: SwiftData Entity Şeması ve Para Formatlayıcılar](#mikro-adım-12-swiftdata-entity-şeması-ve-para-formatlayıcılar)
  - [x] [1.3: Dosya Sistemi Tabanlı Görüntü Deposu](#mikro-adım-13-dosya-sistemi-tabanl%C4%B1-g%C3%B6r%C3%BCnt%C3%BC-deposu-receiptimagediskmanager)
  - [x] [1.4: Swift 6 Eşzamanlı Kalıcılık Aktörü](#mikro-adım-14-swift-6-e%C5%9Fzamanl%C4%B1-kal%C4%B1c%C4%B1l%C4%B1k-akt%C3%B6r%C3%BC-receiptpersistenceactor)
- [ ] **FAZ 2: VisionKit Tarama ve Görüntü İyileştirme (0 / 3 Tamamlandı)**
  - [ ] [2.1: VisionKit Doküman Tarayıcı Sarmalayıcısı](#mikro-adım-21-visionkit-dok%C3%BCman-taray%C3%BDc%C4%B1-sarmalay%C3%BDc%C4%B1s%C4%B1-documentscannerview)
  - [ ] [2.2: Metal Destekli Görsel Ön İşleme Motoru](#mikro-adım-22-metal-destekli-g%C3%B6rsel-%C3%B6n-i%C5%9Fleme-motoru-receiptimagepreprocessor)
  - [ ] [2.3: Apple Vision OCR ve Geometrik Satır Gruplayıcı](#mikro-adım-23-apple-vision-ocr-ve-geometrik-sat%C4%B1r-gruplay%C4%B1c%C4%B1-receiptlinesegmenter)
- [ ] **FAZ 3: Genişletilebilir Pazar Profili ve Fiş Ayrıştırma (0 / 2 Tamamlandı)**
  - [ ] [3.1: Pazar Stratejisi Altyapısı ve Regex Kütüphaneleri](#mikro-adım-31-pazar-stratejisi-altyap%C4%B1s%C4%B1-ve-regex-k%C3%BCt%C3%BCphaneleri)
  - [ ] [3.2: Ayrıştırıcı Motor ve Güven Skorlama](#mikro-adım-32-ayr%C4%B1%C5%9Ft%C4%B1r%C4%B1c%C4%B1-motor-ve-g%C3%BCven-skorlama-receiptparserengine)
- [ ] **FAZ 4: İnteraktif Doğrulama Ekranı ve Taslak Güvenliği (0 / 3 Tamamlandı)**
  - [ ] [4.1: İki Parçalı Bölünmüş Ekran ve Durum Makinesi](#mikro-adım-41-iki-par%C3%A7al%C4%B1-b%C3%B6l%C3%BCnm%C3%BC%C5%9F-ekran-ve-durum-makinesi-reviewcorrectionview)
  - [ ] [4.2: Dokun-İncele ve Canlı Sağlama Çubuğu](#mikro-adım-42-dokun-incele-tap-to-inspect-ve-canl%C4%B1-sa%C4%9Flama-%C3%A7ubu%C4%9Fu)
  - [ ] [4.3: Kaza Kurtarma ve Taslak Deposu](#mikro-adım-43-kaza-kurtarma-ve-taslak-deposu-receiptdraftstore)
- [ ] **FAZ 5: Gösterge Paneli ve Analitik Motoru (0 / 3 Tamamlandı)**
  - [ ] [5.1: Ana Gösterge Paneli ve Fiş Geçmişi Listesi](#mikro-adım-51-ana-g%C3%B6sterge-paneli-ve-fi%C5%9F-ge%C3%A7mi%C5%9Fi-listesi)
  - [ ] [5.2: Fiyat ve Harcama Analitiği Motoru](#mikro-adım-52-fiyat-ve-harcama-analiti%C4%9Fi-motoru-swift-charts)
  - [ ] [5.3: Deterministik Harcama İçgörü Motoru](#mikro-adım-53-deterministik-harcama-i%C3%A7g%C3%B6r%C3%BC-motoru-deterministicinsightengine)
- [ ] **FAZ 6: Çok Parçalı Fiş Birleştirme, Erişilebilirlik ve Yayın (0 / 2 Tamamlandı)**
  - [ ] [6.1: Çok Parçalı Uzun Fiş Birleştirici](#mikro-adım-61-%C3%A7ok-par%C3%A7al%C4%B1-uzun-fi%C5%9F-birle%C5%9Ftirici-multipagereceiptstitcher)
  - [ ] [6.2: Erişilebilirlik ve Sürüm Profilleme](#mikro-adım-62-eri%C5%9Filebilirlik-dynamic-type--voiceover-ve-s%C3%BCr%C3%BCm-profilleme)

---

# FAZ 1: Çekirdek Veri Mimarisi ve Kalıcılık Temeli

### Mikro-Adım 1.1: Değer Tipleri, Enum'lar ve DTO Katmanı
* **Odak:** Tip güvenli enum'lar, ambalaj ayrıştırıcı, birim normalizasyonu ve aktörler arası taşınabilir `Sendable` DTO'lar.
* **İlgili Mimari Bölüm:** Bölüm 2.3 & Bölüm 3.1
* **Satır Referansları:**
  * `Sendable Bounding Box & DTO'lar` (`NormalizedRect`, `ParsedItemDTO`, `ParsedReceiptDTO`, `PriceRecordDTO`): [`mimari_tasarim.md#L137-L300`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L137-L300)
  * `PaymentMethod` Enum: [`mimari_tasarim.md#L560-L580`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L560-L580)
  * `TaxSystem` Enum: [`mimari_tasarim.md#L581-L593`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L581-L593)
  * `UnitType` Enum: [`mimari_tasarim.md#L594-L650`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L594-L650)
  * `ProductPackagingParser` (Çoklu paket $Q_{\text{norm}}$ ayrıştırma): [`mimari_tasarim.md#L652-L697`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L652-L697)
  * `UnitConverter` (Birim normalizasyonu): [`mimari_tasarim.md#L700-L740`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L700-L740)
* **Geliştirilecek Dosyalar:**
  * `Alisveris-fisTarama/Core/Models/Enums/PaymentMethod.swift`
  * `Alisveris-fisTarama/Core/Models/Enums/TaxSystem.swift`
  * `Alisveris-fisTarama/Core/Models/Enums/UnitType.swift`
  * `Alisveris-fisTarama/Core/Utilities/ProductPackagingParser.swift`
  * `Alisveris-fisTarama/Core/Utilities/UnitConverter.swift`
  * `Alisveris-fisTarama/Core/DTOs/ReceiptDTOs.swift`
* **Checklist:**
  - [x] `UnitType` enum'ına `.weight`, `.volume`, `.discrete` boyutları ve standart baz dönüşüm faktörleri eklendi.
  - [x] `UnitConverter.normalizePriceToBaseUnit` metodu çift bölme ($P / Q^2$) hatası yapmayacak şekilde kodlandı.
  - [x] Tüm DTO'lar `Sendable`, `Codable` ve `Identifiable` protokollerine bağlandı.
* **Test Komutu:**
  ```bash
  xcodebuild test -scheme Alisveris-fisTarama -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:Alisveris-fisTaramaTests/UnitConverterTests
  ```

---

### Mikro-Adım 1.2: SwiftData Entity Şeması ve Para Formatlayıcılar
* **Odak:** SwiftData `@Model` sınıflarının kodlanması, `Decimal` para hassasiyeti ve ilişki silme kuralları.
* **İlgili Mimari Bölüm:** Bölüm 3.2, 3.3, 3.4
* **Satır Referansları:**
  * `Store` Modeli: [`mimari_tasarim.md#L750-L778`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L750-L778)
  * `Category` Modeli: [`mimari_tasarim.md#L780-L825`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L780-L825)
  * `ShoppingTrip` Modeli (Para birimi, vergi ve seans): [`mimari_tasarim.md#L827-L895`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L827-L895)
  * `ShoppingItem` Modeli (Ürün satırı): [`mimari_tasarim.md#L897-L945`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L897-L945)
  * `PriceRecord` Modeli & `#Index` tanımı: [`mimari_tasarim.md#L947-L1005`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L947-L1005)
  * Silme Kuralları Tablosu: [`mimari_tasarim.md#L1015-L1040`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L1015-L1040)
  * `TurkishCurrencyNormalizer` & `NumberFormatterCache`: [`mimari_tasarim.md#L1045-L1085`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L1045-L1085)
* **Geliştirilecek Dosyalar:**
  * `Alisveris-fisTarama/Data/Persistence/Models/Store.swift`
  * `Alisveris-fisTarama/Data/Persistence/Models/Category.swift`
  * `Alisveris-fisTarama/Data/Persistence/Models/ShoppingTrip.swift`
  * `Alisveris-fisTarama/Data/Persistence/Models/ShoppingItem.swift`
  * `Alisveris-fisTarama/Data/Persistence/Models/PriceRecord.swift`
  * `Alisveris-fisTarama/Core/Formatters/CurrencyNormalizer.swift`
* **Checklist:**
  - [x] Hiçbir modelde `Double` para alanı bırakılmadı; tüm tutarlar `Decimal` yapıldı.
  - [x] `ShoppingTrip` silindiğinde kalemler cascade kuralıyla siliniyor, market ve kategori nullify ile korunuyor.
  - [x] `currencyCode` (varsayılan "TRY") ve `taxSystem` alanları eklendi.
* **Test Komutu:**
  ```bash
  xcodebuild test -scheme Alisveris-fisTarama -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:Alisveris-fisTaramaTests/ReceiptDataModelTests
  ```

---

### Mikro-Adım 1.3: Dosya Sistemi Tabanlı Görüntü Deposu (`ReceiptImageDiskManager`)
* **Odak:** Fiş fotoğraflarını veritabanı dışında, `Application Support/ReceiptImages/` altında UUID ile şifreli kaydetmek.
* **İlgili Mimari Bölüm:** Bölüm 3.5 & ADR-002
* **Satır Referansları:**
  * `ReceiptImageDiskManager` Kod Spesifikasyonu: [`mimari_tasarim.md#L1089-L1155`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L1089-L1155)
  * ADR-002 (Görüntü Depolama Karar Kaydı): [`mimari_tasarim.md#L3117-L3132`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L3117-L3132)
* **Geliştirilecek Dosyalar:**
  * `Alisveris-fisTarama/Data/Storage/ReceiptImageDiskManager.swift`
* **Checklist:**
  - [x] Fotoğraflar `.completeFileProtectionUntilFirstUserAuthentication` ile cihaz şifresine bağlandı.
  - [x] SwiftData'ya yalnızca göreceli yol (`ReceiptImages/<UUID>.jpg`) yazılıyor.
  - [x] Görsel silme metodu dosya sisteminden temizliği doğruluyor.
* **Test Komutu:**
  ```bash
  xcodebuild test -scheme Alisveris-fisTarama -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:Alisveris-fisTaramaTests/ReceiptImageDiskManagerTests
  ```

---

### Mikro-Adım 1.4: Swift 6 Eşzamanlı Kalıcılık Aktörü (`ReceiptPersistenceActor`)
* **Odak:** `@ModelActor` makrosu ile arka plan thread'inde güvenli SwiftData yazma, okuma ve silme kancaları.
* **İlgili Mimari Bölüm:** Bölüm 2.2, 2.3 & ADR-003
* **Satır Referansları:**
  * `AppContainer` DI Yapısı: [`mimari_tasarim.md#L91-L125`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L91-L125)
  * `ReceiptPersistenceActor` Tam Kod Tanımı: [`mimari_tasarim.md#L313-L545`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L313-L545)
  * ADR-003 (ModelActor İzolasyon Kararı): [`mimari_tasarim.md#L3134-L3149`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L3134-L3149)
* **Geliştirilecek Dosyalar:**
  * `Alisveris-fisTarama/Data/Persistence/ReceiptPersistenceActor.swift`
  * `Alisveris-fisTarama/App/AppContainer.swift`
* **Checklist:**
  - [x] `@ModelActor` makrosu ile arka plan `ModelContext` izole edildi.
  - [x] UI ile aktör arasında yalnızca `ParsedReceiptDTO` taşınıyor (Model nesneleri aktör dışına çıkmıyor).
  - [x] `deleteTrip` çağrıldığında diskteki görsel ve denormalize `PriceRecord` satırları atomik siliniyor.
* **Test Komutu:**
  ```bash
  xcodebuild test -scheme Alisveris-fisTarama -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:Alisveris-fisTaramaTests/ReceiptPersistenceActorTests
  ```

---

# FAZ 2: VisionKit Tarama ve Görüntü İyileştirme Hattı

### Mikro-Adım 2.1: VisionKit Doküman Tarayıcı Sarmalayıcısı (`DocumentScannerView`)
* **Odak:** Apple'ın donanım hızlandırmalı otomatik 4 köşe/kenar tespiti, otomatik deklanşör (auto-shutter), donanımsal perspektif düzeltme (keystone/dewarping) ve gölge temizleme sunan `VNDocumentCameraViewController`'ını SwiftUI içine entegre etmek; Mac simülatörü/galeri için `PHPickerViewController` fallback köprüsünü kurmak.
* **İlgili Mimari Bölüm:** Bölüm 4.1
* **Satır Referansları:**
  * `DocumentScannerView` Kod Spesifikasyonu: [`mimari_tasarim.md#L1315-L1385`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L1315-L1385)
* **Geliştirilecek Dosyalar:**
  * `Alisveris-fisTarama/Features/Scan/Views/DocumentScannerView.swift`
* **Checklist:**
  - [ ] `VNDocumentCameraViewController.isSupported` kontrolüyle fiziksel cihazda Apple Belge Tarayıcı, simülatörde `PHPickerViewController` fallback'i açılıyor.
  - [ ] Otomatik 4 köşe tespiti, auto-shutter ve donanımsal $90^\circ$ perspektif düzeltme teyit edildi (manuel OpenCV / homografi ihtiyacı sıfırlandı).
  - [ ] Çoklu sayfa desteği (`scan.pageCount`) ve iptal delegateleri bağlandı; sheet temiz kapanıyor.
  - [ ] Elde edilen dik açılı, kırpılmış temiz görsel doğrudan Vision OCR hattına aktarılıyor.
* **Doğrulama:**
  - Gerçek cihazda otomatik kenar tespiti ve auto-shutter'ın çalışması; simülatörde galeri fallback'inin açılması.

---

### Mikro-Adım 2.2: Metal Destekli Görsel Ön İşleme Motoru (`ReceiptImagePreprocessor`)
* **Odak:** `VNDocumentCameraViewController` sayesinde ağır geometrik düzeltmeler atlandığı için, bu adımda yalnızca soluk termal mürekkep, derin kat izi gölgeleri ve düşük kontrast durumlarında devreye giren hafif Metal destekli aydınlatma bölme filtresi (`CIDivideBlendMode`) ve Dinamik Sauvola ($W=31$) kontrast artırma filtresini çalıştırmak.
* **İlgili Mimari Bölüm:** Bölüm 4.1, 7.1 & ADR-008
* **Satır Referansları:**
  * `ReceiptImagePreprocessor` ve Metal Filtre Grafı: [`mimari_tasarim.md#L1383-L1495`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L1383-L1495)
  * Dinamik Sauvola Matematiksel Formülü: [`mimari_tasarim.md#L2580-L2610`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L2580-L2610)
  * ADR-008 (Sauvola ve Aydınlatma Bölme Kararı): [`mimari_tasarim.md#L3280-L3300`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L3280-L3300)
* **Geliştirilecek Dosyalar:**
  * `Alisveris-fisTarama/Services/ImageProcessing/ReceiptImagePreprocessor.swift`
* **Checklist:**
  - [ ] CIContext Metal cihazı üzerinden başlatılarak CPU darboğazı önlendi.
  - [ ] Kat izi gölgeleri homojenize edildi; soluk termal yazılar Dinamik Sauvola ile belirginleştirildi.
* **Test Komutu:**
  ```bash
  xcodebuild test -scheme Alisveris-fisTarama -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:Alisveris-fisTaramaTests/ReceiptImagePreprocessorTests
  ```

---

### Mikro-Adım 2.3: Apple Vision OCR ve Geometrik Satır Gruplayıcı (`ReceiptLineSegmenter`)
* **Odak:** `VNRecognizeTextRequest` çalıştırmak, eğim açısını ($\theta$) tespit edip telafi etmek ve dikey medyan toleransı ($\delta Y$) ile kelimeleri yatay satırlarda birleştirmek.
* **İlgili Mimari Bölüm:** Bölüm 4.2, 4.3
* **Satır Referansları:**
  * `ReceiptOCRService` & Perakende Sözlüğü: [`mimari_tasarim.md#L1360-L1405`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L1360-L1405)
  * Geometrik Dönüşüm ve $\delta Y$ Formülleri: [`mimari_tasarim.md#L1410-L1425`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L1410-L1425)
  * `ReceiptLineSegmenter` ve Rotasyonel Kümeleme Kodu: [`mimari_tasarim.md#L1426-L1620`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L1426-L1620)
* **Geliştirilecek Dosyalar:**
  * `Alisveris-fisTarama/Services/OCR/ReceiptOCRService.swift`
  * `Alisveris-fisTarama/Services/OCR/ReceiptLineSegmenter.swift`
* **Checklist:**
  - [ ] Vision sol-alt orijinli koordinatları, UIKit üstten orijinli piksel uzayına tek geçişte çevrildi.
  - [ ] Eğik çekilmiş fişlerde dominant eğim açısı $\theta$ telafi edilerek satır kopmaları önlendi.
* **Test Komutu:**
  ```bash
  xcodebuild test -scheme Alisveris-fisTarama -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:Alisveris-fisTaramaTests/ReceiptLineSegmenterTests
  ```

---

# FAZ 3: Genişletilebilir Pazar Profili ve Fiş Ayrıştırma

### Mikro-Adım 3.1: Pazar Stratejisi Altyapısı ve Regex Kütüphaneleri
* **Odak:** `RetailMarketProfile` protokolü, `TurkeyRetailProfile` kuralları, `GlobalRetailProfile` şablonu ve Türkçe kısaltma temizleyicisi.
* **İlgili Mimari Bölüm:** Bölüm 4.4 & ADR-009
* **Satır Referansları:**
  * `TurkishProductNameCleaner`: [`mimari_tasarim.md#L1625-L1648`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L1625-L1648)
  * `RetailMarketProfile` Protokolü: [`mimari_tasarim.md#L1651-L1670`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L1651-L1670)
  * `TurkeyRetailProfile` (BİM, A101, Şok, Migros, CarrefourSA): [`mimari_tasarim.md#L1672-L1705`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L1672-L1705)
  * `GlobalRetailProfile` (ABD/AB Küresel Şablonu): [`mimari_tasarim.md#L1708-L1745`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L1708-L1745)
  * ADR-009 (Pazar Stratejisi Karar Kaydı): [`mimari_tasarim.md#L3197-L3210`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L3197-L3210)
* **Geliştirilecek Dosyalar:**
  * `Alisveris-fisTarama/Services/Parser/Profiles/RetailMarketProfile.swift`
  * `Alisveris-fisTarama/Services/Parser/Profiles/TurkeyRetailProfile.swift`
  * `Alisveris-fisTarama/Services/Parser/Profiles/GlobalRetailProfile.swift`
  * `Alisveris-fisTarama/Services/Parser/Cleaners/TurkishProductNameCleaner.swift`
* **Checklist:**
  - [ ] Kısaltmalar ("SUT" -> "SÜT", "YMRTA" -> "YUMURTA") başarıyla genişletiliyor.
  - [ ] 5 büyük market zincirinin VKN ve regex şablonları profile bağlandı.
* **Test Komutu:**
  ```bash
  xcodebuild test -scheme Alisveris-fisTarama -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:Alisveris-fisTaramaTests/MarketProfileRegexTests
  ```

---

### Mikro-Adım 3.2: Ayrıştırıcı Motor ve Güven Skorlama (`ReceiptParserEngine`)
* **Odak:** Kümelenmiş satırları profilden gelen kurallarla ayrıştırarak `ParsedReceiptDTO` üretmek ve $C_{\text{composite}}$ skorunu hesaplamak.
* **İlgili Mimari Bölüm:** Bölüm 4.4 & 4.5
* **Satır Referansları:**
  * `TurkishReceiptParserEngine` Satır Ayrıştırma Döngüsü: [`mimari_tasarim.md#L1750-L1950`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L1750-L1950)
  * İki Satırlı Kayan Pencere (Tartı ve Çarpan Eşleme): [`mimari_tasarim.md#L1780-L1830`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L1780-L1830)
  * Kompozit Güven Skoru ($C_{\text{composite}}$) Formülü ve Kod: [`mimari_tasarim.md#L1960-L2030`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L1960-L2030)
* **Geliştirilecek Dosyalar:**
  * `Alisveris-fisTarama/Services/Parser/ReceiptParserEngine.swift`
* **Checklist:**
  - [ ] Genel toplam, ara toplam ve vergi satırları ürün listesinden temizlendi.
  - [ ] İndirim satırları eksi bakiye kontrolüyle güvenli ayrıştırıldı.
  - [ ] Aritmetik bakiye tutuyorsa $C_{\text{arith}} = 1.0$, tutmuyorsa $0.0$ verilerek skor hesaplandı.
* **Test Komutu:**
  ```bash
  xcodebuild test -scheme Alisveris-fisTarama -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:Alisveris-fisTaramaTests/ReceiptParserEngineBenchmarkTests
  ```

---

# FAZ 4: İnteraktif Doğrulama Ekranı ve Taslak Güvenliği

### Mikro-Adım 4.1: İki Parçalı Bölünmüş Ekran ve Durum Makinesi (`ReviewCorrectionView`)
* **Odak:** Üstte fiş görseli (`%45`), altta ürün listesi (`%55`) içeren arayüz ve 9 durumlu `ReceiptState` FSM akışını kurmak.
* **İlgili Mimari Bölüm:** Bölüm 6.1 & 6.2
* **Satır Referansları:**
  * 9 Durumlu FSM (`ReceiptState`): [`mimari_tasarim.md#L2330-L2380`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L2330-L2380)
  * Bölünmüş Ekran SwiftUI Arayüz İskeleti: [`mimari_tasarim.md#L2385-L2445`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L2385-L2445)
* **Geliştirilecek Dosyalar:**
  * `Alisveris-fisTarama/Features/Review/Models/ReceiptState.swift`
  * `Alisveris-fisTarama/Features/Review/ViewModels/ReviewCorrectionViewModel.swift`
  * `Alisveris-fisTarama/Features/Review/Views/ReviewCorrectionView.swift`
* **Checklist:**
  - [ ] Kalem fiyatı, adı, miktarı satır içi dokunarak düzenlenebiliyor.
  - [ ] Kalem silme, ekleme ve genel toplam alanları düzenlenebiliyor.
* **Doğrulama:**
  - Mock `ParsedReceiptDTO` verisiyle SwiftUI Preview üzerinde arayüz testleri.

---

### Mikro-Adım 4.2: Dokun-İncele (Tap-to-Inspect) ve Canlı Sağlama Çubuğu
* **Odak:** Listeden bir kaleme dokunulduğunda fiş görselinin ilgili satıra yaylanmalı odaklanması ($2\times$ zoom); canlı bakiye farkı ($\Delta$) göstergesi.
* **İlgili Mimari Bölüm:** Bölüm 6.3 & 6.4
* **Satır Referansları:**
  * Aspect-Fit Letterbox Projeksiyonu Formülü ($s, \Delta X, \Delta Y$): [`mimari_tasarim.md#L2450-L2485`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L2450-L2485)
  * Canlı Sağlama Çubuğu ($\Delta = |S_{\text{items}} - T|$) Formülü: [`mimari_tasarim.md#L2490-L2510`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L2490-L2510)
* **Geliştirilecek Dosyalar:**
  * `Alisveris-fisTarama/Features/Review/Components/ZoomableReceiptImageView.swift`
  * `Alisveris-fisTarama/Features/Review/Components/LiveBalancingBarView.swift`
* **Checklist:**
  - [ ] Kalem seçildiğinde görsel piksel sapması olmadan kutucuğu ekranın ortasına getiriyor.
  - [ ] Kalem toplamı fiş toplamına eşit olduğunda çubuk yeşile, fark varsa sarı/kırmızıya dönüyor.
* **Test Komutu:**
  ```bash
  xcodebuild test -scheme Alisveris-fisTarama -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:Alisveris-fisTaramaUITests/ReviewCorrectionInteractionTests
  ```

---

### Mikro-Adım 4.3: Kaza Kurtarma ve Taslak Deposu (`ReceiptDraftStore`)
* **Odak:** Kullanıcı düzenleme yaparken telefon çaldığında veya uygulama kapandığında verilerin diske debounced flush edilmesi (`scenePhase == .background`).
* **İlgili Mimari Bölüm:** Bölüm 7.3 & ADR-007
* **Satır Referansları:**
  * `ReceiptDraftStore` Kod Spesifikasyonu: [`mimari_tasarim.md#L2650-L2745`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L2650-L2745)
  * Arka Plan Yaşam Döngüsü Kancası (`beginBackgroundTask`): [`mimari_tasarim.md#L2748-L2775`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L2748-L2775)
  * ADR-007 (Taslak Deposu Karar Kaydı): [`mimari_tasarim.md#L3165-L3178`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L3165-L3178)
* **Geliştirilecek Dosyalar:**
  * `Alisveris-fisTarama/Data/Storage/ReceiptDraftStore.swift`
  * `Alisveris-fisTarama/App/AppLifecycleObserver.swift`
* **Checklist:**
  - [ ] `DraftScans/<UUID>/` dizininde görsel ve `draft.json` atomik yazılıyor.
  - [ ] Uygulama yeniden açıldığında kaydedilmemiş taslak sorulup kurtarılıyor.
* **Test Komutu:**
  ```bash
  xcodebuild test -scheme Alisveris-fisTarama -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:Alisveris-fisTaramaTests/ReceiptDraftStoreTests
  ```

---

# FAZ 5: Gösterge Paneli ve Analitik Motoru

### Mikro-Adım 5.1: Ana Gösterge Paneli ve Fiş Geçmişi Listesi
* **Odak:** `HomeDashboardView` (Cari ay toplamı, MTD barı, hızlı tara CTA'sı) ve `TripHistoryView` (aranabilir, filtrelenebilir fiş listesi).
* **İlgili Mimari Bölüm:** Bölüm 5.1 & Faz 4 Özeti
* **Satır Referansları:**
  * MTD ve Harcama Göstergeleri: [`mimari_tasarim.md#L2045-L2085`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L2045-L2085)
  * Geçmiş Listesi ve Arama Spesifikasyonu: [`mimari_tasarim.md#L3020-L3040`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L3020-L3040)
* **Geliştirilecek Dosyalar:**
  * `Alisveris-fisTarama/Features/Dashboard/Views/HomeDashboardView.swift`
  * `Alisveris-fisTarama/Features/Dashboard/ViewModels/HomeDashboardViewModel.swift`
  * `Alisveris-fisTarama/Features/History/Views/TripHistoryView.swift`
  * `Alisveris-fisTarama/Features/History/Views/TripDetailView.swift`
* **Checklist:**
  - [ ] SwiftData `@Query` ile yeni eklenen fiş anında ana sayfada toplamı modelliyor.
  - [ ] Fiş detayında kayıtlı fiş görseli büyütülebilir biçimde gösteriliyor.
* **Doğrulama:**
  - SwiftData simülatöründe 5 farklı fiş ekleyip silerek reaktif liste güncellemelerinin kontrolü.

---

### Mikro-Adım 5.2: Fiyat ve Harcama Analitiği Motoru (Swift Charts)
* **Odak:** Ağırlıklı Laspeyres Sepeti kişisel market enflasyonu ($I_L^t$), HHI market bağımlılık endeksi ve Swift Charts grafikleri.
* **İlgili Mimari Bölüm:** Bölüm 5.2, 5.3 & ADR-004
* **Satır Referansları:**
  * Bayesyen Harcama Hızı Yumuşatması ($V_w$): [`mimari_tasarim.md#L2086-L2115`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L2086-L2115)
  * Ağırlıklı Laspeyres Enflasyon Modeli: [`mimari_tasarim.md#L2120-L2180`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L2120-L2180)
  * HHI Mağaza Bağımlılık Skoru ($<3000, 3000-5500, >5500$): [`mimari_tasarim.md#L2185-L2220`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L2185-L2220)
  * ADR-004 (Laspeyres Karar Kaydı): [`mimari_tasarim.md#L3151-L3163`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L3151-L3163)
* **Geliştirilecek Dosyalar:**
  * `Alisveris-fisTarama/Services/Analytics/PeriodicAnalyticsService.swift`
  * `Alisveris-fisTarama/Services/Analytics/PersonalInflationEngine.swift`
  * `Alisveris-fisTarama/Services/Analytics/StorePreferenceService.swift`
  * `Alisveris-fisTarama/Features/Analytics/Views/AnalyticsChartsView.swift`
* **Checklist:**
  - [ ] Sıfıra bölme durumlarında formüller asla $NaN$ veya $Infinity$ üretmiyor.
  - [ ] Ayın ilk günlerinde harcama projeksiyonu Bayesyen yumuşatma ile dengeleniyor.
* **Test Komutu:**
  ```bash
  xcodebuild test -scheme Alisveris-fisTarama -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:Alisveris-fisTaramaTests/AnalyticsEngineMathTests
  ```

---

### Mikro-Adım 5.3: Deterministik Harcama İçgörü Motoru (`DeterministicInsightEngine`)
* **Odak:** Veriler üzerinde çalışan 5 kural (harcama sıçraması, baskın kategori, market riski) ve 7 günlük cooldown filtresi.
* **İlgili Mimari Bölüm:** Bölüm 5.4 & 5.5
* **Satır Referansları:**
  * Deterministik 5 Kural Spesifikasyonu: [`mimari_tasarim.md#L2225-L2280`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L2225-L2280)
  * Cooldown ve Önceliklendirme Motoru: [`mimari_tasarim.md#L2285-L2325`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L2285-L2325)
* **Geliştirilecek Dosyalar:**
  * `Alisveris-fisTarama/Services/Insights/DeterministicInsightEngine.swift`
  * `Alisveris-fisTarama/Features/Dashboard/Components/InsightCardView.swift`
* **Checklist:**
  - [ ] Aynı ürün veya kategoriye ait içgörü 7 gün geçmeden ikinci kez üretilmiyor.
  - [ ] En yüksek öncelikli içgörü ana sayfada kart olarak gösteriliyor.
* **Test Komutu:**
  ```bash
  xcodebuild test -scheme Alisveris-fisTarama -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:Alisveris-fisTaramaTests/DeterministicInsightEngineTests
  ```

---

# FAZ 6: Çok Parçalı Fiş Birleştirme, Erişilebilirlik ve Yayın

### Mikro-Adım 6.1: Çok Parçalı Uzun Fiş Birleştirici (`MultiPageReceiptStitcher`)
* **Odak:** 50+ kalemlik uzun fişlerin sınır çakışmalarını Smith-Waterman kayan penceresi ve sağlama kontrolü ile birleştirmek.
* **İlgili Mimari Bölüm:** Bölüm 7.2 & ADR-006
* **Satır Referansları:**
  * `MultiPageReceiptStitcher` Kod Spesifikasyonu: [`mimari_tasarim.md#L2525-L2645`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L2525-L2645)
  * ADR-006 (Smith-Waterman Birleştirme Karar Kaydı): [`mimari_tasarim.md#L3180-L3195`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L3180-L3195)
* **Geliştirilecek Dosyalar:**
  * `Alisveris-fisTarama/Services/Stitching/MultiPageReceiptStitcher.swift`
* **Checklist:**
  - [ ] 3 harf ve daha kısa kelimelerde (TUZ/MUZ, CAY/YAG) tam eşitlik şartı korunuyor.
  - [ ] Genel toplam farkı $|\sum P_i - T| \le 0.05$ TL sağlama kontrolünden geçiyor.
* **Test Komutu:**
  ```bash
  xcodebuild test -scheme Alisveris-fisTarama -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:Alisveris-fisTaramaTests/MultiPageStitchingTests
  ```

---

### Mikro-Adım 6.2: Erişilebilirlik (Dynamic Type / VoiceOver) ve Sürüm Profilleme
* **Odak:** Dynamic Type XXL, VoiceOver erişilebilirlik etiketleri, Instruments bellek sızıntısı denetimi ve sıfır derleme uyarısı.
* **İlgili Mimari Bölüm:** Bölüm 7.1, 7.3 & Faz 6 Özeti
* **Satır Referansları:**
  * Erişilebilirlik ve Performans Kriterleri: [`mimari_tasarim.md#L3075-L3100`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/mimari_tasarim.md#L3075-L3100)
* **Checklist:**
  - [ ] Ekran okuyucu (VoiceOver) tüm buton ve fiş kalemlerini doğru okuyor.
  - [ ] Swift 6 Strict Concurrency altında sıfır uyarı ile release build alınıyor.
* **Sürüm Derleme Komutu:**
  ```bash
  xcodebuild build -scheme Alisveris-fisTarama -destination 'generic/platform=iOS' -configuration Release SWIFT_STRICT_CONCURRENCY=complete
  ```
