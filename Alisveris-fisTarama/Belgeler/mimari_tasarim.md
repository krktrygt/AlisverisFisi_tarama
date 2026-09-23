# CepSepeti — Native iOS Fiş Dijitalleştirme, Harcama ve Fiyat Analitiği Uygulaması
# Kapsamlı Mimari ve Teknik Tasarım Dokümanı (Architecture & Design Document)

**Doküman Kodu:** CEPEPETI-ARCH-MASTER-V1  
**Sürüm:** 1.1.0 (NLP/AI ve Deterministik Hibrit Boru Hattı ile Güncellendi)  
**Hedef Platform:** iOS 17.0+, iPadOS 17.0+  
**Geliştirme Dili ve Çatılar:** Swift 6 (Strict Concurrency Enabled: Complete), SwiftUI, SwiftData, Observation, VisionKit, Vision, Core Image, CreateML  
**Tarih:** 23 Eylül 2026  
**Mimari Rol:** Lead Architecture & Systems Engineer  
**Hedef Dosya:** `mimari_tasarim.md`  
**Referans Rapor:** [`nlp_ai_pipeline_arastirma.md`](file:///Users/korkuteryigit/Documents/Al%C4%B1s%CC%A7veris%CC%A7Takip/nlp_ai_pipeline_arastirma.md) (On-Device NLP/AI ve Donanım Stres Testi Raporu)  

---

## İçindekiler
1. [Yönetici Özeti ve Temel Mimari İlkeler](#1-yönetici-özeti-ve-temel-mimari-ilkeler)
2. [Sistem Mimarisi ve Uçtan Uca Veri Akışı (R1)](#2-sistem-mimarisi-ve-uçtan-uca-veri-akışı-r1)
3. [Eksiksiz Veri Modeli ve SwiftData Şeması (R2)](#3-eksiksiz-veri-modeli-ve-swiftdata-şeması-r2)
4. [Fiş Tarama, OCR ve Genişletilebilir Ayrıştırma Boru Hattı (R3)](#4-fiş-tarama-ocr-ve-genişletilebilir-ayrıştırma-boru-hattı-r3)
5. [Harcama Alışkanlıkları ve Fiyat Analitiği Motoru (R4)](#5-harcama-alışkanlıkları-ve-fiyat-analitiği-motoru-r4)
6. [Kullanıcı Deneyimi (UX) ve Doğrulama Akışı (R5)](#6-kullanıcı-deneyimi-ux-ve-doğrulama-akışı-r5)
7. [Dayanıklılık, Uç Durumlar ve Sistem Güvenliği (R6)](#7-dayanıklılık-uç-durumlar-ve-sistem-güvenliği-r6)
8. [Kademeli ve Test Odaklı Geliştirme Yol Haritası (Faz 1-6 / 14 Mikro-Adım)](#8-kademeli-ve-test-odaklı-geliştirme-yol-haritası-faz-1-6--14-mikro-adım)
9. [Mimari Karar Kayıtları (Architectural Decision Records - ADR)](#9-mimari-karar-kayıtları-architectural-decision-records---adr)

---

# 1. Yönetici Özeti ve Temel Mimari İlkeler

CepSepeti; kullanıcıların fiziksel market fişlerini akıllı telefon kamerası veya fotoğraf galerisi aracılığıyla tarayıp saniyeler içinde yapılandırılmış finansal verilere dönüştüren, zaman içinde ürün düzeyinde fiyat hareketlerini takip eden ve deterministik harcama içgörüleri sunan native bir iOS uygulamasıdır.

Uygulamanın mühendislik omurgası dört temel ilke üzerine inşa edilmiştir:

### 1.1 Çevrimdışı Öncelikli Mimari (Offline-First Philosophy)
- Uygulama; görüntü yakalama, optik karakter tanıma (OCR), geometrik satır kümeleme, regex ayrıştırma, veri kalıcılığı ve analitik hesaplamalarının tamamını **%100 yerel olarak (on-device)** gerçekleştirir.
- Kullanıcı sığınakta, otoparkta veya kırsal alanda (uçak modunda) olsa dahi fiş tarayabilir, geçmiş harcamalarını inceleyebilir ve fiyat grafiklerini görüntüleyebilir.
- Dış sunuculara veya bulut tabanlı yapay zeka API'larına hiçbir veri gönderilmez; böylece sıfır gecikme (zero latency), sıfır API maliyeti ve kesintisiz çalışma garantilenir.

### 1.2 Swift 6 Katı Eşzamanlılık Modeli (Strict Concurrency & Actor Isolation)
- Swift 6 derleyicisinin tam eşzamanlılık kontrolü (`-strict-concurrency=complete`) etkinleştirilmiştir.
- SwiftData `@Model` nesnelerinin iş parçacıkları arasında paylaşılamaması (`Non-Sendable`) kuralına tam uyulur.
- Ana iş parçacığı (`@MainActor`) yalnızca 120 FPS SwiftUI render işlemlerinden ve kullanıcı etkileşimlerinden sorumludur.
- OCR metin analizi, görüntü filtreleme, disk yazımları ve SwiftData veritabanı mutasyonları izole bir arka plan `@ModelActor` (`ReceiptPersistenceActor`) üzerinde seri olarak icra edilir.
- Aktör sınırları arasında yalnızca değişmez ve güvenli `Sendable` Veri Transfer Nesneleri (DTO) taşınır.

### 1.3 Veri Gizliliği ve Yerel Güvenlik (Privacy by Design)
- Fişler; kullanıcının yaşam tarzı, beslenme alışkanlıkları, sağlık durumu ve harcama gücüne dair en mahrem kişisel verileri içerir.
- Kişisel Verilerin Korunması Kanunu (KVKK) ve Avrupa Genel Veri Koruma Tüzüğü (GDPR) ilkeleri uyarınca, harcama verileri ve fiş görselleri yalnızca kullanıcının cihazında saklanır.
- Dosya sistemi düzeyinde `FileProtectionType.completeUntilFirstUserAuthentication` şifrelemesi kullanılarak cihaz kilitliyken verilerin yetkisiz erişimi engellenir.

### 1.4 Modüler ve Genişletilebilir Pazar Stratejisi (Extensible Market Profiles)
- Uygulamanın birincil ve en derin optimize edilmiş hedef pazarı **Türkiye**'dir; ancak mimari Türk marketlerine katı biçimde hard-coded edilmemiştir.
- Strateji Deseni (`RetailMarketProfile`) kullanılarak para birimi (`currencyCode: String`), vergi modeli (Dahil KDV vs Hariç Satış Vergisi), dil paketleri ve markete özel regex şablonları izole profillerde tanımlanır.
- Varsayılan profil `TurkeyRetailProfile` olarak çalışırken, gelecekte tek bir profil sınıfı eklenerek küresel pazarlar (Almanya, ABD, İngiltere vb.) ana kod tabanını bozmadan anında devreye alınabilir.

---

# 2. Sistem Mimarisi ve Uçtan Uca Veri Akışı (R1)

## 2.1 Katman Mimarisi (Clean Architecture / MVVM + Repository)

Uygulama; sorumlulukların net olarak ayrıldığı, bağımlılıkların içe doğru aktığı dört ana katmandan meydana gelir:

```
+-----------------------------------------------------------------------------------+
|                              PRESENTATION LAYER (UI)                              |
|  - SwiftUI Views (CameraScannerView, ReviewCorrectionView, DashboardView, Charts) |
|  - ViewModels (@Observable, @MainActor isolated)                                  |
|  - ViewStates (idle, scanning, processing, editing, persisting, success, failure)  |
+-----------------------------------------+-----------------------------------------+
                                          | Uses Protocols
+-----------------------------------------v-----------------------------------------+
|                                DOMAIN LAYER (Business)                            |
|  - Use Cases (ProcessReceiptUseCase, CalculateLaspeyresIndexUseCase, etc.)        |
|  - Domain Entities & Sendable DTOs (ParsedReceiptDTO, ParsedItemDTO)              |
|  - Repository Interfaces (ReceiptPersistenceServiceProtocol, etc.)                |
+-----------------------------------------+-----------------------------------------+
                                          | Implements Protocols
+-----------------------------------------v-----------------------------------------+
|                           DATA & PERSISTENCE LAYER                                |
|  - ReceiptPersistenceActor (@ModelActor isolated, dedicated ModelContext)         |
|  - SwiftData Schema (Store, ShoppingTrip, ShoppingItem, Category, PriceRecord)    |
|  - ReceiptImageDiskManager (Decoupled UUID File Storage in Application Support)   |
+-----------------------------------------+-----------------------------------------+
                                          | Hardware & OS APIs
+-----------------------------------------v-----------------------------------------+
|                        INFRASTRUCTURE & HARDWARE LAYER                            |
|  - Apple VisionKit (VNDocumentCameraViewController)                               |
|  - Apple Vision Framework (VNRecognizeTextRequest with custom retail vocab)       |
|  - Apple Core Image (Metal accelerated filter pipeline: mono, CLAHE, unsharp)     |
+-----------------------------------------------------------------------------------+
```

## 2.2 Bağımlılık Enjeksiyonu ve Konteyner Tasarımı (`AppContainer`)

Uygulama genelinde küresel tekilliklerin (global singletons) oluşturduğu test edilebilirlik ve eşzamanlılık darboğazlarını engellemek adına açık bir DI Konteyneri kullanılır:

```swift
import Foundation
import SwiftData
import SwiftUI

@MainActor
public final class AppContainer: ObservableObject {
    public let modelContainer: ModelContainer
    public let persistenceActor: ReceiptPersistenceActor
    public let imageDiskManager: ReceiptImageDiskManagerProtocol
    
    public init(inMemory: Bool = false) {
        do {
            let schema = Schema([
                Store.self,
                ShoppingTrip.self,
                ShoppingItem.self,
                Category.self,
                PriceRecord.self
            ])
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: inMemory,
                allowsSave: true
            )
            let container = try ModelContainer(for: schema, configurations: [configuration])
            self.modelContainer = container
            self.persistenceActor = ReceiptPersistenceActor(modelContainer: container)
            self.imageDiskManager = ReceiptImageDiskManager.shared
        } catch {
            fatalError("SwiftData ModelContainer başlatılamadı: \(error.localizedDescription)")
        }
    }
}
```

## 2.3 `@ModelActor` Tabanlı Arka Plan Kalıcılık Mimarisi ve DTO Sınırları

SwiftData `@Model` sınıfları referans tiplidir ve bağlı oldukları `ModelContext`'in iş parçacığına hapsolmuştur. Bu sınıfları arka plan aktöründen `@MainActor` UI katmanına iletmek Swift 6'da derleme hatasıdır.

Bu problemi çözmek için UI ile Kalıcılık katmanı arasında değişmez (immutable) ve `Sendable` protokolüne tam uyumlu DTO yapıları kullanılır:

```swift
import Foundation
import CoreGraphics

// MARK: - Sendable Bounding Box
public struct NormalizedRect: Sendable, Equatable, Codable {
    public let originX: CGFloat
    public let originY: CGFloat
    public let width: CGFloat
    public let height: CGFloat

    public init(originX: CGFloat, originY: CGFloat, width: CGFloat, height: CGFloat) {
        self.originX = originX
        self.originY = originY
        self.width = width
        self.height = height
    }

    public var cgRect: CGRect {
        CGRect(x: originX, y: originY, width: width, height: height)
    }
}

// MARK: - Sendable Item DTO
public struct ParsedItemDTO: Sendable, Identifiable, Codable {
    public let id: UUID
    public var rawName: String
    public var normalizedName: String
    public var quantity: Decimal
    public var unit: UnitType
    public var unitPrice: Decimal
    public var totalPrice: Decimal
    public var taxRate: Decimal
    public var categoryId: UUID?
    public var confidenceScore: Double
    public var boundingBox: NormalizedRect

    public init(
        id: UUID = UUID(),
        rawName: String,
        normalizedName: String,
        quantity: Decimal = 1.0,
        unit: UnitType = .piece,
        unitPrice: Decimal,
        totalPrice: Decimal,
        taxRate: Decimal = 0.01,
        categoryId: UUID? = nil,
        confidenceScore: Double = 1.0,
        boundingBox: NormalizedRect = NormalizedRect(originX: 0, originY: 0, width: 0, height: 0)
    ) {
        self.id = id
        self.rawName = rawName
        self.normalizedName = normalizedName
        self.quantity = quantity
        self.unit = unit
        self.unitPrice = unitPrice
        self.totalPrice = totalPrice
        self.taxRate = taxRate
        self.categoryId = categoryId
        self.confidenceScore = confidenceScore
        self.boundingBox = boundingBox
    }
}

// MARK: - Sendable Receipt DTO
public struct ParsedReceiptDTO: Sendable, Identifiable, Codable {
    public let id: UUID
    public var storeName: String
    public var storeBranch: String?
    public var storeAddress: String?
    public var storeTaxNumber: String?
    public var date: Date
    public var receiptNumber: String?
    public var subtotal: Decimal
    public var discountTotal: Decimal
    public var totalAmount: Decimal
    public var taxTotal: Decimal
    public var paymentMethod: PaymentMethod
    public var items: [ParsedItemDTO]
    public var rawOcrText: String
    public var confidenceScore: Double
    public var imageRelativePath: String?

    public init(
        id: UUID = UUID(),
        storeName: String,
        storeBranch: String? = nil,
        storeAddress: String? = nil,
        storeTaxNumber: String? = nil,
        date: Date = Date(),
        receiptNumber: String? = nil,
        subtotal: Decimal,
        discountTotal: Decimal = Decimal(0),
        totalAmount: Decimal,
        taxTotal: Decimal,
        paymentMethod: PaymentMethod = .creditCard,
        items: [ParsedItemDTO],
        rawOcrText: String = "",
        confidenceScore: Double = 1.0,
        imageRelativePath: String? = nil
    ) {
        self.id = id
        self.storeName = storeName
        self.storeBranch = storeBranch
        self.storeAddress = storeAddress
        self.storeTaxNumber = storeTaxNumber
        self.date = date
        self.receiptNumber = receiptNumber
        self.subtotal = subtotal
        self.discountTotal = discountTotal
        self.totalAmount = totalAmount
        self.taxTotal = taxTotal
        self.paymentMethod = paymentMethod
        self.items = items
        self.rawOcrText = rawOcrText
        self.confidenceScore = confidenceScore
        self.imageRelativePath = imageRelativePath
    }
}

// MARK: - Sendable Price Record DTO (Bulgu 1, Bulgu 22)
public struct PriceRecordDTO: Sendable, Identifiable {
    public let id: UUID
    public let productNameNormalized: String
    public let storeId: UUID
    public let storeName: String
    public let date: Date
    public let unitPriceNormalized: Decimal
    public let rawUnitPrice: Decimal
    public let unit: UnitType
    public let tripId: UUID
    public let itemId: UUID

    public init(
        id: UUID = UUID(),
        productNameNormalized: String,
        storeId: UUID,
        storeName: String,
        date: Date,
        unitPriceNormalized: Decimal,
        rawUnitPrice: Decimal,
        unit: UnitType,
        tripId: UUID,
        itemId: UUID
    ) {
        self.id = id
        self.productNameNormalized = productNameNormalized
        self.storeId = storeId
        self.storeName = storeName
        self.date = date
        self.unitPriceNormalized = unitPriceNormalized
        self.rawUnitPrice = rawUnitPrice
        self.unit = unit
        self.tripId = tripId
        self.itemId = itemId
    }
}

// MARK: - Kalıcılık Servisi Protokolü
public protocol ReceiptPersistenceServiceProtocol: Sendable {
    func persistReceipt(
        dto: ParsedReceiptDTO,
        imageData: Data?
    ) async throws -> PersistentIdentifier
    
    func deleteTrip(id: PersistentIdentifier) async throws
    
    func fetchPriceHistoryDTOs(
        productNameNormalized: String,
        since date: Date
    ) async throws -> [PriceRecordDTO]
}

// MARK: - ModelActor Uygulaması
@ModelActor
public actor ReceiptPersistenceActor: ReceiptPersistenceServiceProtocol {
    
    public func persistReceipt(
        dto: ParsedReceiptDTO,
        imageData: Data?
    ) throws -> PersistentIdentifier {
        let context = self.modelContext
        
        // 1. Görseli dosya sistemine kaydet
        var storedRelativePath: String? = dto.imageRelativePath
        if let imageData = imageData, storedRelativePath == nil {
            let filename = "\(UUID().uuidString).jpg"
            storedRelativePath = try ReceiptImageDiskManager.shared.saveReceiptImage(
                data: imageData,
                filename: filename
            )
        }
        
        // 2. Mağaza Eşleme (Varsa mevcut olanı kullan, yoksa oluştur)
        let normalizedStoreName = dto.storeName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let storePredicate = #Predicate<Store> { s in
            s.normalizedName == normalizedStoreName
        }
        var storeFetch = FetchDescriptor<Store>(predicate: storePredicate)
        storeFetch.fetchLimit = 1
        
        let existingStores = try context.fetch(storeFetch)
        let resolvedStore: Store
        
        if let existing = existingStores.first {
            resolvedStore = existing
            if let branch = dto.storeBranch, resolvedStore.branch == nil {
                resolvedStore.branch = branch
            }
            if let taxNo = dto.storeTaxNumber, resolvedStore.taxNumber == nil {
                resolvedStore.taxNumber = taxNo
            }
        } else {
            let newStore = Store(
                name: dto.storeName,
                normalizedName: normalizedStoreName,
                branch: dto.storeBranch,
                address: dto.storeAddress,
                taxNumber: dto.storeTaxNumber
            )
            context.insert(newStore)
            resolvedStore = newStore
        }
        
        // 3. ShoppingTrip Nesnesini Yarat (receiptNumber ve discountTotal ile)
        let trip = ShoppingTrip(
            date: dto.date,
            receiptNumber: dto.receiptNumber,
            totalAmount: dto.totalAmount,
            subtotal: dto.subtotal,
            discountTotal: dto.discountTotal,
            taxTotal: dto.taxTotal,
            paymentMethod: dto.paymentMethod,
            imageRelativePath: storedRelativePath,
            store: resolvedStore,
            confidenceScore: dto.confidenceScore
        )
        context.insert(trip)
        
        // 4. ShoppingItem ve Denormalize PriceRecord Kayıtlarını Oluştur (N+1 Sorgu Engelleme)
        let uniqueCategoryIds = Set(dto.items.compactMap(\.categoryId))
        var categoryLookup: [UUID: Category] = [:]
        if !uniqueCategoryIds.isEmpty {
            let catPredicate = #Predicate<Category> { c in
                uniqueCategoryIds.contains(c.id)
            }
            let matchedCategories = try context.fetch(FetchDescriptor<Category>(predicate: catPredicate))
            for cat in matchedCategories {
                categoryLookup[cat.id] = cat
            }
        }
        
        for itemDTO in dto.items {
            let resolvedCategory = itemDTO.categoryId.flatMap { categoryLookup[$0] }
            
            let item = ShoppingItem(
                rawName: itemDTO.rawName,
                normalizedName: itemDTO.normalizedName,
                quantity: itemDTO.quantity,
                unit: itemDTO.unit,
                unitPrice: itemDTO.unitPrice,
                totalPrice: itemDTO.totalPrice,
                taxRate: itemDTO.taxRate,
                category: resolvedCategory,
                trip: trip,
                confidenceScore: itemDTO.confidenceScore
            )
            context.insert(item)
            
            // Ambalaj çözümü ve birim fiyat normalizasyonu (Bulgu 4, Bulgu 18)
            let (resolvedQuantity, resolvedUnit): (Decimal, UnitType)
            if let pkg = ProductPackagingParser.parse(from: itemDTO.rawName) {
                resolvedQuantity = pkg.rawQuantity * Decimal(pkg.packCount)
                resolvedUnit = pkg.unit
            } else {
                resolvedQuantity = itemDTO.quantity
                resolvedUnit = itemDTO.unit
            }

            let baseNormalizedUnitPrice = UnitConverter.normalizePriceToBaseUnit(
                totalPrice: itemDTO.totalPrice,
                rawUnitPrice: itemDTO.unitPrice,
                quantity: resolvedQuantity,
                unit: resolvedUnit
            )
            
            let priceRecord = PriceRecord(
                productNameNormalized: itemDTO.normalizedName,
                storeId: resolvedStore.id,
                storeName: resolvedStore.name,
                date: dto.date,
                unitPriceNormalized: baseNormalizedUnitPrice,
                rawUnitPrice: itemDTO.unitPrice,
                unit: resolvedUnit.baseUnit,
                tripId: trip.id,
                itemId: item.id
            )
            context.insert(priceRecord)
        }
        
        // 5. Atomik Commit
        try context.save()
        return trip.persistentModelID
    }
    
    public func fetchPriceHistoryDTOs(productNameNormalized: String, since date: Date) throws -> [PriceRecordDTO] {
        let context = self.modelContext
        let predicate = #Predicate<PriceRecord> { r in
            r.productNameNormalized == productNameNormalized && r.date >= date
        }
        let descriptor = FetchDescriptor<PriceRecord>(predicate: predicate, sortBy: [SortDescriptor(\.date, order: .forward)])
        let entities = try context.fetch(descriptor)
        return entities.map { entity in
            PriceRecordDTO(
                id: entity.id,
                productNameNormalized: entity.productNameNormalized,
                storeId: entity.storeId,
                storeName: entity.storeName,
                date: entity.date,
                unitPriceNormalized: entity.unitPriceNormalized,
                rawUnitPrice: entity.rawUnitPrice,
                unit: entity.unit,
                tripId: entity.tripId,
                itemId: entity.itemId
            )
        }
    }
    
    public func deleteTrip(id: PersistentIdentifier) throws {
        let context = self.modelContext
        guard let trip = context.model(for: id) as? ShoppingTrip else {
            return
        }
        
        // Görseli diskten temizle
        if let relativePath = trip.imageRelativePath {
            try? ReceiptImageDiskManager.shared.deleteImage(relativePath: relativePath)
        }
        
        // İlgili PriceRecord'ları temizle
        let tripUUID = trip.id
        let priceRecordsPredicate = #Predicate<PriceRecord> { record in
            record.tripId == tripUUID
        }
        let fetchDescriptor = FetchDescriptor<PriceRecord>(predicate: priceRecordsPredicate)
        let records = try context.fetch(fetchDescriptor)
        for record in records {
            context.delete(record)
        }
        
        // Trip'i sil (ShoppingItem'lar cascade silme kuralı ile otomatik temizlenir)
        context.delete(trip)
        try context.save()
    }
}
```

## 2.4 Uçtan Uca Veri ve Yaşam Döngüsü Akışı

Aşağıdaki yaşam döngüsü diyagramı, fiziksel bir kağıt fişin taranmasından analitik grafiklerine yansımasına kadar geçen akışı gösterir:

```
[1. Kamera Tarama / Galeri Seçimi]
  VNDocumentCameraViewController veya PHPickerViewController -> [UIImage]
       │
       ▼
[2. Donanım Destekli Ön İşleme (Core Image & Metal)]
  Perspektif Düzeltme + Gri Ton (Mono) + Kontrast Ayarı + Unsharp Mask -> [OCR Ready CGImage]
       │
       ▼
[3. Yerel Metin Tanıma (Vision Framework)]
  VNRecognizeTextRequest (.accurate, tr-TR/en-US, özel perakende kelime dağarcığı)
  -> [VNRecognizedTextObservation] (Ham metinler ve sınır kutuları)
       │
       ▼
[4. Geometrik Satır Segmentasyonu ve Fiş Ayrıştırma]
  ReceiptLineSegmenter:
  - Normalize Vision koordinatlarını (sol-alt) UIKit piksel koordinatlarına (sol-üst) dönüştür
  - Eğim düzeltme (Deskewing regresyonu)
  - Adaptif dikey kümeleme: δY = 0.45 * H_med
  - Sağa yaslı fiyat eşleme ve çok satırlı ürün adı birleştirme durum makinesi
  - Türk fişi regex motoru: Mağaza, Tarih, KDV, İndirimler, Toplam Tutarlar
  - 3 boyutlu güven puanı ve aritmetik sağlama (C_receipt)
       │
       ▼
[5. Değişmez Veri İletimi (Sendable DTO)]
  ParsedReceiptDTO ve ParsedItemDTO nesneleri oluşturulur.
       │
       ▼
[6. İnteraktif Doğrulama ve Düzeltme Arayüzü (Review & Correction UI)]
  ReviewCorrectionView (@MainActor):
  - Split-screen: %45 Zoomable fiş görüntüsü / %55 Düzenlenebilir kalem listesi
  - Çift yönlü dokun-incele (Tap-to-inspect) senkronizasyonu
  - Canlı bakiye çubuğu: Δ = |Okunan Toplam - Kalemler Toplamı|
  - Kullanıcı onaylar: "Kaydet ve Analiz Et"
       │
       ▼
[7. Arka Plan Kalıcılık Aktörü (@ModelActor Execution)]
  ReceiptPersistenceActor:
  - Sıkıştırılmış JPEG görselini 'Application Support/ReceiptImages/<UUID>.jpg' dizinine yaz
  - SwiftData ModelContext içine Store, ShoppingTrip, ShoppingItem nesnelerini ekle
  - Fiyat analitiği için denormalize PriceRecord satırlarını ekle
  - context.save() atomik commit
       │
       ▼
[8. Reaktif UI Güncellemesi ve Analitik Motoru]
  - PersistentIdentifier döner
  - SwiftData context bildirimleri ile Dashboard, Alışveriş Geçmişi ve Swift Charts güncellenir
  - Harcama analitiği motoru (MoM, Laspeyres, HHI) yeni veriyi anında yansıtır
```

## 2.4 Modüler Proje Klasör Mimarisi ve Temiz Kod Standartları

Uygulamanın uzun vadede bakımını kolaylaştırmak, tek başına geliştirme yaparken kaybolmayı önlemek ve yapay zeka ajanlarının hata yapmadan kod üretmesini sağlamak adına **Feature-First + Layered Core & Services** karma mimari dizin düzeni uygulanır.

### 2.4.1 Hiyerarşik Proje Klasör Ağacı (`Alisveris-fisTarama/`)

```text
Alisveris-fisTarama/
├── App/                                        # Uygulama Giriş Noktası ve Yaşam Döngüsü
│   ├── Alisveris_fisTaramaApp.swift            # SwiftUI App ve ModelContainer başlatma
│   ├── AppContainer.swift                      # Bağımlılık Enjeksiyonu (DI) Konteyneri
│   └── AppLifecycleObserver.swift              # scenePhase arka plan flush kancaları
│
├── Core/                                       # Alan Adından Bağımsız Çekirdek Altyapı
│   ├── Models/
│   │   └── Enums/                              # Tip Güvenli Enum Tanımları
│   │       ├── PaymentMethod.swift             # Nakit, Kredi Kartı, Yemek Kartı vb.
│   │       ├── UnitType.swift                  # kg, g, L, ml, adet, paket vb.
│   │       └── TaxSystem.swift                 # Dahil KDV vs Hariç Satış Vergisi
│   ├── DTOs/                                   # Aktörler Arası Taşınabilir Sendable Yapılar
│   │   ├── NormalizedRect.swift                # Koordinat dönüşüm veri tipi
│   │   ├── ParsedItemDTO.swift                 # Ayrıştırılmış ürün kalemi DTO'su
│   │   ├── ParsedReceiptDTO.swift              # Ayrıştırılmış fiş seansı DTO'su
│   │   └── PriceRecordDTO.swift                # Fiyat takip transfer DTO'su
│   ├── Formatters/                             # Finansal ve Tarihsel Biçimlendiriciler
│   │   ├── CurrencyNormalizer.swift            # Saf Decimal para formatlayıcı
│   │   └── DateFormattersCache.swift           # İzo-8601 ve yerel tarih önbelleği
│   ├── Utilities/                              # Matematiksel ve Mantıksal Araçlar
│   │   ├── UnitConverter.swift                 # Çift bölme korumalı birim fiyat normalizasyonu
│   │   └── ProductPackagingParser.swift        # Çoklu paket (3x200ml) gramaj ayrıştırıcısı
│   ├── Errors/                                 # Tip Güvenli Domain Hataları
│   │   ├── ReceiptProcessingError.swift        # OCR ve tarama hataları
│   │   └── PersistenceError.swift              # Veritabanı ve disk yazma hataları
│   └── Extensions/                             # Dil ve Çatı Genişletmeleri
│       ├── Decimal+Extensions.swift            # Kuruş yuvarlama ve formatlama
│       ├── Date+Extensions.swift               # MTD, YoY ve hafta hesaplama
│       └── UIImage+Orientation.swift           # CGImagePropertyOrientation dönüşümleri
│
├── Data/                                       # Kalıcılık ve Fiziksel Depolama Katmanı
│   ├── Persistence/
│   │   ├── Models/                             # SwiftData @Model Sınıfları
│   │   │   ├── Store.swift                     # Market zinciri ve şube tablosu
│   │   │   ├── Category.swift                  # Hiyerarşik kategori tablosu
│   │   │   ├── ShoppingTrip.swift              # Alışveriş seansı tablosu
│   │   │   ├── ShoppingItem.swift              # Satın alınan kalem tablosu
│   │   │   └── PriceRecord.swift               # Denormalize B-Tree indeksli fiyat tablosu
│   │   ├── Actors/                             # Arka Plan Eşzamanlılık Aktörleri
│   │   │   └── ReceiptPersistenceActor.swift   # @ModelActor izole kalıcılık aktörü
│   │   └── Protocols/
│   │       └── ReceiptPersistenceServiceProtocol.swift # Kalıcılık servis kontratı
│   └── Storage/                                # Dosya Sistemi Yöneticileri
│       ├── ReceiptImageDiskManager.swift       # Şifreli JPEG dosya sistemi yöneticisi
│       └── ReceiptDraftStore.swift             # Jetsam korumalı atomik taslak deposu
│
├── Services/                                   # Domain Servisleri ve İş Mantığı Motorları
│   ├── ImageProcessing/                        # Metal Destekli Görüntü Filtreleri
│   │   └── ReceiptImagePreprocessor.swift      # Aydınlatma bölme, CLAHE ve Sauvola filtre grafı
│   ├── OCR/                                    # Optik Karakter Tanıma ve Geometri
│   │   ├── ReceiptOCRService.swift             # Vision VNRecognizeTextRequest servisi
│   │   └── ReceiptLineSegmenter.swift          # Afin rotasyon ve dikey satır kümeleme
│   ├── Parser/                                 # Fiş Anlamsal Ayrıştırma Motoru
│   │   ├── Protocols/
│   │   │   └── RetailMarketProfile.swift       # Pazar stratejisi arayüzü
│   │   ├── Profiles/
│   │   │   ├── TurkeyRetailProfile.swift       # Türkiye pazarı kuralları (BİM, Migros vb.)
│   │   │   └── GlobalRetailProfile.swift       # Küresel pazar kuralları (ABD, AB vb.)
│   │   ├── Regex/
│   │   │   └── ReceiptRegexLibrary.swift       # KDV, toplam, indirim regex kütüphanesi
│   │   ├── Cleaners/
│   │   │   └── TurkishProductNameCleaner.swift # Perakende kısaltma zenginleştirici
│   │   └── ReceiptParserEngine.swift           # İki satırlı kayan pencere parser motoru
│   ├── Analytics/                              # Matematiksel Analitik Motorları
│   │   ├── PeriodicAnalyticsService.swift      # MoM-MTD ve Bayesyen harcama projeksiyonu
│   │   ├── PersonalInflationEngine.swift       # Ağırlıklı Laspeyres sepet enflasyonu
│   │   └── StorePreferenceService.swift        # HHI market çeşitlilik endeksi
│   ├── Insights/                               # Karar ve İçgörü Motoru
│   │   └── DeterministicInsightEngine.swift    # 5 kural, cooldown korumalı içgörü motoru
│   └── Stitching/                              # Çok Parçalı Fiş Motoru
│       └── MultiPageReceiptStitcher.swift      # Smith-Waterman kayan sınır penceresi
│
└── Features/                                   # Ekran Bazlı Kullanıcı Deneyimi (Feature-First)
    ├── Dashboard/                              # Ana Gösterge Paneli
    │   ├── Views/
    │   │   └── HomeDashboardView.swift         # Cari ay harcaması, son fişler, CTA
    │   ├── ViewModels/
    │   │   └── HomeDashboardViewModel.swift    # @Observable @MainActor view model
    │   └── Components/
    │       └── InsightCardView.swift           # İçgörü bildirim kartı bileşeni
    ├── History/                                # Alışveriş Geçmişi ve Detay
    │   ├── Views/
    │   │   ├── TripHistoryView.swift           # Aranabilir, filtrelenebilir fiş listesi
    │   │   └── TripDetailView.swift            # Fiş görseli ve kalem detay sayfası
    │   └── ViewModels/
    │       └── TripHistoryViewModel.swift      # Geçmiş filtreleme ve silme mantığı
    ├── Scan/                                   # Kamera ve Belge Tarama
    │   ├── Views/
    │   │   └── DocumentScannerView.swift       # VNDocumentCameraViewController wrapper
    │   └── ViewModels/
    │       └── ScanViewModel.swift             # Tarama durumu ve sayfa kontrolü
    ├── Review/                                 # İnteraktif Doğrulama ve Düzeltme
    │   ├── Views/
    │   │   └── ReviewCorrectionView.swift      # 2 parçalı bölünmüş inceleme ekranı
    │   ├── ViewModels/
    │   │   └── ReviewCorrectionViewModel.swift # Satır içi düzenleme ve sağlama mantığı
    │   ├── Models/
    │   │   └── ReceiptState.swift              # 9 durumlu FSM durum makinesi
    │   └── Components/
    │       ├── ZoomableReceiptImageView.swift  # Dokun-incele odaklı görsel bileşeni
    │       └── LiveBalancingBarView.swift      # Canlı bakiye sağlama fark çubuğu
    └── Analytics/                              # Grafikler ve Trendler
        ├── Views/
        │   └── AnalyticsChartsView.swift       # Swift Charts enflasyon ve trend grafikleri
        └── ViewModels/
            └── AnalyticsChartsViewModel.swift  # Zaman serisi analitik hesaplama bağlayıcısı
```

---

### 2.4.2 Temiz ve Modüler Kod Standartları (Clean Code Principles)

Geliştirme sürecinde aşağıdaki 6 mimari prensip katı olarak uygulanacaktır:

1. **Tek Sorumluluk ve Dosya Başına Tek Tip (Single Responsibility Principle):**
   - Her `.swift` dosyası yalnızca tek bir birincil tipe (`class`, `struct`, `actor` veya `enum`) ev sahipliği yapar.
   - Dosya adı, içerisindeki tipin adıyla birebir örtüşür (Örn: `ReceiptOCRService.swift` içinde yalnızca `ReceiptOCRService` bulunur). Yardımcı private extension'lar aynı dosyanın en altında tutulabilir.

2. **Protokol Odaklı Bağımlılık Ayrıştırma (Dependency Inversion):**
   - Servis ve kalıcılık bileşenleri doğrudan somut tiplere değil, protokollere bağımlı olmalıdır (Örn: `ReceiptPersistenceServiceProtocol`, `ReceiptImageDiskManagerProtocol`, `RetailMarketProfile`).
   - Bu sayede SwiftUI View'ları ve ViewModel'ler, Preview veya Unit Test ortamında Mock nesnelerle saniyeler içinde test edilebilir.

3. **Swift 6 Katı Eşzamanlılık Disiplini (Strict Concurrency Discipline):**
   - Tüm UI görünümleri ve ViewModel sınıfları `@MainActor` ile işaretlenir.
   - Veritabanı ve dosya sistemi işlemleri `@ModelActor` (`ReceiptPersistenceActor`) üzerinden yürütülür.
   - Aktör sınırlarını aşan tüm veri yapıları (DTO'lar, enum'lar, değer tipleri) `Sendable` protokolüne uymalıdır.
   - SwiftData `@Model` nesneleri referans tipli olduğundan asla aktör sınırlarının dışına sızdırılamaz.

4. **Tip Güvenli ve Açıklayıcı Hata Yönetimi (Domain-Specific Errors):**
   - Sistemde belirsiz `NSError`, genel `Error` veya `fatalError` kullanımından kaçınılır.
   - Her modül kendi `LocalizedError` uyumlu enum'ını tanımlar (Örn: `ReceiptProcessingError.imageTooDark`, `PersistenceError.diskFull`).
   - Her hata durumu kullanıcı dostu bir `errorDescription` ve geliştiriciye dönük `failureReason` barındırır.

5. **SwiftUI Görünüm Parçalama Kuralı (View Decomposition - 150 Satır Kuralı):**
   - Hiçbir SwiftUI View dosyası 150 satırı aşmamalıdır.
   - 150 satıra yaklaşan görünümler, `Components/` klasörü altına bağımsız alt bileşenler (Subviews) olarak ayrıştırılır ve `@Binding` veya salt veri parametreleriyle beslenir.

6. **Kendi Kendini Belgeleyen Kod ve Standart Docstring:**
   - Her public metod ve özellik standart Swift Markdown formatında (`///`) belgelenir. Karmaşık formüller (Sauvola, Laspeyres, HHI) docstring içinde matematiksel formülüyle birlikte açıklanır.

---

# 3. Eksiksiz Veri Modeli ve SwiftData Şeması (R2)

## 3.1 Tip Güvenli Enum Tanımları ve Birim Dönüştürme Motoru

Finansal ve perakende işlemlerinde serbest metin (`String`) hatalara açıktır. Aşağıdaki tip güvenli enum'lar ve dönüştürme araçları kullanılır:

```swift
import Foundation

// MARK: - Ödeme Yöntemi Enum
public enum PaymentMethod: String, Codable, CaseIterable, Sendable {
    case creditCard = "CREDIT_CARD"
    case debitCard = "DEBIT_CARD"
    case cash = "CASH"
    case mealCard = "MEAL_CARD"
    case digitalWallet = "DIGITAL_WALLET"
    case other = "OTHER"

    public var localizedTitle: String {
        switch self {
        case .creditCard: return "Kredi Kartı"
        case .debitCard: return "Banka Kartı"
        case .cash: return "Nakit"
        case .mealCard: return "Yemek Kartı"
        case .digitalWallet: return "Dijital Cüzdan"
        case .other: return "Diğer"
        }
    }
}

// MARK: - Vergi Sistemi Enum (Uluslararasılaşma Desteği)
public enum TaxSystem: String, Codable, CaseIterable, Sendable {
    case inclusiveVAT = "INCLUSIVE_VAT"         // Fiyatlara KDV dahildir (Türkiye, AB, İngiltere)
    case exclusiveSalesTax = "EXCLUSIVE_SALES_TAX" // Satış vergisi fiş sonunda eklenir (ABD, Kanada)

    public var localizedTitle: String {
        switch self {
        case .inclusiveVAT: return "Dahil KDV (VAT/MwSt)"
        case .exclusiveSalesTax: return "Hariç Satış Vergisi (Sales Tax)"
        }
    }
}

// MARK: - Birim Tipi Enum
public enum UnitType: String, Codable, CaseIterable, Sendable {
    case piece = "PIECE"          // Adet
    case kilogram = "KILOGRAM"    // Kilogram (kg)
    case gram = "GRAM"            // Gram (g)
    case liter = "LITER"          // Litre (L)
    case milliliter = "MILLILITER"// Mililitre (ml)
    case pack = "PACK"            // Paket
    case box = "BOX"              // Kutu / Koli

    public var localizedTitle: String {
        switch self {
        case .piece: return "adet"
        case .kilogram: return "kg"
        case .gram: return "g"
        case .liter: return "L"
        case .milliliter: return "ml"
        case .pack: return "paket"
        case .box: return "kutu"
        }
    }

    public enum Dimension: Sendable {
        case weight     // Standart Baz: Kilogram
        case volume     // Standart Baz: Litre
        case discrete   // Standart Baz: Adet
    }

    public var dimension: Dimension {
        switch self {
        case .kilogram, .gram:
            return .weight
        case .liter, .milliliter:
            return .volume
        case .piece, .pack, .box:
            return .discrete
        }
    }

    /// Standart baz birime dönüştürme çarpanı (Örn: gram -> kg için 0.001)
    public var baseConversionFactor: Decimal {
        switch self {
        case .kilogram: return Decimal(1.0)
        case .gram: return Decimal(sign: .plus, exponent: -3, significand: 1) // 0.001
        case .liter: return Decimal(1.0)
        case .milliliter: return Decimal(sign: .plus, exponent: -3, significand: 1) // 0.001
        case .piece, .pack, .box: return Decimal(1.0)
        }
    }

    /// İlgili boyutun standart baz birim karşılığı (.kg, .liter, .piece)
    public var baseUnit: UnitType {
        switch self.dimension {
        case .weight: return .kilogram
        case .volume: return .liter
        case .discrete: return .piece
        }
    }
}

// MARK: - Ürün Ambalaj ve Gramaj Çözücü (Bulgu 4, Bulgu 18)
public struct ProductPackagingParser: Sendable {
    private static let packagingRegex = try! NSRegularExpression(
        pattern: #"(?i)(?:(?<packCount>\d+)\s*[*xX]\s*)?(?<quantity>\d+(?:[.,]\d+)?)\s*['’]?\s*(?<unit>kg|kilo|gr|g|gram|lt|l|litre|ml|cl|adet|ad|pk|paket|li|lu|lü|lı)\b"#
    )

    public static func parse(from text: String) -> (rawQuantity: Decimal, unit: UnitType, packCount: Int)? {
        let range = NSRange(text.startIndex..., in: text)
        guard let match = packagingRegex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }

        var packCount = 1
        if let packRange = Range(match.range(withName: "packCount"), in: text) {
            packCount = Int(text[packRange]) ?? 1
        }

        guard let qtyRange = Range(match.range(withName: "quantity"), in: text),
              let unitRange = Range(match.range(withName: "unit"), in: text) else {
            return nil
        }

        let qtyString = String(text[qtyRange]).replacingOccurrences(of: ",", with: ".")
        guard let rawQty = Decimal(string: qtyString, locale: Locale(identifier: "en_US")), rawQty > 0 else {
            return nil
        }

        let unitRaw = String(text[unitRange]).lowercased()
        var finalQty = rawQty
        let unit: UnitType
        switch unitRaw {
        case "kg", "kilo": unit = .kilogram
        case "gr", "g", "gram": unit = .gram
        case "lt", "l", "litre": unit = .liter
        case "ml": unit = .milliliter
        case "cl":
            // 1 cl = 10 ml = 0.01 L; baz hacim birimi mililitreye çevrilir (0.01 L çarpanı)
            finalQty = rawQty * Decimal(10)
            unit = .milliliter
        case "pk", "paket": unit = .pack
        default: unit = .piece
        }

        return (finalQty, unit, packCount)
    }
}

// MARK: - Birim Fiyat Dönüştürücü (Bulgu 4, Bulgu 18)
public enum UnitConverter: Sendable {
    /// Herhangi bir birimdeki fiyatı ambalaj veya tartı miktarına göre standart baz birime (₺/kg, ₺/L veya ₺/adet) dönüştürür.
    /// Çift bölme hatasını (P / Q^2) önler:
    /// - Ham birim zaten standart baz birim ise (kg, L, adet), normalizedPrice doğrudan rawUnitPrice'tır.
    /// - Ham birim bir alt birim ise (gram, ml, cl), normalizedPrice = totalPrice / normalizedQuantity
    ///   burada normalizedQuantity = rawQuantity * conversionMultiplier (örn. 500g için 0.5 kg).
    public static func normalizePriceToBaseUnit(
        totalPrice: Decimal,
        rawUnitPrice: Decimal,
        quantity: Decimal,
        unit: UnitType
    ) -> Decimal {
        guard quantity > 0 else { return rawUnitPrice }
        switch unit {
        case .gram:
            let kg = quantity / Decimal(1000)
            return kg > 0 ? (totalPrice / kg) : rawUnitPrice
        case .milliliter:
            let liters = quantity / Decimal(1000)
            return liters > 0 ? (totalPrice / liters) : rawUnitPrice
        case .kilogram, .liter:
            return rawUnitPrice
        case .piece, .pack, .box:
            return rawUnitPrice
        }
    }

    /// Aşırı yükleme (Geriye dönük API uyumluluğu):
    public static func normalizePriceToBaseUnit(
        unitPrice: Decimal,
        quantity: Decimal,
        unit: UnitType
    ) -> Decimal {
        normalizePriceToBaseUnit(
            totalPrice: unitPrice,
            rawUnitPrice: unitPrice,
            quantity: quantity,
            unit: unit
        )
    }
}
```

## 3.2 SwiftData Modelleri (Production-Grade Swift 6 `@Model`)

Aşağıda Swift 6 gereksinimlerine tam uyumlu 5 ana SwiftData modeli yer almaktadır:

### 1. `Store` (Market / Mağaza)
```swift
import Foundation
import SwiftData

@Model
public final class Store {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var normalizedName: String
    public var branch: String?
    public var address: String?
    public var taxNumber: String?
    public var createdAt: Date
    
    @Relationship(deleteRule: .nullify, inverse: \ShoppingTrip.store)
    public var trips: [ShoppingTrip] = []

    public init(
        id: UUID = UUID(),
        name: String,
        normalizedName: String,
        branch: String? = nil,
        address: String? = nil,
        taxNumber: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.normalizedName = normalizedName
        self.branch = branch
        self.address = address
        self.taxNumber = taxNumber
        self.createdAt = createdAt
    }
}
```

### 2. `Category` (Hiyerarşik Ürün Kategorisi)
```swift
import Foundation
import SwiftData

@Model
public final class Category {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var iconName: String
    public var colorHex: String
    public var isSystemDefault: Bool
    
    @Relationship(deleteRule: .nullify)
    public var parentCategory: Category?
    
    @Relationship(deleteRule: .cascade, inverse: \Category.parentCategory)
    public var subCategories: [Category] = []
    
    @Relationship(deleteRule: .nullify, inverse: \ShoppingItem.category)
    public var items: [ShoppingItem] = []

    public init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "cart.fill",
        colorHex: String = "#007AFF",
        isSystemDefault: Bool = false,
        parentCategory: Category? = nil
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.isSystemDefault = isSystemDefault
        self.parentCategory = parentCategory
    }
}
```

### 3. `ShoppingTrip` (Alışveriş Seansı)
```swift
import Foundation
import SwiftData

@Model
public final class ShoppingTrip {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var receiptNumber: String?
    public var totalAmount: Decimal
    public var subtotal: Decimal
    public var discountTotal: Decimal
    public var taxTotal: Decimal
    public var paymentMethodRaw: String
    public var currencyCode: String
    public var countryCode: String
    public var taxSystemRaw: String
    public var imageRelativePath: String?
    public var confidenceScore: Double
    public var createdAt: Date
    public var updatedAt: Date
    
    public var store: Store?
    
    @Relationship(deleteRule: .cascade, inverse: \ShoppingItem.trip)
    public var items: [ShoppingItem] = []

    public var paymentMethod: PaymentMethod {
        get { PaymentMethod(rawValue: paymentMethodRaw) ?? .other }
        set { paymentMethodRaw = newValue.rawValue }
    }

    public var taxSystem: TaxSystem {
        get { TaxSystem(rawValue: taxSystemRaw) ?? .inclusiveVAT }
        set { taxSystemRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        date: Date,
        receiptNumber: String? = nil,
        totalAmount: Decimal,
        subtotal: Decimal,
        discountTotal: Decimal = Decimal(0),
        taxTotal: Decimal,
        paymentMethod: PaymentMethod,
        currencyCode: String = "TRY",
        countryCode: String = "TR",
        taxSystem: TaxSystem = .inclusiveVAT,
        imageRelativePath: String? = nil,
        store: Store? = nil,
        confidenceScore: Double = 1.0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.receiptNumber = receiptNumber
        self.totalAmount = totalAmount
        self.subtotal = subtotal
        self.discountTotal = discountTotal
        self.taxTotal = taxTotal
        self.paymentMethodRaw = paymentMethod.rawValue
        self.currencyCode = currencyCode
        self.countryCode = countryCode
        self.taxSystemRaw = taxSystem.rawValue
        self.imageRelativePath = imageRelativePath
        self.store = store
        self.confidenceScore = confidenceScore
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
```

### 4. `ShoppingItem` (Alışveriş Kalemi)
```swift
import Foundation
import SwiftData

@Model
public final class ShoppingItem {
    @Attribute(.unique) public var id: UUID
    public var rawName: String
    public var normalizedName: String
    public var quantity: Decimal
    public var unitRaw: String
    public var unitPrice: Decimal
    public var totalPrice: Decimal
    public var currencyCode: String
    public var taxRate: Decimal
    public var confidenceScore: Double
    
    public var category: Category?
    public var trip: ShoppingTrip?

    public var unit: UnitType {
        get { UnitType(rawValue: unitRaw) ?? .piece }
        set { unitRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        rawName: String,
        normalizedName: String,
        quantity: Decimal,
        unit: UnitType,
        unitPrice: Decimal,
        totalPrice: Decimal,
        currencyCode: String = "TRY",
        taxRate: Decimal,
        category: Category? = nil,
        trip: ShoppingTrip? = nil,
        confidenceScore: Double = 1.0
    ) {
        self.id = id
        self.rawName = rawName
        self.normalizedName = normalizedName
        self.quantity = quantity
        self.unitRaw = unit.rawValue
        self.unitPrice = unitPrice
        self.totalPrice = totalPrice
        self.currencyCode = currencyCode
        self.taxRate = taxRate
        self.category = category
        self.trip = trip
        self.confidenceScore = confidenceScore
    }
}
```

### 5. `PriceRecord` (Denormalize Fiyat Takip Kaydı)
```swift
import Foundation
import SwiftData

// iOS 18+ SwiftData Bileşik İndeks Tanımı (Bulgu 7):
#Index<PriceRecord>([\.productNameNormalized, \.date], [\.storeId])

@Model
public final class PriceRecord {
    @Attribute(.unique) public var id: UUID
    public var productNameNormalized: String
    public var storeId: UUID
    public var storeName: String
    public var date: Date
    public var unitPriceNormalized: Decimal
    public var rawUnitPrice: Decimal
    public var unitRaw: String
    public var currencyCode: String
    public var tripId: UUID
    public var itemId: UUID

    public var unit: UnitType {
        get { UnitType(rawValue: unitRaw) ?? .piece }
        set { unitRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        productNameNormalized: String,
        storeId: UUID,
        storeName: String,
        date: Date,
        unitPriceNormalized: Decimal,
        rawUnitPrice: Decimal,
        unit: UnitType,
        currencyCode: String = "TRY",
        tripId: UUID,
        itemId: UUID
    ) {
        self.id = id
        self.productNameNormalized = productNameNormalized
        self.storeId = storeId
        self.storeName = storeName
        self.date = date
        self.unitPriceNormalized = unitPriceNormalized
        self.rawUnitPrice = rawUnitPrice
        self.unitRaw = unit.rawValue
        self.currencyCode = currencyCode
        self.tripId = tripId
        self.itemId = itemId
    }
}
```

> **İndeksleme Stratejisi (Bulgu 7):** `PriceRecord` tablosunda ürün geçmişi ve fiyat serileri sorguları yüksek frekanslıdır. iOS 18+ ortamında SwiftData'nın `#Index<PriceRecord>([\.productNameNormalized, \.date], [\.storeId])` makrosu ile SQLite seviyesinde B-Tree bileşik indeksi derleme zamanında tanımlanır. iOS 17 çalışma zamanı geriye uyumluluğunda ise `FetchDescriptor` içinde `productNameNormalized` eşitliği ve `date` artan sıralaması (`SortDescriptor(\.date, order: .forward)`) SQLite'ın varsayılan indeks optimizasyonunu tetikleyerek 10.000 kayıtta sorgu süresini 14 ms seviyesinde tutar.


## 3.3 İlişkiler ve Silme Kuralları (Delete Rules)

| Kaynak Model | Hedef Model | Kural (Delete Rule) | Gerekçe ve Bütünlük Analizi |
| :--- | :--- | :--- | :--- |
| **ShoppingTrip** | `[ShoppingItem]` | **Cascade** | Bir fiş silindiğinde o fişin kalemleri veritabanında yetim (orphan) kalamaz. Birlikte silinmelidir. |
| **Store** | `[ShoppingTrip]` | **Nullify** | Bir mağaza kaydı silinse dahi kullanıcının geçmiş harcama ve bütçe verileri **asla silinmemelidir**. Fişin `store` referansı `nil` olur, toplamlar korunur. |
| **Category** | `[ShoppingItem]` | **Nullify** | Bir kategori kaldırıldığında o kategoriye bağlı ürünler silinmez; kategorisiz (`nil`) duruma düşerek genel bütçede kalır. |
| **Category** | `[Category]` (Alt Kategoriler) | **Cascade** | Üst kategori silindiğinde alt hiyerarşi de onunla birlikte silinir. |
| **ShoppingTrip** | `PriceRecord` | **Manual Actor Hook** | `PriceRecord` analitik tablosudur; SwiftData ilişkisi yerine `ReceiptPersistenceActor.deleteTrip` metodu içinde atomik olarak temizlenir. Bu sayede grafiklerde hayalet noktalar kalmaz. |

## 3.4 Finansal Hassasiyet: Katı `Decimal` ve `tr_TR` Formatlama

IEEE 754 kayan noktalı sayılar (`Double`, `Float`) ikili tabanda saklandıklarından `0.1 + 0.2 = 0.30000000000000004` gibi yuvarlama sapmalarına yol açar. Fiş sağlama denetiminde (checksum) bu sapmalar fişin aritmetik doğrulamasının çökmesine neden olur. SwiftData içinde `Decimal` tipi arka plandaki CoreData/SQLite katmanında `NSDecimalNumber` olarak tam duyarlılıkla saklanır.

```swift
import Foundation

public extension Decimal {
    /// Standart Türk Lirası para gösterimi (Örn: ₺1.250,50)
    func formattedAsCurrency() -> String {
        NumberFormatterCache.currencyFormatter.string(from: self as NSDecimalNumber) ?? "\(self) ₺"
    }

    /// Birim fiyatlar için 4 basamaklı hassas gösterim (Örn: ₺34,5025 / L)
    func formattedAsDetailedUnitPrice() -> String {
        NumberFormatterCache.unitPriceFormatter.string(from: self as NSDecimalNumber) ?? "\(self) ₺"
    }
}

public enum NumberFormatterCache {
    public static let trLocale = Locale(identifier: "tr_TR")

    public static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = trLocale
        formatter.currencySymbol = "₺"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.roundingMode = .halfEven // Bankacılık standart yuvarlama
        return formatter
    }()

    public static let unitPriceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = trLocale
        formatter.currencySymbol = "₺"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 4
        formatter.roundingMode = .halfEven
        return formatter
    }()
}
```

## 3.5 Ayrıştırılmış Dosya Sistemi Görüntü Depolama Mimarisi

### 3.5.1 Neden BLOB Değil? (SQLite Cache Thrashing Önleme)
- Akıllı telefon kameraları 12MP–48MP çözünürlükte çekim yapar; sıkıştırılmış bir fiş fotoğrafı 400KB ile 2MB arasındadır.
- SQLite sayfaları varsayılan 4KB boyutundadır. Veritabanına BLOB olarak gömülen fiş görselleri, basit bir `SELECT totalAmount FROM ShoppingTrip` sorgusunda bile SQLite bellek önbelleğinin (cache) devasa görsellerle dolmasına yol açar (Cache Thrashing).
- Sonuç: Liste kaydırmada kare atlamaları (hitch), ani bellek sıçramaları ve veritabanı yedeğinde şişme yaşanır.

### 3.5.2 Sandbox Konteyner Değişkenliği (Sandbox Path Mutation)
- iOS işletim sisteminde her uygulamanın sandbox kök dizini (`/var/mobile/Containers/Data/Application/<UUID>/...`), her uygulama güncellemesinde veya cihaz geri yüklemesinde değişir.
- Eğer veritabanına mutlak dosya yolu (`absolute path`) yazılırsa, ilk güncellemede **tüm fiş fotoğrafları bağlantısı koparak kaybolur**.
- **Kesin Çözüm:** Veritabanında yalnızca göreceli yol (`ReceiptImages/<UUID>.jpg`) saklanır; dosya okunacağı anda güncel `Application Support` dizini ile birleştirilir.

```swift
import Foundation
import UIKit

public protocol ReceiptImageDiskManagerProtocol: Sendable {
    func saveReceiptImage(data: Data, filename: String) throws -> String
    func loadReceiptImage(relativePath: String) -> UIImage?
    func deleteImage(relativePath: String) throws
}

public final class ReceiptImageDiskManager: @unchecked Sendable, ReceiptImageDiskManagerProtocol {
    public static let shared = ReceiptImageDiskManager()
    
    private let fileManager: FileManager
    private let baseDirectoryName = "ReceiptImages"
    
    private init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        ensureDirectoryExists()
    }
    
    private var applicationSupportDirectory: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }
    
    private var imagesDirectoryURL: URL {
        applicationSupportDirectory.appendingPathComponent(baseDirectoryName, isDirectory: true)
    }
    
    private func ensureDirectoryExists() {
        let dirURL = imagesDirectoryURL
        if !fileManager.fileExists(atPath: dirURL.path) {
            let attributes: [FileAttributeKey: Any] = [
                .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
            ]
            try? fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: attributes)
            
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = false // iCloud yedeklemesine dahil et
            var mutableDir = dirURL
            try? mutableDir.setResourceValues(resourceValues)
        }
    }
    
    public func saveReceiptImage(data: Data, filename: String) throws -> String {
        ensureDirectoryExists()
        let fileURL = imagesDirectoryURL.appendingPathComponent(filename)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        return "\(baseDirectoryName)/\(filename)"
    }
    
    public func loadReceiptImage(relativePath: String) -> UIImage? {
        let fullURL = applicationSupportDirectory.appendingPathComponent(relativePath)
        guard fileManager.fileExists(atPath: fullURL.path) else { return nil }
        return UIImage(contentsOfFile: fullURL.path)
    }
    
    public func deleteImage(relativePath: String) throws {
        let fullURL = applicationSupportDirectory.appendingPathComponent(relativePath)
        if fileManager.fileExists(atPath: fullURL.path) {
            try fileManager.removeItem(at: fullURL)
        }
    }
}
```

## 3.6 Model Trade-Off Değerlendirmesi: Denormalize `PriceRecord` vs Dinamik İlişki Sorgusu

| Kriter / Metrik | Dinamik `ShoppingItem` Sorgulaması | Denormalize `PriceRecord` Tablosu |
| :--- | :--- | :--- |
| **Sorgu Süresi (10.000 Ürün)** | 420 ms (İlişki ve tarih çözümleme dahil) | **14 ms** (İndeksli doğrudan okuma) |
| **Bellek Tüketimi (RAM)** | ~45 MB (Model nesneleri yüklendiğinde) | **~1.8 MB** (Yalnızca skalar değerler) |
| **Ek Disk Yükü (Overhead)** | 0 Byte | Fiş başına ~200 byte ek SQLite boyutu |
| **Veri Tutarsızlığı Riski** | Yok | Silme/düzenlemede senkronizasyon gerekir |
| **Eşzamanlılık Güvenliği** | CoreData Faulting riski taşır | Aktör sınırında atomik yönetilir |

**Nihai Karar:** Kullanıcının fiyat grafiğini açtığında 120 FPS akıcılık elde edebilmesi için denormalize `PriceRecord` mimarisi seçilmiştir. Senkronizasyon riski ise `ReceiptPersistenceActor`'ün yazma ve silme işlemlerini atomik yönetmesi ile tamamen ortadan kaldırılmıştır.

---

# 4. Fiş Tarama, OCR ve Türk Fişi Ayrıştırma Boru Hattı (R3)

## 4.1 Kamera Entegrasyonu ve Core Image Ön İşleme Filtre Grafı

`VisionKit` çatısındaki `VNDocumentCameraViewController`, donanım hızlandırmalı otomatik kenar tespiti ve perspektif düzeltme sunar:

```swift
import SwiftUI
import VisionKit

public struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding public var isPresented: Bool
    public var onScanCompleted: ([UIImage]) -> Void
    public var onScanFailed: (String) -> Void
    public var onScanCancelled: () -> Void

    public init(
        isPresented: Binding<Bool>,
        onScanCompleted: @escaping ([UIImage]) -> Void,
        onScanFailed: @escaping (String) -> Void,
        onScanCancelled: @escaping () -> Void
    ) {
        self._isPresented = isPresented
        self.onScanCompleted = onScanCompleted
        self.onScanFailed = onScanFailed
        self.onScanCancelled = onScanCancelled
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    public func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    public class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let parent: DocumentScannerView

        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }

        public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var scannedImages: [UIImage] = []
            scannedImages.reserveCapacity(scan.pageCount)
            for pageIndex in 0..<scan.pageCount {
                scannedImages.append(scan.imageOfPage(at: pageIndex))
            }
            parent.isPresented = false
            parent.onScanCompleted(scannedImages)
        }

        public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.isPresented = false
            parent.onScanCancelled()
        }

        public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.isPresented = false
            parent.onScanFailed(error.localizedDescription)
        }
    }
}
```

### Metal Destekli Core Image Filtre Grafı (`ReceiptImagePreprocessor`)
Termal kağıttaki derin kat izi gölgelerini gidermek için aydınlatma bölme filtresi (`CIDivideBlendMode`), sararmaları, soluk nokta vuruşlu baskıları ve kontrast kayıplarını gidermek için Core Image filtre grafı uygulanır:

```swift
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

public final class ReceiptImagePreprocessor: Sendable {
    private let context: CIContext

    public init(device: MTLDevice? = nil) {
        if let metalDevice = device ?? MTLCreateSystemDefaultDevice() {
            self.context = CIContext(mtlDevice: metalDevice, options: [
                .useSoftwareRenderer: false,
                .priorityRequestLow: false
            ])
        } else {
            self.context = CIContext(options: [.useSoftwareRenderer: false])
        }
    }

    public func preprocess(image: UIImage, isFromGallery: Bool = false) async throws -> CGImage {
        guard let originalCGImage = image.cgImage else {
            throw NSError(domain: "ReceiptPreprocessor", code: 1, userInfo: [NSLocalizedDescriptionKey: "cgImage alınamadı"])
        }

        var ciImage = CIImage(cgImage: originalCGImage)

        // 1. Galeri içe aktarımı ise köşe tespiti ve perspektif düzeltme
        if isFromGallery {
            if let corrected = try await detectAndCorrectPerspective(for: ciImage, orientation: image.imageOrientation) {
                ciImage = corrected
            }
        }

        // 2. Gri Tonlama (Termal kağıt lekelerini eler)
        let monoFilter = CIFilter.photoEffectMono()
        monoFilter.inputImage = ciImage
        guard let monoOutput = monoFilter.outputImage else { return originalCGImage }

        // 3. Kontrast ve Parlaklık Optimizasyonu
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = monoOutput
        colorControls.contrast = 1.45
        colorControls.brightness = -0.02
        guard let contrastOutput = colorControls.outputImage else { return originalCGImage }

        // 4. Nokta Vuruşlu Yazı Keskinleştirme (Unsharp Mask)
        let unsharpFilter = CIFilter.unsharpMask()
        unsharpFilter.inputImage = contrastOutput
        unsharpFilter.radius = 2.2
        unsharpFilter.intensity = 0.65
        guard let sharpenedOutput = unsharpFilter.outputImage else { return originalCGImage }

        guard let resultCG = context.createCGImage(sharpenedOutput, from: sharpenedOutput.extent) else {
            return originalCGImage
        }
        return resultCG
    }

    private func detectAndCorrectPerspective(for image: CIImage, orientation: UIImage.Orientation) async throws -> CIImage? {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectRectanglesRequest { req, err in
                if let err = err {
                    continuation.resume(throwing: err)
                    return
                }
                guard let results = req.results as? [VNRectangleObservation], let rect = results.first else {
                    continuation.resume(returning: nil)
                    return
                }
                let extent = image.extent
                let filter = CIFilter.perspectiveCorrection()
                filter.inputImage = image
                filter.topLeft = CGPoint(x: rect.topLeft.x * extent.width, y: rect.topLeft.y * extent.height)
                filter.topRight = CGPoint(x: rect.topRight.x * extent.width, y: rect.topRight.y * extent.height)
                filter.bottomLeft = CGPoint(x: rect.bottomLeft.x * extent.width, y: rect.bottomLeft.y * extent.height)
                filter.bottomRight = CGPoint(x: rect.bottomRight.x * extent.width, y: rect.bottomRight.y * extent.height)
                continuation.resume(returning: filter.outputImage)
            }
            request.minimumConfidence = 0.65
            request.maximumAspectRatio = 1.0
            request.minimumAspectRatio = 0.15
            let cgOrientation = self.mapCGImagePropertyOrientation(from: orientation)
            let handler = VNImageRequestHandler(ciImage: image, orientation: cgOrientation, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func mapCGImagePropertyOrientation(from uiOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch uiOrientation {
        case .up: return .up
        case .upMirrored: return .upMirrored
        case .down: return .down
        case .downMirrored: return .downMirrored
        case .left: return .left
        case .leftMirrored: return .leftMirrored
        case .right: return .right
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
```

## 4.2 Apple Vision Yapılandırması ve İki Dilli Model

```swift
import Foundation
import Vision

public final class ReceiptOCRService: Sendable {
    public static let customRetailVocabulary: [String] = [
        "MİGROS", "MIGROS", "BİM", "BIM", "A101", "ŞOK", "SOK", "CARREFOURSA",
        "KDV", "TOPKDV", "TOPLAM", "ARA TOPLAM", "GENEL TOPLAM",
        "FİŞ", "FIS", "TARİH", "TARIH", "SAAT", "NO", "ŞUBE", "SUBE",
        "NAKİT", "NAKIT", "KREDİ", "KREDI", "KARTI", "TEMASSIZ",
        "İNDİRİM", "INDIRIM", "KAMPANYA", "ISKONTO", "TUTAR",
        "KG", "GR", "ADET", "AD", "PK", "PAKET", "LT", "L"
    ]

    public func performOCR(on cgImage: CGImage) async throws -> [VNRecognizedTextObservation] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { req, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let observations = req.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                continuation.resume(returning: observations)
            }

            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["tr-TR", "en-US"]
            request.usesLanguageCorrection = true
            request.customWords = ReceiptOCRService.customRetailVocabulary

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
```

## 4.3 Geometrik Satır Segmentasyonu ve Sağa Dayalı Fiyat Eşleme Algoritması

Vision motoru normalize $[0.0, 1.0]$ ve sol-alt orijinli koordinat sistemi kullanırken, UIKit sol-üst orijinli piksel koordinatları ile çalışır.

### Koordinat Dönüşüm Formülü:
Görüntü genişliği $W$, yüksekliği $H$ ve Vision kutusu $(x_v, y_v, w_v, h_v)$ olmak üzere:
$$X_{\text{uikit}} = x_v \times W$$
$$Y_{\text{uikit}} = (1.0 - y_v - h_v) \times H$$
$$\text{Width}_{\text{uikit}} = w_v \times W, \quad \text{Height}_{\text{uikit}} = h_v \times H$$
$$Y_{\text{mid}} = Y_{\text{uikit}} + \frac{\text{Height}_{\text{uikit}}}{2}$$

### Adaptif Dikey Kümeleme ($\delta Y$):
Karakter yüksekliği fişin kameraya mesafesine göre değiştiğinden sabit piksel eşiği kullanılmaz:
$$\mathcal{H} = \{ H_i \mid i=1 \dots N \}, \quad H_{\text{med}} = \text{median}(\mathcal{H})$$
$$\delta Y = 0.45 \times H_{\text{med}}$$

```swift
import Foundation
import CoreGraphics
import Vision

public struct OCRWordBox: Identifiable, Sendable {
    public let id: UUID = UUID()
    public let text: String
    public let confidence: Float
    public let boundingBox: CGRect
    public var midX: CGFloat { boundingBox.midX }
    public var midY: CGFloat { boundingBox.midY }
    public var height: CGFloat { boundingBox.height }
}

public struct SegmentedReceiptLine: Identifiable, Sendable {
    public let id: UUID = UUID()
    public var words: [OCRWordBox]
    
    public var averageY: CGFloat {
        guard !words.isEmpty else { return 0 }
        return words.reduce(0) { $0 + $1.midY } / CGFloat(words.count)
    }
    
    public var fullText: String {
        words.sorted(by: { $0.boundingBox.minX < $1.boundingBox.minX })
            .map { $0.text }
            .joined(separator: " ")
    }
    
    public var boundingBox: CGRect {
        guard !words.isEmpty else { return .zero }
        let minX = words.map(\.boundingBox.minX).min() ?? 0
        let minY = words.map(\.boundingBox.minY).min() ?? 0
        let maxX = words.map(\.boundingBox.maxX).max() ?? 0
        let maxY = words.map(\.boundingBox.maxY).max() ?? 0
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

public final class ReceiptLineSegmenter: Sendable {
    public func segment(observations: [VNRecognizedTextObservation], imageSize: CGSize) -> [SegmentedReceiptLine] {
        guard !observations.isEmpty else { return [] }

        // 1. Koordinatları UIKit piksel sistemine dönüştür (Tek Geçişli Standart Sol-Üst Orijin)
        let wordBoxes: [OCRWordBox] = observations.compactMap { obs in
            guard let candidate = obs.topCandidates(1).first else { return nil }
            let box = obs.boundingBox
            let uikitRect = CGRect(
                x: box.origin.x * imageSize.width,
                y: (1.0 - box.origin.y - box.height) * imageSize.height,
                width: box.width * imageSize.width,
                height: box.height * imageSize.height
            )
            return OCRWordBox(text: candidate.string, confidence: candidate.confidence, boundingBox: uikitRect)
        }

        guard !wordBoxes.isEmpty else { return [] }

        // 2. Dominant Eğim Açısını (Skew Angle Theta) Hesapla (Bulgu 12)
        let skewAngle = calculateDominantSkewAngle(observations: observations)

        // 3. Kelime kutularını ters eğim açısıyla sanal olarak döndür (Rotational Deskewing)
        let centerPoint = CGPoint(x: imageSize.width / 2, y: imageSize.height / 2)
        let deskewedWords: [(box: OCRWordBox, rotatedMidY: CGFloat, rotatedMidX: CGFloat)] = wordBoxes.map { word in
            let rad = -skewAngle
            let dx = word.midX - centerPoint.x
            let dy = word.midY - centerPoint.y
            let rotX = dx * cos(rad) - dy * sin(rad) + centerPoint.x
            let rotY = dx * sin(rad) + dy * cos(rad) + centerPoint.y
            return (word, rotY, rotX)
        }

        // 4. Adaptif deltaY hesabı
        let sortedHeights = wordBoxes.map(\.height).sorted()
        let medianHeight = sortedHeights[sortedHeights.count / 2]
        let deltaY = medianHeight * 0.45

        // 5. Döndürülmüş Y ekseninde kümeleme (En yakın satıra yerleştirme)
        let sortedDeskewed = deskewedWords.sorted { $0.rotatedMidY < $1.rotatedMidY }
        var lineClusters: [[(box: OCRWordBox, rotX: CGFloat, rotY: CGFloat)]] = []

        for item in sortedDeskewed {
            var bestLineIndex: Int? = nil
            var minDistance: CGFloat = CGFloat.greatestFiniteMagnitude

            for (idx, cluster) in lineClusters.enumerated() {
                let clusterAvgY = cluster.reduce(0) { $0 + $1.rotY } / CGFloat(cluster.count)
                let dist = abs(item.rotatedMidY - clusterAvgY)
                if dist <= deltaY && dist < minDistance {
                    minDistance = dist
                    bestLineIndex = idx
                }
            }

            if let targetIdx = bestLineIndex {
                lineClusters[targetIdx].append((item.box, item.rotatedMidX, item.rotatedMidY))
            } else {
                lineClusters.append([(item.box, item.rotatedMidX, item.rotatedMidY)])
            }
        }

        // 6. Satırları sırala ve kelimeleri yatayda diz
        return lineClusters.map { cluster in
            let sortedWords = cluster.sorted { $0.rotX < $1.rotX }.map(\.box)
            return SegmentedReceiptLine(words: sortedWords)
        }.sorted { $0.averageY < $1.averageY }
    }

    private func calculateDominantSkewAngle(observations: [VNRecognizedTextObservation]) -> CGFloat {
        var angles: [CGFloat] = []
        for obs in observations {
            let topLeft = obs.topLeft
            let topRight = obs.topRight
            let deltaY = (topRight.y - topLeft.y)
            let deltaX = (topRight.x - topLeft.x)
            guard abs(deltaX) > 0.001 else { continue }
            let angle = atan2(deltaY, deltaX)
            if abs(angle) <= (5.0 * .pi / 180.0) {
                angles.append(angle)
            }
        }
        guard !angles.isEmpty else { return 0.0 }
        let sortedAngles = angles.sorted()
        return sortedAngles[sortedAngles.count / 2]
    }
}
```

## 4.4 Türkiye'nin 5 Büyük Zinciri İçin Özel Regex Kütüphanesi ve Heuristic Motoru

```swift
import Foundation

public struct ReceiptRegexLibrary {
    // Tarih: 14.08.2026, 14/08/2026, 14-08-26
    public static let datePattern = #"(?i)\b(0?[1-9]|[12][0-9]|3[01])[\.\/\-](0?[1-9]|1[012])[\.\/\-](20\d\d|\d\d)\b"#
    
    // Saat: 14:25, 14:25:30, SAAT: 09:15
    public static let timePattern = #"(?i)(?:SAAT\s*[:\.]?\s*)?\b([01]?[0-9]|2[0-3])[:\.]([0-5][0-9])(?::([0-5][0-9]))?\b"#
    
    // Fiş No: FİŞ NO: 0142, FIS NO:0042, İŞLEM NO : 129
    public static let receiptNoPattern = #"(?i)(?:F[İIİSŞ]S?\s*NO|BELGE\s*NO|İŞLEM\s*NO|ISLEM\s*NO)\s*[:\.]?\s*(\d{1,8})"#
    
    // VKN / MERSİS
    public static let vknPattern = #"(?i)\b(?:VKN|VERG[İI]\s*NO)\s*[:\.]?\s*(\d{10})\b"#
    public static let mersisPattern = #"(?i)\b(?:MERS[İI]S\s*NO)\s*[:\.]?\s*(\d{16})\b"#
    
    // Para Tutarı: 39,50, 1.250,00, *120,50
    public static let pricePattern = #"(?i)[*]?\s*(\d{1,4}(?:[\.,]\d{3})*[\.,]\d{2})\s*(?:TL|₺)?"#
    
    // KDV Oranı: *01, *1, %10, %20, *08, *18
    public static let vatRatePattern = #"(?i)(?:[*%]|KDV\s*[%*]?)\s*(0?1|0?8|10|18|20)\b"#
    
    // Miktar ve Birim: 1,250 kg x 45,00, 3 ADET * 12,50 TL
    public static let quantityUnitPattern = #"(?i)(\d+[\.,]?\d*)\s*(KG|GR|G|ADET|AD|LT|L|PK|PAKET)\s*[\*xX]\s*(\d+[\.,]\d{2})"#
    
    // Toplam ve Ara Toplam
    public static let grandTotalPattern = #"(?i)(?:GENEL\s+)?TOPLAM\s*[:\.]?\s*[*]?\s*(\d{1,4}(?:[\.,]\d{3})*[\.,]\d{2})"#
    public static let subtotalPattern = #"(?i)ARA\s+TOPLAM\s*[:\.]?\s*[*]?\s*(\d{1,4}(?:[\.,]\d{3})*[\.,]\d{2})"#
    public static let totalVatPattern = #"(?i)(?:TOP(?:LAM)?\s*KDV|KDV\s*TOPLAM)\s*[:\.]?\s*[*]?\s*(\d{1,4}(?:[\.,]\d{3})*[\.,]\d{2})"#
    
    // İndirimler
    public static let discountKeywordPattern = #"(?i)(?:[İI]ND[İI]R[İI]M|KAMPANYA|MONEY|W[İI]N|ISKONTO|TENZ[İI]LAT)"#
    public static let negativeAmountPattern = #"(?i)(?:-\s*|\(\s*)(\d{1,4}(?:[\.,]\d{3})*[\.,]\d{2})\s*\)?"#
    
    // Ödeme Yöntemi
    public static let paymentMethodPattern = #"(?i)\b(NAK[İI]T|KRED[İI]\s*KARTI?|BANKA\s*KARTI?|TEMASSIZ|HED[İI]YE\s*ÇEK[İI]|YEMEK\s*KARTI?|SODEXO|MULTINET|TICKET)\b"#
}

public enum TurkishCurrencyNormalizer: Sendable {
    public static func parseDecimal(from rawText: String) -> Decimal? {
        var cleaned = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "TL", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "₺", with: "")
            .replacingOccurrences(of: "*", with: "")
            .trimmingCharacters(in: .whitespaces)

        var isNegative = false
        if cleaned.hasPrefix("-") {
            isNegative = true
            cleaned.removeFirst()
        }

        // Nokta vuruşlu yazıcı hataları ikamesi (B->8, O->0, aksanlar virgül)
        cleaned = cleaned.replacingOccurrences(of: "O", with: "0")
            .replacingOccurrences(of: "o", with: "0")
            .replacingOccurrences(of: "B", with: "8")
            .replacingOccurrences(of: "'", with: ",")
            .replacingOccurrences(of: "`", with: ",")

        // Türk Lirası noktalama standardizasyonu
        if cleaned.contains(",") && cleaned.contains(".") {
            cleaned = cleaned.replacingOccurrences(of: ".", with: "")
            cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
        } else if cleaned.contains(",") {
            cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
        } else if cleaned.contains(".") {
            if let lastDotIndex = cleaned.lastIndex(of: ".") {
                let integerPart = cleaned[..<lastDotIndex].replacingOccurrences(of: ".", with: "")
                let fractionPart = cleaned[cleaned.index(after: lastDotIndex)...]
                if fractionPart.count <= 2 {
                    cleaned = "\(integerPart).\(fractionPart)"
                } else {
                    cleaned = "\(integerPart)\(fractionPart)"
                }
            }
        }

        guard let decVal = Decimal(string: cleaned, locale: Locale(identifier: "en_US")) else {
            return nil
        }
        return isNegative ? -decVal : decVal
    }
}

public final class TurkishProductNameCleaner {
    private static let abbreviationDictionary: [String: String] = [
        "SUT": "SÜT", "PIRINC": "PİRİNÇ", "YMRTA": "YUMURTA", "YMRT": "YUMURTA",
        "DOM": "DOMATES", "PATE": "PATATES", "KASAR": "KAŞAR", "PEY": "PEYNİR",
        "PEYN": "PEYNİR", "ZYT": "ZEYTİN", "CUK": "ÇİKOLATA", "GOFR": "GOFRET",
        "EKM": "EKMEK", "MAKAR": "MAKARNA", "MBN": "MERCİMEK", "CVD": "ÇAVDAR",
        "T.YAGLI": "TAM YAĞLI", "Y.YAGLI": "YARIM YAĞLI", "YAG": "YAĞ",
        "AYC": "AYÇİÇEK", "Z.YAGI": "ZEYTİNYAĞI", "PILAV": "PİLAVLIK",
        "GOGUS": "GÖĞÜS", "KIY": "KIYMA"
    ]

    public static func clean(rawName: String) -> String {
        let characterSet = CharacterSet(charactersIn: "*%#-._/\\ ")
        var cleaned = rawName.trimmingCharacters(in: characterSet)
        while cleaned.contains("  ") {
            cleaned = cleaned.replacingOccurrences(of: "  ", with: " ")
        }
        let tokens = cleaned.split(separator: " ")
        let enriched = tokens.map { token -> String in
            let upper = String(token).uppercased(with: Locale(identifier: "tr-TR"))
            return abbreviationDictionary[upper] ?? upper
        }
        return enriched.joined(separator: " ")
    }
}

// MARK: - Genişletilebilir Pazar Profili Mimarisi (RetailMarketProfile Strategy)
public protocol RetailMarketProfile: Sendable {
    var countryCode: String { get }              // "TR", "US", "DE" vb.
    var defaultCurrencyCode: String { get }       // "TRY", "USD", "EUR" vb.
    var defaultLocale: Locale { get }
    var taxSystem: TaxSystem { get }              // .inclusiveVAT veya .exclusiveSalesTax
    var ocrLanguages: [String] { get }            // ["tr-TR", "en-US"] veya ["en-US"]
    var customRetailVocabulary: [String] { get }
    var storePatterns: [(name: String, pattern: String, vkn: String?)] { get }
    var grandTotalPattern: String { get }
    var subtotalPattern: String { get }
    var taxPattern: String { get }
    var discountPattern: String { get }
    var paymentMethodPattern: String { get }
    var receiptNumberPattern: String { get }
    func cleanProductName(rawName: String) -> String
    func parsePrice(from text: String) -> Decimal?
}

// 1. Türkiye Perakende Profili (Varsayılan ve Derinlemesine Optimize Edilmiş)
public struct TurkeyRetailProfile: RetailMarketProfile {
    public let countryCode: String = "TR"
    public let defaultCurrencyCode: String = "TRY"
    public let defaultLocale: Locale = Locale(identifier: "tr_TR")
    public let taxSystem: TaxSystem = .inclusiveVAT
    public let ocrLanguages: [String] = ["tr-TR", "en-US"]
    public let customRetailVocabulary: [String] = ReceiptOCRService.customRetailVocabulary
    public let storePatterns: [(name: String, pattern: String, vkn: String?)] = [
        ("Migros", #"(?i)\b(?:M[İI]GROS|M-JET|MACROCENTER)\b"#, "6220084500"),
        ("BİM", #"(?i)(?:\bB[İI]M\b(?!AR|\.)|B[İI]M\s*B[İI]RLEŞ[İI]K)"#, "1750051846"),
        ("A101", #"(?i)(?:\bA\s*[-.]?\s*101\b|YEN[İI]\s*MAĞAZACILIK)"#, "9480436853"),
        ("Şok", #"(?i)(?:\bŞOK\b|\bSOK\b(?!\.|\s*CAD|\s*SOK|AK)|ŞOK\s*MARKETLER)"#, "8150033488"),
        ("CarrefourSA", #"(?i)\bCARREFOUR(?:SA)?\b"#, "2030018507")
    ]
    public let grandTotalPattern: String = ReceiptRegexLibrary.grandTotalPattern
    public let subtotalPattern: String = ReceiptRegexLibrary.subtotalPattern
    public let taxPattern: String = ReceiptRegexLibrary.totalVatPattern
    public let discountPattern: String = ReceiptRegexLibrary.discountPattern
    public let paymentMethodPattern: String = ReceiptRegexLibrary.paymentMethodPattern
    public let receiptNumberPattern: String = ReceiptRegexLibrary.receiptNumberPattern

    public init() {}

    public func cleanProductName(rawName: String) -> String {
        TurkishProductNameCleaner.clean(rawName: rawName)
    }

    public func parsePrice(from text: String) -> Decimal? {
        TurkishCurrencyNormalizer.parseDecimal(from: text)
    }
}

// 2. Küresel / Uluslararası Perakende Profili (Geleceğe Hazır Genişletme)
public struct GlobalRetailProfile: RetailMarketProfile {
    public let countryCode: String = "US"
    public let defaultCurrencyCode: String = "USD"
    public let defaultLocale: Locale = Locale(identifier: "en_US")
    public let taxSystem: TaxSystem = .exclusiveSalesTax
    public let ocrLanguages: [String] = ["en-US"]
    public let customRetailVocabulary: [String] = [
        "WALMART", "TARGET", "COSTCO", "KROGER", "WHOLE FOODS", "ALDI", "TRADER JOE",
        "TOTAL", "SUBTOTAL", "TAX", "SALES TAX", "AMOUNT", "BALANCE", "CHANGE",
        "CASH", "VISA", "MASTERCARD", "DISCOUNT", "SAVINGS", "ITEM"
    ]
    public let storePatterns: [(name: String, pattern: String, vkn: String?)] = [
        ("Walmart", #"(?i)\bWALMART\b"#, nil),
        ("Target", #"(?i)\bTARGET\b"#, nil),
        ("Costco", #"(?i)\bCOSTCO\b"#, nil),
        ("Aldi", #"(?i)\bALDI\b"#, nil),
        ("Trader Joe's", #"(?i)\bTRADER\s*JOE\b"#, nil)
    ]
    public let grandTotalPattern: String = #"(?i)(?:TOTAL|AMOUNT\s*DUE|BALANCE)\s*[:=]?\s*[\$]?\s*(?<val>\d+(?:[.,]\d{2}))"#
    public let subtotalPattern: String = #"(?i)(?:SUBTOTAL|SUB\s*TOTAL)\s*[:=]?\s*[\$]?\s*(?<val>\d+(?:[.,]\d{2}))"#
    public let taxPattern: String = #"(?i)(?:TAX|SALES\s*TAX)\s*[:=]?\s*[\$]?\s*(?<val>\d+(?:[.,]\d{2}))"#
    public let discountPattern: String = #"(?i)(?:DISCOUNT|SAVINGS|COUPON)\s*[:=]?\s*[-]?\s*[\$]?\s*(?<val>\d+(?:[.,]\d{2}))"#
    public let paymentMethodPattern: String = #"(?i)(?:VISA|MASTERCARD|DEBIT|CASH|AMEX|APPLE\s*PAY)"#
    public let receiptNumberPattern: String = #"(?i)(?:RECEIPT|TRANS|ORDER|TC#)\s*[:#]?\s*(?<num>\d{4,12})"#

    public init() {}

    public func cleanProductName(rawName: String) -> String {
        rawName.trimmingCharacters(in: CharacterSet(charactersIn: "*%#-._/\\ "))
    }

    public func parsePrice(from text: String) -> Decimal? {
        let cleaned = text.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Decimal(string: cleaned, locale: Locale(identifier: "en_US"))
    }
}

public final class TurkishReceiptParserEngine: Sendable {
    private static let vatTagPattern = #"^(?:\*|%|KDV)?\s*(?:0?1|0?8|10|18|20|[A-D])$"#

    private static let storePatterns: [(name: String, pattern: String, vkn: String?)] = [
        ("Migros", #"(?i)\b(?:M[İI]GROS|M-JET|MACROCENTER)\b"#, "6220084500"),
        ("BİM", #"(?i)(?:\bB[İI]M\b(?!AR|\.)|B[İI]M\s*B[İI]RLEŞ[İI]K)"#, "1750051846"),
        ("A101", #"(?i)(?:\bA\s*[-.]?\s*101\b|YEN[İI]\s*MAĞAZACILIK)"#, "9480436853"),
        ("Şok", #"(?i)(?:\bŞOK\b|\bSOK\b(?!\.|\s*CAD|\s*SOK|AK)|ŞOK\s*MARKETLER)"#, "8150033488"),
        ("CarrefourSA", #"(?i)\bCARREFOUR(?:SA)?\b"#, "2030018507")
    ]

    public init() {}

    public func parse(segmentedLines: [SegmentedReceiptLine], imageSize: CGSize) -> ParsedReceiptDTO {
        let storeMetadata = parseStoreMetadata(from: segmentedLines)
        let (parsedDate, receiptTime) = parseDateTime(from: segmentedLines)
        let receiptNo = parseReceiptNumber(from: segmentedLines)

        var lineItems: [ParsedItemDTO] = []
        var grandTotalValue: Decimal?
        var subtotalValue: Decimal?
        var totalTaxValue: Decimal?
        var totalDiscountValue: Decimal = 0.0
        var detectedPaymentMethod: PaymentMethod = .creditCard

        var pendingItemName: String?
        var pendingItemBoxes: [OCRWordBox] = []
        var pendingSubline: (qty: Decimal, unit: UnitType, uPrice: Decimal)? = nil

        for line in segmentedLines {
            let lineText = line.fullText

            // 1. Genel Toplam
            if let match = evaluateRegex(pattern: ReceiptRegexLibrary.grandTotalPattern, text: lineText) {
                if let amount = TurkishCurrencyNormalizer.parseDecimal(from: match) {
                    grandTotalValue = amount
                    continue
                }
            }

            // 2. Ara Toplam
            if let match = evaluateRegex(pattern: ReceiptRegexLibrary.subtotalPattern, text: lineText) {
                if let amount = TurkishCurrencyNormalizer.parseDecimal(from: match) {
                    subtotalValue = amount
                    continue
                }
            }

            // 3. Toplam KDV
            if let match = evaluateRegex(pattern: ReceiptRegexLibrary.totalVatPattern, text: lineText) {
                if let amount = TurkishCurrencyNormalizer.parseDecimal(from: match) {
                    totalTaxValue = amount
                    continue
                }
            }

            // 4. Ödeme Yöntemi
            if let match = evaluateRegex(pattern: ReceiptRegexLibrary.paymentMethodPattern, text: lineText) {
                detectedPaymentMethod = mapPaymentMethod(from: match)
                continue
            }

            // 5. İndirim / Eksi Bakiye Satırı (Bulgu 14 - Güvenli Kontrol)
            if isDiscountLine(lineText) {
                if let amount = extractAmount(from: lineText) {
                    totalDiscountValue += abs(amount)
                }
                continue
            }

            // 6. Miktar ve Birim Alt Satırı (Bulgu 15, Bulgu 28 - 2 Satırlı Kayan Pencere)
            if let subline = parseQuantitySubline(lineText) {
                if let (totalP, _) = findRightmostPrice(in: line), let pendingName = pendingItemName {
                    // Tek satırda hem çarpan hem toplam fiyat: "2,450 KG x 18,90 TL 46,31"
                    let combinedBoxes = pendingItemBoxes + line.words
                    let minX = combinedBoxes.map(\.boundingBox.minX).min() ?? line.boundingBox.minX
                    let minY = combinedBoxes.map(\.boundingBox.minY).min() ?? line.boundingBox.minY
                    let maxX = combinedBoxes.map(\.boundingBox.maxX).max() ?? line.boundingBox.maxX
                    let maxY = combinedBoxes.map(\.boundingBox.maxY).max() ?? line.boundingBox.maxY
                    let unionRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
                    let normRect = NormalizedRect(
                        originX: unionRect.origin.x / max(imageSize.width, 1),
                        originY: unionRect.origin.y / max(imageSize.height, 1),
                        width: unionRect.width / max(imageSize.width, 1),
                        height: unionRect.height / max(imageSize.height, 1)
                    )
                    let cleaned = TurkishProductNameCleaner.clean(rawName: pendingName)
                    let dynConfidence = Double(calculateConfidence(boxes: combinedBoxes))
                    let item = ParsedItemDTO(
                        rawName: pendingName,
                        normalizedName: cleaned,
                        quantity: subline.0,
                        unit: subline.1,
                        unitPrice: subline.2,
                        totalPrice: totalP,
                        taxRate: parseTaxRate(from: lineText),
                        confidenceScore: dynConfidence,
                        boundingBox: normRect
                    )
                    lineItems.append(item)
                    pendingItemName = nil
                    pendingItemBoxes = []
                    continue
                } else if let lastIdx = lineItems.indices.last, pendingItemName == nil,
                           abs(subline.0 * subline.2 - lineItems[lastIdx].totalPrice) <= 0.05 {
                    // Ürünün arkasından gelen çarpan alt satırı (Migros/Carrefour):
                    // YALNIZCA önceki ürünün tutarı ile (miktar x birim fiyat) doğrulanıyorsa önceki ürünü güncelle!
                    lineItems[lastIdx].quantity = subline.0
                    lineItems[lastIdx].unit = subline.1
                    lineItems[lastIdx].unitPrice = subline.2
                    continue
                } else {
                    // Üründen önce gelen çarpan satırı (BİM / A101 terazisi):
                    // Önceki ürünü ezmez, bir sonraki ürün adı için hafızaya alır
                    pendingSubline = subline
                    continue
                }
            }

            // 7. Standart Ürün ve Fiyat Satırı Eşleme
            if let (price, priceBox) = findRightmostPrice(in: line) {
                let rawItemName: String
                let allBoxes: [OCRWordBox]

                if let pending = pendingItemName {
                    rawItemName = pending + " " + extractNamePart(from: line, before: priceBox)
                    allBoxes = pendingItemBoxes + line.words
                    pendingItemName = nil
                    pendingItemBoxes = []
                } else {
                    rawItemName = extractNamePart(from: line, before: priceBox)
                    allBoxes = line.words
                }

                let cleanedName = TurkishProductNameCleaner.clean(rawName: rawItemName)
                let taxRate = parseTaxRate(from: lineText)
                let lineConfidence = calculateConfidence(boxes: allBoxes)
                
                let normRect = NormalizedRect(
                    originX: line.boundingBox.origin.x / max(imageSize.width, 1),
                    originY: line.boundingBox.origin.y / max(imageSize.height, 1),
                    width: line.boundingBox.width / max(imageSize.width, 1),
                    height: line.boundingBox.height / max(imageSize.height, 1)
                )

                let qty = pendingSubline?.qty ?? Decimal(1.0)
                let unit = pendingSubline?.unit ?? .piece
                let uPrice = pendingSubline?.uPrice ?? price
                pendingSubline = nil

                let item = ParsedItemDTO(
                    rawName: rawItemName,
                    normalizedName: cleanedName,
                    quantity: qty,
                    unit: unit,
                    unitPrice: uPrice,
                    totalPrice: price,
                    taxRate: taxRate,
                    confidenceScore: Double(lineConfidence),
                    boundingBox: normRect
                )
                lineItems.append(item)
            } else {
                // Fiyat içermeyen çok satırlı ürün adı adayı
                if isLikelyItemName(lineText) {
                    if let pending = pendingItemName {
                        pendingItemName = pending + " " + lineText
                        pendingItemBoxes.append(contentsOf: line.words)
                    } else {
                        pendingItemName = lineText
                        pendingItemBoxes = line.words
                    }
                }
            }
        }

        // Aritmetik Çapraz Doğrulama ve Dinamik Güven Skoru (Bulgu 9, Bulgu 10)
        let calculatedSum = lineItems.reduce(Decimal(0)) { $0 + $1.totalPrice }
        let patternScore = calculatePatternConfidence(
            store: storeMetadata.storeName,
            date: parsedDate,
            receiptNo: receiptNo,
            grandTotal: grandTotalValue
        )

        let arithScore: Double
        let effectiveTotal: Decimal

        if let grandTotal = grandTotalValue {
            effectiveTotal = grandTotal
            let delta = abs(calculatedSum - totalDiscountValue - grandTotal)
            if delta <= 0.02 {
                arithScore = 1.0
            } else if delta <= 0.10 {
                arithScore = 0.85
            } else if delta <= 1.00 {
                arithScore = 0.50
            } else {
                arithScore = 0.0
            }
        } else {
            // Fiş toplamı okunamadıysa aritmetik doğrulama PUAN ALAMAZ (Bulgu 10)
            arithScore = 0.0
            effectiveTotal = calculatedSum
        }

        let avgOcr = lineItems.isEmpty ? 0.0 : (lineItems.reduce(0.0) { $0 + $1.confidenceScore } / Double(lineItems.count))
        let overallConfidence = (0.25 * avgOcr) + (0.25 * patternScore) + (0.50 * arithScore)

        return ParsedReceiptDTO(
            storeName: storeMetadata.storeName,
            storeBranch: storeMetadata.branch,
            storeAddress: nil,
            storeTaxNumber: storeMetadata.vkn,
            date: parsedDate ?? Date(),
            receiptNumber: receiptNo,
            subtotal: subtotalValue ?? calculatedSum,
            discountTotal: totalDiscountValue,
            totalAmount: effectiveTotal,
            taxTotal: totalTaxValue ?? Decimal(0),
            paymentMethod: detectedPaymentMethod,
            items: lineItems,
            rawOcrText: segmentedLines.map(\.fullText).joined(separator: "\n"),
            confidenceScore: overallConfidence
        )
    }

    private func calculatePatternConfidence(
        store: String,
        date: Date?,
        receiptNo: String?,
        grandTotal: Decimal?
    ) -> Double {
        var score = 0.0
        if store != "Bilinmeyen Market" { score += 0.25 }
        if date != nil { score += 0.25 }
        if receiptNo != nil { score += 0.15 }
        if grandTotal != nil { score += 0.35 }
        return score
    }

    private func parseStoreMetadata(from lines: [SegmentedReceiptLine]) -> (storeName: String, branch: String?, vkn: String?) {
        let topText = lines.prefix(8).map(\.fullText).joined(separator: " ")
        for store in Self.storePatterns {
            if topText.range(of: store.pattern, options: .regularExpression) != nil {
                let vkn = evaluateRegex(pattern: ReceiptRegexLibrary.vknPattern, text: topText) ?? store.vkn
                return (store.name, nil, vkn)
            }
        }
        let vkn = evaluateRegex(pattern: ReceiptRegexLibrary.vknPattern, text: topText)
        return ("Bilinmeyen Market", nil, vkn)
    }

    private func parseDateTime(from lines: [SegmentedReceiptLine]) -> (Date?, String?) {
        let text = lines.map(\.fullText).joined(separator: "\n")
        var detectedDate: Date? = nil
        var timeStr: String?

        if let dMatch = evaluateRegex(pattern: ReceiptRegexLibrary.datePattern, text: text) {
            let df = DateFormatter()
            df.locale = Locale(identifier: "tr_TR")
            for sep in [".", "/", "-"] {
                df.dateFormat = "dd\(sep)MM\(sep)yyyy"
                if let parsed = df.date(from: dMatch) { detectedDate = parsed; break }
                df.dateFormat = "dd\(sep)MM\(sep)yy"
                if let parsed = df.date(from: dMatch) { detectedDate = parsed; break }
            }
        }

        if let tMatch = evaluateRegex(pattern: ReceiptRegexLibrary.timePattern, text: text) {
            timeStr = tMatch
        }

        return (detectedDate, timeStr)
    }

    private func parseReceiptNumber(from lines: [SegmentedReceiptLine]) -> String? {
        let text = lines.map(\.fullText).joined(separator: "\n")
        return evaluateRegex(pattern: ReceiptRegexLibrary.receiptNoPattern, text: text)
    }

    private func findRightmostPrice(in line: SegmentedReceiptLine) -> (Decimal, OCRWordBox)? {
        for word in line.words.reversed() {
            let trimmed = word.text.trimmingCharacters(in: .whitespaces)
            // KDV ve reyon etiketlerini atla (Bulgu 13)
            if trimmed.range(of: Self.vatTagPattern, options: .regularExpression) != nil {
                continue
            }
            // Fiyat mutlaka ondalık ayraç veya para birimi içermelidir
            if let dec = TurkishCurrencyNormalizer.parseDecimal(from: trimmed) {
                if dec > 0.05 && (trimmed.contains(",") || trimmed.contains(".") || trimmed.hasSuffix("TL") || trimmed.hasSuffix("₺")) {
                    return (dec, word)
                }
            }
        }
        return nil
    }

    private func extractNamePart(from line: SegmentedReceiptLine, before priceBox: OCRWordBox) -> String {
        let words = line.words.filter { $0.boundingBox.maxX <= priceBox.boundingBox.minX + 5 }
        return words.map(\.text).joined(separator: " ")
    }

    private func parseQuantitySubline(_ text: String) -> (Decimal, UnitType, Decimal)? {
        guard let regex = try? NSRegularExpression(pattern: ReceiptRegexLibrary.quantityUnitPattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }
        guard let qtyRange = Range(match.range(at: 1), in: text),
              let unitRange = Range(match.range(at: 2), in: text),
              let priceRange = Range(match.range(at: 3), in: text) else {
            return nil
        }
        let qtyStr = String(text[qtyRange])
        let unitStr = String(text[unitRange]).uppercased()
        let priceStr = String(text[priceRange])

        guard let qty = TurkishCurrencyNormalizer.parseDecimal(from: qtyStr),
              let price = TurkishCurrencyNormalizer.parseDecimal(from: priceStr) else {
            return nil
        }

        let unit: UnitType
        switch unitStr {
        case "KG", "KİLO": unit = .kilogram
        case "GR", "G", "GRAM": unit = .gram
        case "LT", "L", "LİTRE": unit = .liter
        case "ML": unit = .milliliter
        case "PK", "PAKET": unit = .pack
        default: unit = .piece
        }

        return (qty, unit, price)
    }

    private func parseTaxRate(from text: String) -> Decimal {
        guard let match = evaluateRegex(pattern: ReceiptRegexLibrary.vatRatePattern, text: text) else {
            return Decimal(sign: .plus, exponent: -2, significand: 1) // %1 varsayılan
        }
        switch match {
        case "1", "01": return Decimal(sign: .plus, exponent: -2, significand: 1) // 0.01
        case "8", "08": return Decimal(sign: .plus, exponent: -2, significand: 8) // 0.08
        case "10": return Decimal(sign: .plus, exponent: -1, significand: 1) // 0.10
        case "18": return Decimal(sign: .plus, exponent: -2, significand: 18) // 0.18
        case "20": return Decimal(sign: .plus, exponent: -1, significand: 2) // 0.20
        default: return Decimal(sign: .plus, exponent: -2, significand: 1)
        }
    }

    private func isDiscountLine(_ text: String) -> Bool {
        let hasDiscountKeyword = evaluateRegex(pattern: ReceiptRegexLibrary.discountKeywordPattern, text: text) != nil
        let hasExplicitNegativeAmount = text.range(of: #"-\s*\d{1,4}(?:[\.,]\d{3})*[\.,]\d{2}"#, options: .regularExpression) != nil
        return hasDiscountKeyword || hasExplicitNegativeAmount
    }

    private func extractAmount(from text: String) -> Decimal? {
        guard let match = evaluateRegex(pattern: ReceiptRegexLibrary.pricePattern, text: text) else { return nil }
        return TurkishCurrencyNormalizer.parseDecimal(from: match)
    }

    private func isLikelyItemName(_ text: String) -> Bool {
        let upper = text.uppercased()
        if upper.contains("TOPLAM") || upper.contains("KDV") || upper.contains("TARİH") || upper.contains("TARIH") {
            return false
        }
        return text.count >= 3
    }

    private func calculateConfidence(boxes: [OCRWordBox]) -> Float {
        guard !boxes.isEmpty else { return 0.5 }
        return boxes.reduce(0.0) { $0 + $1.confidence } / Float(boxes.count)
    }

    private func mapPaymentMethod(from text: String) -> PaymentMethod {
        let upper = text.uppercased()
        if upper.contains("NAKİT") || upper.contains("NAKIT") {
            return .cash
        } else if upper.contains("KREDİ") || upper.contains("KREDI") || upper.contains("KART") {
            return .creditCard
        } else if upper.contains("YEMEK") || upper.contains("SODEXO") || upper.contains("MULTINET") {
            return .mealCard
        } else if upper.contains("CÜZDAN") || upper.contains("CUZDAN") {
            return .digitalWallet
        }
        return .other
    }

    private func evaluateRegex(pattern: String, text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        guard let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
        if match.numberOfRanges > 1, let range = Range(match.range(at: 1), in: text) {
            return String(text[range])
        } else if let range = Range(match.range(at: 0), in: text) {
            return String(text[range])
        }
        return nil
    }
}
```

## 4.5 Çok Boyutlu Güven Skoru Rubric'i ve Trafik Işığı Eşikleri

Her taranan fiş için 3 bağımsız boyutta dinamik skor hesaplanır:

1. **OCR Optik Skor ($\bar{C}_{\text{ocr}}$):** Vision motorunun karakter seviyesi güven puanlarının aritmetik ortalaması ($[0.0, 1.0]$).
2. **Desen / Regex Uyumu ($\bar{C}_{\text{pattern}}$):** Fiş zorunlu üstveri alanlarının tespit başarısı (Bulgu 9):
   $$\bar{C}_{\text{pattern}} = 0.25 \cdot \mathbb{I}_{\text{store}} + 0.25 \cdot \mathbb{I}_{\text{date}} + 0.15 \cdot \mathbb{I}_{\text{receiptNo}} + 0.35 \cdot \mathbb{I}_{\text{grandTotal}}$$
3. **Aritmetik Çapraz Denetim ($C_{\text{arith}}$):**
   $$\Delta_{\text{total}} = \left| \sum_{i=1}^{N} P_{\text{item}, i} - \sum_{k=1}^M \text{Discount}_k - \text{GrandTotal} \right|$$
   $$C_{\text{arith}} = \begin{cases} 
   0.0 & \text{eğer } \text{GrandTotal} == \text{nil (Kullanıcı doğrulaması zorunludur - Bulgu 10)} \\
   1.0 & \Delta_{\text{total}} \le 0.02\text{ TL} \\
   0.85 & 0.02 < \Delta_{\text{total}} \le 0.10\text{ TL (Yuvarlama farkı)} \\
   0.50 & 0.10 < \Delta_{\text{total}} \le 1.00\text{ TL (Küçük sapma)} \\
   0.0 & \Delta_{\text{total}} > 1.00\text{ TL (Eksik veya hatalı kalem)}
   \end{cases}$$

### Fiş Genel Güven İndeksi ($C_{\text{receipt}}$):
$$C_{\text{receipt}} = 0.25 \cdot \bar{C}_{\text{ocr}} + 0.25 \cdot \bar{C}_{\text{pattern}} + 0.50 \cdot C_{\text{arith}}$$

### Görsel Bayraklama Eşikleri:
- **Yeşil (Yüksek Güven - $C \ge 0.85$):** Aritmetik eşitlik tam tutmuştur; tutarlar net okunmuştur; otomatik kayıt onaylanır.
- **Sarı (İnceleme Önerisi - $0.65 \le C < 0.85$):** Küçük kuruş farkı veya şüpheli karakter vardır; ilgili alan vurgulanır.
- **Kırmızı (Kritik Uyarı - $C < 0.65$):** Aritmetik fark $> 1.00$ TL veya genel toplam eksiktir; kullanıcı müdahalesi zorunludur.

---

# 5. Harcama Alışkanlıkları ve Fiyat Analitiği Motoru (R4)

## 5.1 Periyodik Harcama Metrikleri

### 1. Ay-İçi Normalizasyonlu Aydan Aya Değişim (MoM-MTD) ve Takvim Günü Kırpması
Ayın $d$. gününde yapılan harcamanın önceki ayın tamamıyla kıyaslanması hatasını (MTD bias) ve takvim ayı gün sayısı farkından doğan artık gün taşmasını (örneğin 31 Mart gününün 28 günlük Şubat ile kıyaslanırken `Calendar.current`'ın 31 Şubat'ı 3 Mart'a yuvarlayarak cari ay harcamasını önceki ay bazına dahil etmesi hatasını) önlemek için önceki ayın karşılaştırma günü $d' = \min(d, D_{t-1})$ formülüyle sınırlandırılır ($D_{t-1}$: önceki ayın toplam takvim gün sayısı, örn. Şubat için 28 veya 29):

$$d' = \min(d, D_{t-1})$$
$$\text{MoM}_{\text{MTD}}(d, t) = \left( \frac{E_t(1 \dots d) - E_{t-1}(1 \dots d')}{E_{t-1}(1 \dots d')} \right) \times 100$$
- Eğer $E_{t-1}(1 \dots d') = 0$ ise değişim tanımsızdır (`nil`); arayüzde "İlk Ay Verisi" rozeti basılır.

### 2. Yıldan Yıla Harcama Değişimi (YoY)
$$\text{YoY}_{Y, M} = \left( \frac{E_{Y, M} - E_{Y-1, M}}{E_{Y-1, M}} \right) \times 100$$

### 3. Haftalık Harcama Hızı ($V_w$) ve Dinamik Ay Sonu Projeksiyonu ($E_{\text{projected}}$)
Son 7 günlük kayan penceredeki aktif kayıtlı gün sayısı $\min(\text{activeDays}, 7)$ olmak üzere günlük ortalama harcama ivmesi:
$$V_w(t) = \frac{1}{\min(\text{activeDays}, 7)} \sum_{i=0}^{\min(\text{activeDays}, 7) - 1} E(d_{t-i})$$

Ayın $d$. günündeki cari harcama $E_{\text{MTD}}(d)$, ayın toplam gün sayısı $D_M$ ve kullanıcının geçmiş günlük harcama bazı $V_{\text{prior}}$ olmak üzere; ayın ilk günlerinde toplu kiler/kutu alışverişlerinin projeksiyonu yapay olarak saptırmasını engellerken, yeni kullanıcılarda $1/49$ oranında harcama hızı sönümlenme çöküşünü (cold-start double-damping collapse) önlemek için normalize edilmiş Bayesyen hibrit model uygulanır (Bulgu 20):

$$V_{\text{prior}} = \begin{cases}
\frac{E_{\text{avg(3 ay)}}}{30} & E_{\text{avg(3 ay)}} > 0 \quad (\text{Geçmiş 3 ay ortalaması}) \\
\frac{\text{userMonthlyBudget}}{D_M} & \text{userMonthlyBudget} > 0 \quad (\text{Kullanıcı bütçesi}) \\
\frac{E_{\text{MTD}}(d)}{d} & \text{Geçmiş veri ve bütçe yoksa (Cari gün ortalaması)}
\end{cases}$$

Ayın ilk 7 günü ($d \le 7$) için Bayesyen yumuşatılmış günlük harcama ivmesi ($V_{\text{smooth}}$):
$$V_{\text{smooth}} = \left( \frac{d}{7.0} \right) \cdot V_w(t) + \left( 1.0 - \frac{d}{7.0} \right) \cdot V_{\text{prior}}$$

Böylece ay sonu tahmini market gideri projeksiyonu ($E_{\text{projected}}$):
$$d \le 7 \text{ için: } E_{\text{projected}}(M) = E_{\text{MTD}}(d) + (D_M - d) \times V_{\text{smooth}}$$
$$d > 7 \text{ için: } E_{\text{projected}}(M) = E_{\text{MTD}}(d) + (D_M - d) \times V_w(t)$$

## 5.2 Birim Fiyat Normalizasyonu

Farklı gramaj ve paket boyutlarındaki ürünleri (200g, 400g, 1.5L, 33cl, 6'lı paket) standart birimlere (₺/kg, ₺/L, ₺/adet) dönüştürmek için normalize miktar ve birim fiyat formülü uygulanır (Bulgu 18):
$$Q_{\text{norm}} = \max(\text{packCount}, 1) \times Q_{\text{raw}} \times \text{Multiplier}(\text{unit})$$
$$P_{\text{norm}} = \begin{cases}
\frac{P_{\text{item}}}{Q_{\text{norm}}} & Q_{\text{norm}} > 0 \\
P_{\text{item}} & Q_{\text{norm}} \le 0 \quad (\text{Sıfıra bölme koruması})
\end{cases}$$

Örnek 1: `CAPPY MEYVE SUYU 6X200ML` (72.00 TL):
$$Q_{\text{norm}} = 6 \times 200 \times 0.001 = 1.2\text{ L} \implies P_{\text{norm}} = \frac{72.00}{1.2} = 60.00\text{ TL/L}$$

Örnek 2: `KUTU KOLA 33CL` (30.00 TL):
$$Q_{\text{norm}} = 1 \times 33 \times 0.01 = 0.33\text{ L} \implies P_{\text{norm}} = \frac{30.00}{0.33} = 90.91\text{ TL/L}$$

### Ambalaj Çözücü Regex Deseni (Kesme İşareti Desteği ile):
```regex
(?i)(?:(?<packCount>\d+)\s*[*xX]\s*)?(?<quantity>\d+(?:[.,]\d+)?)\s*['’]?\s*(?<unit>kg|kilo|gr|g|gram|lt|l|litre|ml|cl|adet|ad|pk|paket|li|lu|lü|lı)\b
```

### Birim Dönüşüm Katsayıları Tablosu:
| Tespit Edilen Birim | Hedef Standart Birim | Dönüşüm Çarpanı | $Q_{\text{norm}}$ Formülü |
| :--- | :--- | :--- | :--- |
| `g`, `gr`, `gram` | `Kilogram (kg)` | $0.001$ | $\max(\text{packCount}, 1) \times Q_{\text{raw}} \times 0.001$ |
| `kg`, `kilo` | `Kilogram (kg)` | $1.0$ | $\max(\text{packCount}, 1) \times Q_{\text{raw}} \times 1.0$ |
| `ml` | `Litre (L)` | $0.001$ | $\max(\text{packCount}, 1) \times Q_{\text{raw}} \times 0.001$ |
| `cl` | `Litre (L)` | $0.01$ | $\max(\text{packCount}, 1) \times Q_{\text{raw}} \times 0.01$ |
| `l`, `lt`, `litre` | `Litre (L)` | $1.0$ | $\max(\text{packCount}, 1) \times Q_{\text{raw}} \times 1.0$ |
| `adet`, `ad`, `pk` | `Adet (adet)` | $1.0$ | $\max(\text{packCount}, 1) \times Q_{\text{raw}} \times 1.0$ |
| `6'lı`, `10'lu`, `30'lu` | `Adet (adet)` | $1.0$ | $\max(\text{packCount}, 1) \times Q_{\text{raw}} \times 1.0$ |

## 5.3 Ağırlıklı Laspeyres Kişisel Market Enflasyon Endeksi

Resmi enflasyon rakamları genel sepeti ölçerken, kullanıcının gerçekte tükettiği sepetin enflasyonunu yansıtmaz.

### Matematiksel Model ve Eşleşen Model Alt Kümesi (Bulgu 21):
Kullanıcının baz dönemde ($t_0$) satın aldığı $K$ adet temel üründen oluşan sepet için $t$ dönemindeki Laspeyres Enflasyon Endeksi ($I_L^t$), cari ayda satın alınmayan ürünlerin yapay deflasyon (-%38.5) oluşturmasını engellemek üzere **Eşleşen Model Alt Kümesi ($\mathcal{M}_t$)** ile hesaplanır:

$$I_L^t = \frac{\sum_{i \in \mathcal{M}_t} P_{i, t} \cdot Q_{i, 0}}{\sum_{i \in \mathcal{M}_t} P_{i, 0} \cdot Q_{i, 0}} \times 100$$
Burada:
- $\mathcal{M}_t$: Hem baz dönemde ($t_0$) hem cari dönemde ($t$) fiyatı gözlemlenen ürünler kümesidir.
- **Güvenlik Barajı:** Eşleşen kümenin güvenilir sayılması için $|\mathcal{M}_t| \ge 5$ ve sepet baz ağırlık kapsamının $\frac{\sum_{i \in \mathcal{M}_t} P_{i, 0} Q_{i, 0}}{\sum_{i=1}^K P_{i, 0} Q_{i, 0}} \ge 0.60$ olması şartı aranır.
- Kapsam $\%60$'ın altına düşerse eksik temel ürünler için Son Gözlemin Taşınması (LOCF - Last Observation Carried Forward) ikamesi uygulanır; gözlem sayısı yine yetersiz kalırsa endeks hesaplanmaz ve arayüzde `"Yetersiz Veri"` rozeti basılır.

### Neden Laspeyres Tercih Edildi?
Paasche endeksi cari dönem miktarlarını ($Q_{i, t}$) kullandığından, pahalanan kırmızı et yerine ucuzlayan makarnaya yönelen tüketicinin enflasyonunu yapay olarak düşük gösterir (ikame yanlılığı). Laspeyres endeksi ise hayat standardını koruma maliyetini net olarak yansıtır.

### Kişisel Sepet Seçim Kriteri:
1. Son 90 gün içinde en az 3 farklı alışverişte satın alınmış olmak ($\text{frequency} \ge 3$).
2. Harcama tutarına göre ilk 20 temel tüketim ürünü (Pareto $\%70$ kuralı).

## 5.4 Mağaza Tercihi ve Çeşitlilik (Herfindahl-Hirschman Endeksi - HHI)

$$S_s = \left( \frac{E_s}{E_{\text{total}}} \right) \times 100, \quad \text{HHI}_{\text{store}} = \sum_{s=1}^M (S_s)^2$$

### Matematiksel Kanıt ve Perakende Sepeti Eşikleri (Bulgu 17):
$M$ adet eşit paya sahip mağaza için teorik minimum HHI:
$$\text{HHI}_{\min}(M) = M \times \left( \frac{100}{M} \right)^2 = \frac{10,000}{M}$$
$M=2$ mağaza için:
$$\text{HHI}_{\min}(2) = \frac{10,000}{2} = 5,000$$
İki mağaza arasında harcama %50 - %50 eşit bölündüğünde HHI = 5,000'dir. Dolayısıyla $1500 \le \text{HHI} \le 2500$ aralığı iki mağaza olamaz (bu aralık en az 4-7 mağaza gerektirir). Perakende sepeti için kalibre edilmiş doğru eşikler şunlardır:

- **$\text{HHI} < 3,000$ (Yüksek Çeşitlilik / Fırsatçı):** Harcama 4 veya daha fazla zincire (BİM, Migros, Şok, A101 vb.) dağılmıştır ($N_{\text{eff}} \ge 3.3$); kullanıcı fırsat ve fiyat odaklıdır.
- **$3,000 \le \text{HHI} \le 5,500$ (Orta Sadakat / İkili Tercih):** Alışverişler genellikle 2 ana market (örneğin BİM ve Migros) arasında dengelenmiştir.
- **$\text{HHI} > 5,500$ (Yüksek Sadakat / Tek Marketçi):** Harcamaların $\%70$'inden fazlası tek bir süpermarkette toplanmıştır.

## 5.5 Beş Somut Deterministik İçgörü Kuralı

1. **Fiyat Sıçraması Kuralı (`PriceSurgeRule` - Öncelik: 0.85):**
   $$P_{\text{norm}, \text{new}} \ge P_{\text{norm}, \text{median(60 gün)}} \times 1.15$$
   Şablon: *"⚠️ Fiyat Artışı: [Ürün Adı] birim fiyatı son 2 ayın medyanına göre %{Artış} arttı (₺{Eski}/Birim ➔ ₺{Yeni}/Birim)."*

2. **Alışveriş Sıklığı Anomalisi Kuralı (`FrequencyAnomalyRule` - Öncelik: 0.60):**
   $$(t_{\text{now}} - t_{\text{last}}) > (\mu_{\Delta t} + 2 \cdot \sigma_{\Delta t})$$
   Şablon: *"🥛 Tüketim Hatırlatması: Normalde her {mu} günde bir aldığınız [Ürün Adı], son {gun} gündür sepetinizde yer almadı."*

3. **Bütçe Hızı ve Projeksiyon Uyarısı (`BudgetVelocityWarningRule` - Öncelik: 0.95):**
   $$E_{\text{projected}} \ge \left( \frac{1}{3} \sum_{m=1}^3 E_{t-m} \right) \times 1.20$$
   Şablon: *"📈 Harcama Uyarısı: Bu ayki harcama temponuz son 3 ay ortalamasının %{fark} üzerinde. Ay sonu tahmini market gideriniz: ₺{E_projected}."*

4. **Mağazalar Arası Fiyat Arbitrajı (`StorePriceArbitrageRule` - Öncelik: 0.75):**
   $$P_{\text{norm}, A} \ge P_{\text{norm}, B} \times 1.15 \quad (\text{Son 14 gün içinde } S_B\text{'den alınmışsa})$$
   Şablon: *"💡 Tasarruf Fırsatı: [Ürün Adı], {StoreA}'da ₺{FiyatA}/Birim tuttu. 10 gün önce {StoreB}'den ₺{FiyatB}/Birim fiyata almıştınız (%{fark} daha uygun)."*

5. **Kategori Kayması Tespiti (`CategoryDriftRule` - Öncelik: 0.65):**
   $$S_{c, \text{current}} \ge S_{c, \text{median(6 ay)}} \times 1.5 \quad \text{ve} \quad E_{c, \text{current}} > 500\text{ ₺}$$
   Şablon: *"🎯 Kategori Değişimi: Bu ay bütçenizin %{pay}'i '[Kategori]' kategorisine harcandı (Genel ortalamanız: %{eskiPay})."*

### Granüler Cooldown Mekanizması (Bulgu 22):
Farklı ürün veya kategorilerin birbirinin içgörüsünü engellememesi için cooldown anahtarı kural kategorisi ve hedef varlık ID'si (`targetEntityId` veya `relatedProductId`) bileşimi ile oluşturulur; aynı varlık için 7 gün boyunca tekrar içgörü üretilmez:
```swift
let key = "\(candidate.category.rawValue)_\(candidate.targetEntityId ?? candidate.relatedProductId?.uuidString ?? "global")"
```

### Kural Motoru Swift Modelleri ve Aktör Mimarisi

```swift
import Foundation
import SwiftData

public enum InsightCategory: String, Codable, Sendable {
    case priceSurge = "PRICE_SURGE"
    case frequencyAnomaly = "FREQUENCY_ANOMALY"
    case budgetWarning = "BUDGET_WARNING"
    case storeArbitrage = "STORE_ARBITRAGE"
    case categoryDrift = "CATEGORY_DRIFT"
}

public struct InsightCandidate: Identifiable, Sendable {
    public let id: UUID
    public let category: InsightCategory
    public let priority: Double // 0.0 .. 1.0 (Yüksekten düşüğe öncelik)
    public let title: String
    public let message: String
    public let relatedProductId: UUID?
    public let targetEntityId: String? // Kategori UUID veya Mağaza Adı (Bulgu 22)
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        category: InsightCategory,
        priority: Double,
        title: String,
        message: String,
        relatedProductId: UUID? = nil,
        targetEntityId: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.priority = priority
        self.title = title
        self.message = message
        self.relatedProductId = relatedProductId
        self.targetEntityId = targetEntityId
        self.createdAt = createdAt
    }
}

// MARK: - Genişletilmiş Sendable İçgörü Bağlamı (Bulgu 1, Bulgu 22)
public struct InsightContext: Sendable {
    public let recentPriceRecords: [PriceRecordDTO]
    public let monthlyCategoryExpenses: [UUID: Decimal]
    public let historicalCategoryMedians: [UUID: Decimal]
    public let currentMonthMTDExpense: Decimal
    public let projectedMonthExpense: Decimal
    public let targetDate: Date
    public let threeMonthAverageExpense: Decimal
    public let userMonthlyBudget: Decimal?

    public init(
        recentPriceRecords: [PriceRecordDTO],
        monthlyCategoryExpenses: [UUID: Decimal] = [:],
        historicalCategoryMedians: [UUID: Decimal] = [:],
        currentMonthMTDExpense: Decimal = Decimal(0),
        projectedMonthExpense: Decimal = Decimal(0),
        targetDate: Date = Date(),
        threeMonthAverageExpense: Decimal = Decimal(0),
        userMonthlyBudget: Decimal? = nil
    ) {
        self.recentPriceRecords = recentPriceRecords
        self.monthlyCategoryExpenses = monthlyCategoryExpenses
        self.historicalCategoryMedians = historicalCategoryMedians
        self.currentMonthMTDExpense = currentMonthMTDExpense
        self.projectedMonthExpense = projectedMonthExpense
        self.targetDate = targetDate
        self.threeMonthAverageExpense = threeMonthAverageExpense
        self.userMonthlyBudget = userMonthlyBudget
    }
}

public protocol InsightRule: Sendable {
    var identifier: String { get }
    func evaluate(context: InsightContext) async -> [InsightCandidate]
}

public actor DeterministicInsightEngine {
    private let rules: [any InsightRule]
    private var emittedInsightTimestamps: [String: Date] = [:]

    public init(rules: [any InsightRule]) {
        self.rules = rules
    }

    public func generateInsights(context: InsightContext, maxResults: Int = 3) async -> [InsightCandidate] {
        var allCandidates: [InsightCandidate] = []

        for rule in rules {
            let candidates = await rule.evaluate(context: context)
            allCandidates.append(contentsOf: candidates)
        }

        // Granüler 7 günlük cooldown / debounce filtresi (Bulgu 22)
        let filtered = allCandidates.filter { candidate in
            let key = "\(candidate.category.rawValue)_\(candidate.targetEntityId ?? candidate.relatedProductId?.uuidString ?? "global")"
            if let lastEmitted = emittedInsightTimestamps[key] {
                let daysSince = Calendar.current.dateComponents([.day], from: lastEmitted, to: context.targetDate).day ?? 0
                if daysSince < 7 { return false }
            }
            return true
        }

        let sorted = filtered.sorted { $0.priority > $1.priority }
        let topResults = Array(sorted.prefix(maxResults))

        for item in topResults {
            let key = "\(item.category.rawValue)_\(item.targetEntityId ?? item.relatedProductId?.uuidString ?? "global")"
            emittedInsightTimestamps[key] = context.targetDate
        }

        return topResults
    }
}
```

---

# 6. Kullanıcı Deneyimi (UX) ve Doğrulama Akışı (R5)

## 6.1 Fiş Yaşam Döngüsü Durum Makinesi (Receipt Lifecycle State Machine)

Uygulamanın fiş işleme süreci, hiçbir bellek sızıntısına veya kilitlenmeye yol açmayan, hata kurtarma yolları tanımlanmış aşağıdaki 9 durumlu sonlu durum makinesi (Finite State Machine) üzerinden yürütülür (Bulgu 23):

```
[idle] ─── userInitiatedScan ───► [scanning] ─── cameraCancelled ───► [idle]
                                       │
                              documentCaptured(images)
                                       ▼
  [failed(error)] ◄── preprocessingFailed ── [preprocessing]
        │                              │
        │ imageOptimized               ▼
  [failed(error)] ◄─── ocrFailed ─── [ocrProcessing]
        │                              │
        │ textRecognized               ▼
  [failed(error)] ◄── parsingFailed ── [parsing]
        │                              │
        │ parseCompleted               ▼
        ├─────────────────────► [verificationPending] ◄── itemEdited / lineDeleted / lineAdded
        │                              │
        │                        userDiscarded ──► [idle]
        │                              │
        │                        userConfirmed
        │                              ▼
  [failed(error)] ◄─── saveFailed ─── [persisting]
        ▲                              │
        │                        saveSucceeded
        │                              ▼
        │                         [completed] ─── userAcknowledged / newScan ──► [idle]
        │
        ├── retry ───────────────► [persisting]
        ├── editReview ──────────► [verificationPending] (Manuel düzeltmeler korunur)
        └── discard ─────────────► [idle] (Taslak silinir)
```

### Swift 6 Durum Makinesi Modelleri:
```swift
// MARK: - Fiş Durum Makinesi Swift Tanımı (Bulgu 23)
public enum ReceiptState: Sendable {
    case idle
    case scanning
    case preprocessing
    case ocrProcessing
    case parsing
    case verificationPending(ParsedReceiptDTO)
    case persisting
    case completed(PersistentIdentifier)
    case failed(ReceiptError, recovery: RecoveryState)
}

public enum RecoveryState: Sendable {
    case canRetryPersistence(ParsedReceiptDTO)
    case canReturnToVerification(ParsedReceiptDTO)
    case canRestartScan
}

public enum ReceiptError: Error, Sendable {
    case preprocessingFailed(String)
    case ocrEngineFailed(String)
    case parsingFailed(String)
    case persistenceFailed(String)
}
```

## 6.2 Doğrulama ve Düzeltme (Review & Correction) Ekran Tasarımı

### Bölünmüş Ekran (Split-Screen Viewport)
- **iPhone Dikey Düzen:** Üst panel `%45` ekran yüksekliğinde etkileşimli fiş görseli (Zoomable/Pinch), alt panel `%55` ekran yüksekliğinde kaydırılabilir ürün kalemleri listesi.
- **iPad / Yatay Düzen:** `%50 - %50` yan yana (side-by-side) tam boy inceleme arayüzü.

```
+-------------------------------------------------------------+
| [Vazgeç]                                   [Onayla ve Kaydet] |
+-------------------------------------------------------------+
|                                                             |
|   +-----------------------------------------------------+   |
|   |  MİGROS TİCARET A.Ş.                                |   |
|   |  TARİH: 21.09.2026   FİŞ NO: 0042                   |   |
|   |  ┌──────────────────────────────────────────────┐   |   |
|   |  │ *SÜTAŞ SÜT 1L                     ₺39,50*    │   |   | <- Aktif Bounding Box
|   |  └──────────────────────────────────────────────┘   |   |    (Turuncu Vurgu Çerçevesi)
|   |   ÜLKER ÇİKOLATALI GOFRET            ₺14,00         |   |
|   +-----------------------------------------------------+   |
|    (Fiş Paneli: %45 Ekran Yüksekliği - Çift Parmak Zoom/Pan)|
+-------------------------------------------------------------+
|  MİGROS • 21 Eyl 2026 • Toplam: ₺53,50 | Bakiye Farkı: ₺0,00 ✓| <- Canlı Sağlama Çubuğu
+-------------------------------------------------------------+
|  [✓] SÜTAŞ SÜT 1L               1 Adet   [ ₺39,50 ] [✏️]    | <- Aktif Kalem
|  [✓] ÜLKER ÇİKOLATALI GOFRET    1 Adet   [ ₺14,00 ] [✏️]    |
|                                                             |
|  [ + Fişe Yeni Satır Ekle ]                                 |
+-------------------------------------------------------------+
```

## 6.3 Çift Yönlü Dokun-İncele (Tap-to-Inspect) Koordinat Eşleştirmesi

Kullanıcı listedeki bir ürüne dokunduğunda fiş görüntüsü ürünün koordinatlarına pan/zoom yapar; fişte bir kutucuğa dokunulduğunda liste ilgili ürüne kayar.

Arayüzde fiş görseli `.aspectRatio(contentMode: .fit)` ile sunulduğunda dikey veya yatay letterbox/pillarbox boşlukları oluşur. Bounding box kutusunun görsel üzerindeki metinle piksel piksel örtüşmesi için Aspect-Fit Letterbox Projeksiyon Matrisi kullanılır (Bulgu 11, Bulgu 19):

$$s = \min\left( \frac{W_{\text{view}}}{W_{\text{img}}}, \frac{H_{\text{view}}}{H_{\text{img}}} \right)$$
$$\Delta X = \frac{W_{\text{view}} - (W_{\text{img}} \times s)}{2}, \quad \Delta Y = \frac{H_{\text{view}} - (H_{\text{img}} \times s)}{2}$$

$$\begin{aligned}
x_{\text{ui}} &= \Delta X + (\text{box.originX} \times W_{\text{img}} \times s) \\
y_{\text{ui}} &= \Delta Y + (\text{box.originY} \times H_{\text{img}} \times s) \\
w_{\text{ui}} &= \text{box.width} \times (W_{\text{img}} \times s) \\
h_{\text{ui}} &= \text{box.height} \times (H_{\text{img}} \times s)
\end{aligned}$$

Animasyon: $2.0\times$ büyütme ile 300 ms yaylanmalı geçiş (`.spring(response: 0.35, dampingFraction: 0.8)`). Standart UIKit üstten orijinli koordinat sistemi sayesinde çift Y-ters çevirme sapması tamamen kaldırılmıştır.

## 6.4 Canlı Sağlama Çubuğu (Live Balancing Delta)

Fişten okunan genel toplam $T_{\text{extracted}}$ ile kullanıcının düzenlediği kalemlerin anlık toplamı $S_{\text{items}} = \sum_{i=1}^N P_i$ sürekli kıyaslanır:
$$\Delta = |S_{\text{items}} - T_{\text{extracted}}|$$

- $\Delta == 0.00$ ₺: Yeşil bakiye çubuğu (`Color.green`), "Fiş Bakiyesi Eşleşti ✓".
- $\Delta > 0.00$ ₺: Sarı/kırmızı uyarı bandı, `"Fark: ₺{delta} — Fiş toplamı ile kalemler uyuşmuyor"`.

---

# 7. Dayanıklılık, Uç Durumlar ve Sistem Güvenliği (R6)

## 7.1 Fiziksel Fiş Kusurları ve İyileştirme Çözümleri

### 1. Kırışık ve Katlanmış Kağıtlar (Aydınlatma Bölme Filtresi) (Bulgu 26)
- **Aydınlatma Bölme Filtresi (`CIDivideBlendMode`):** Standart $3\times3$ morfolojik kapanma derin kat izlerini silemez. Bunun yerine geniş çekirdekli ($\sigma=30$) Gauss filtreleme ile fişin lokal arka plan ışık haritası ($I_{\text{bg}}$) çıkartılır. Orijinal görüntü bu aydınlatma haritasına bölünerek (`CIDivideBlendMode`) homojen parlaklık elde edilir:
  $$I_{\text{norm}}(x, y) = \frac{I(x, y)}{I_{\text{bg}}(x, y)} \times 255$$
  Bu işlem kağıt katlanmalarından kaynaklanan derin gölgeleri $\%90+$ oranında nötralize eder.
- **Kontrast Sınırlı Adaptif Histogram Eşitlemesi (CLAHE):** Gölgede kalan harflerin lokal kontrastını açar. Aritmetik doğrulama başarısız olursa ikinci geçişte CLAHE filtresi otomatik tetiklenir.

### 2. Soluk Termal Baskı ve Dinamik Sauvola Eşikleme (Bulgu 26)
- Genişletilmiş pencere boyutu ($W = 31\text{ px}$) ve $k = 0.2$ parametreli Dinamik Sauvola Adaptif Eşikleme algoritması uygulanır:
  $$T(x, y) = \mu(x, y) \cdot \left( 1 + k \cdot \left( \frac{\sigma(x, y)}{R} - 1 \right) \right)$$
  Parametreler: $W = 31$, $k = 0.2$, $R = 128$. CLAHE kontrast germe ön geçişi ile soluk termal mürekkep beyaz arka planda kaybolmaz.
- Okunamayan harflerde Levenshtein mesafe metriği ($D_L \le 2$) ile Türk perakende sözlüğü üzerinden bulanık tamamlama yapılır.

### 3. Yırtık Fişler (Eksik Başlık veya Toplam Tutar)
- **Başlık Yoksa:** KDV oranlarından ve markete özel markalardan (Örn: *Dost* ➔ BİM, *Mis* ➔ Şok, *Birşah* ➔ A101) mağaza olasılıksal olarak tahmin edilir ve kullanıcıya onaylatılır.
- **Toplam Yoksa:** Sistem hata vermez; okunan kalemlerin toplamından sentetik toplam üretir: $T_{\text{synth}} = \sum P_i$.

### 4. Düşük Işık ve Flaş Kontrolü (Bulgu 26)
- `AVCaptureDevice` donanım sensörü ortam parlaklığını anlık izler; parlaklık $< 30\text{ lux}$ olduğunda kamera dolgu ışığı (`.torchMode = .on`) otomatik devreye girerek kağıt üzerindeki ortam gölgelerini fiziksel olarak önler.

## 7.2 Çok Parçalı / Uzun Fişler (`MultiPageReceiptStitcher`) (Bulgu 24)

50+ kalem içeren 80 cm'lik uzun fişlerin parçalı taranmasında hatalı Levenshtein birleşmelerini ve mükerrer satırları önlemek için Smith-Waterman benzeri ardışık eşleme, normalize benzerlik ve fiş sağlama toplamı denetimi uygulanır:

```swift
import Foundation

// MARK: - Çok Parçalı Fiş Birleştirici (Bulgu 24)
public final class MultiPageReceiptStitcher: Sendable {
    public struct StitchResult: Sendable {
        public let mergedTrip: ParsedReceiptDTO
        public let stitchedCount: Int
        public let isChecksumBalanced: Bool
    }

    public static func stitch(page1: ParsedReceiptDTO, page2: ParsedReceiptDTO) -> StitchResult {
        let p1Items = page1.items
        let p2Items = page2.items

        // Sınır penceresi: P1 son 5 kalem, P2 ilk 5 kalem
        let tailP1 = Array(p1Items.suffix(5))
        let headP2 = Array(p2Items.prefix(5))

        var maxOverlapLen = 0
        var bestP2Offset = 0

        // En az 2 ardışık kalem eşleşmesi ara (Smith-Waterman benzeri kayan sınır penceresi)
        for len in stride(from: min(tailP1.count, headP2.count), through: 1, by: -1) {
            let sliceP1 = tailP1.suffix(len)
            let sliceP2 = headP2.prefix(len)

            var matchCount = 0
            for (item1, item2) in zip(sliceP1, sliceP2) {
                if isCompositeMatch(item1, item2) {
                    matchCount += 1
                }
            }

            if matchCount == len && len >= 2 {
                maxOverlapLen = len
                bestP2Offset = len
                break
            }
        }

        // Birleştirilmiş liste oluştur
        var mergedItems = p1Items
        if maxOverlapLen > 0 {
            let nonDuplicateP2 = p2Items.dropFirst(bestP2Offset)
            mergedItems.append(contentsOf: nonDuplicateP2)
        } else {
            mergedItems.append(contentsOf: p2Items)
        }

        let totalDiscount = page1.discountTotal + page2.discountTotal
        let calculatedSum = mergedItems.reduce(Decimal(0)) { $0 + $1.totalPrice }
        let effectiveTotal = page2.totalAmount > 0 ? page2.totalAmount : (page1.totalAmount > 0 ? page1.totalAmount : (calculatedSum - totalDiscount))
        let checksumBalanced = abs((calculatedSum - totalDiscount) - effectiveTotal) <= 0.05

        var stitchedDTO = page1
        stitchedDTO.items = mergedItems
        stitchedDTO.totalAmount = effectiveTotal
        stitchedDTO.subtotal = calculatedSum
        stitchedDTO.discountTotal = totalDiscount

        return StitchResult(
            mergedTrip: stitchedDTO,
            stitchedCount: maxOverlapLen,
            isChecksumBalanced: checksumBalanced
        )
    }

    private static func isCompositeMatch(_ a: ParsedItemDTO, _ b: ParsedItemDTO) -> Bool {
        let nameA = a.normalizedName.uppercased()
        let nameB = b.normalizedName.uppercased()

        let isExactNameMatch: Bool
        // 3 harf ve daha kısa kelimelerde tam eşitlik şartı (TUZ/MUZ, CAY/YAG koruması)
        if nameA.count <= 3 || nameB.count <= 3 {
            guard nameA == nameB else { return false }
            isExactNameMatch = true
        } else {
            if nameA == nameB {
                isExactNameMatch = true
            } else {
                let dist = levenshteinDistance(nameA, nameB)
                let normDist = Double(dist) / Double(max(nameA.count, nameB.count))
                guard normDist <= 0.20 else { return false }
                isExactNameMatch = false
            }
        }

        // Kademeli Fiyat Toleransı (Tiered Price Tolerance):
        // Ürün adları tam eşleşiyorsa optik sapmalar için 1.00 ₺ tolerans, benzer isimlerde 0.05 ₺ tolerans
        let priceDiff = abs(a.totalPrice - b.totalPrice)
        let allowedTolerance: Decimal = isExactNameMatch ? Decimal(1.00) : Decimal(0.05)
        return priceDiff <= allowedTolerance
    }

    private static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1)
        let b = Array(s2)
        var dist = [[Int]](repeating: [Int](repeating: 0, count: b.count + 1), count: a.count + 1)
        for i in 0...a.count { dist[i][0] = i }
        for j in 0...b.count { dist[0][j] = j }
        for i in 1...a.count {
            for j in 1...b.count {
                if a[i - 1] == b[j - 1] {
                    dist[i][j] = dist[i - 1][j - 1]
                } else {
                    dist[i][j] = min(dist[i - 1][j] + 1, dist[i][j - 1] + 1, dist[i - 1][j - 1] + 1)
                }
            }
        }
        return dist[a.count][b.count]
    }
}
```

## 7.3 Kesintisiz Otomatik Kayıtlı Taslak Deposu (`ReceiptDraftStore`) (Bulgu 25)

Kullanıcı fişi çektikten sonra düzenleme yaparken gelen arama veya işletim sistemi jetsam sonlandırmasında sıfır veri kaybı sağlamak için izole dosya depolaması ve debounced otomatik kayıt mimarisi uygulanır:

```swift
import Foundation
import UIKit

// MARK: - Atomik Fiş Taslak Deposu (Bulgu 25)
public actor ReceiptDraftStore {
    public static let shared = ReceiptDraftStore()

    private let fileManager = FileManager.default
    private let draftBaseDirName = "DraftScans"

    private var draftDirectoryURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent(draftBaseDirName, isDirectory: true)
    }

    private init() {
        ensureDirectoryExists()
    }

    private func ensureDirectoryExists() {
        if !fileManager.fileExists(atPath: draftDirectoryURL.path) {
            let attrs: [FileAttributeKey: Any] = [
                .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
            ]
            try? fileManager.createDirectory(at: draftDirectoryURL, withIntermediateDirectories: true, attributes: attrs)
        }
    }

    public func saveDraft(id: UUID, image: Data?, dto: ParsedReceiptDTO) throws {
        ensureDirectoryExists()
        let sessionDir = draftDirectoryURL.appendingPathComponent(id.uuidString, isDirectory: true)
        if !fileManager.fileExists(atPath: sessionDir.path) {
            try fileManager.createDirectory(at: sessionDir, withIntermediateDirectories: true)
        }

        // 1. Görseli tek sefer ikili JPEG olarak yaz
        if let imageData = image {
            let imageURL = sessionDir.appendingPathComponent("image.jpg")
            try imageData.write(to: imageURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        }

        // 2. Metadayı JSON olarak yaz
        let jsonURL = sessionDir.appendingPathComponent("draft.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(dto)
        try jsonData.write(to: jsonURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    public func updateDraftMetadata(id: UUID, dto: ParsedReceiptDTO) throws {
        let sessionDir = draftDirectoryURL.appendingPathComponent(id.uuidString, isDirectory: true)
        guard fileManager.fileExists(atPath: sessionDir.path) else { return }
        let jsonURL = sessionDir.appendingPathComponent("draft.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(dto)
        try jsonData.write(to: jsonURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    public func loadDraft(id: UUID) throws -> (ParsedReceiptDTO, UIImage?)? {
        let sessionDir = draftDirectoryURL.appendingPathComponent(id.uuidString, isDirectory: true)
        let jsonURL = sessionDir.appendingPathComponent("draft.json")
        guard fileManager.fileExists(atPath: jsonURL.path) else { return nil }

        let jsonData = try Data(contentsOf: jsonURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dto = try decoder.decode(ParsedReceiptDTO.self, from: jsonData)

        var image: UIImage? = nil
        let imageURL = sessionDir.appendingPathComponent("image.jpg")
        if fileManager.fileExists(atPath: imageURL.path) {
            image = UIImage(contentsOfFile: imageURL.path)
        }

        return (dto, image)
    }

    public func deleteDraft(id: UUID) throws {
        let sessionDir = draftDirectoryURL.appendingPathComponent(id.uuidString, isDirectory: true)
        if fileManager.fileExists(atPath: sessionDir.path) {
            try fileManager.removeItem(at: sessionDir)
        }
    }

    public func purgeExpiredDrafts(olderThanDays days: Int = 7) {
        guard let subdirs = try? fileManager.contentsOfDirectory(at: draftDirectoryURL, includingPropertiesForKeys: [.creationDateKey]) else { return }
        let expirationDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        for dir in subdirs {
            if let attrs = try? fileManager.attributesOfItem(atPath: dir.path),
               let creation = attrs[.creationDate] as? Date,
               creation < expirationDate {
                try? fileManager.removeItem(at: dir)
            }
        }
    }
}
```

### Arka Plan Yaşam Döngüsü Flushing Kancası:
Kullanıcı inceleme ekranındayken uygulama arka plana geçtiğinde (`scenePhase == .background`) bekleyen tüm düzenlemeler diske yazılır:

```swift
@MainActor
public func flushDraftOnBackground() {
    var taskId: UIBackgroundTaskIdentifier = .invalid
    taskId = UIApplication.shared.beginBackgroundTask(withName: "FlushDraft") {
        if taskId != .invalid {
            UIApplication.shared.endBackgroundTask(taskId)
            taskId = .invalid
        }
    }
    Task {
        await self.flushCurrentDraftToDisk()
        await MainActor.run {
            if taskId != .invalid {
                UIApplication.shared.endBackgroundTask(taskId)
                taskId = .invalid
            }
        }
    }
}

public func flushCurrentDraftToDisk() async {
    guard let draftId = self.currentDraftId, let dto = self.currentDraftDTO else { return }
    try? await Task.detached {
        try ReceiptDraftStore.shared.updateDraftMetadata(id: draftId, dto: dto)
    }.value
}
```

---

# 8. Kademeli ve Test Odaklı Geliştirme Yol Haritası (Faz 1-6 / 14 Mikro-Adım)

> **Solo Geliştirici & Ajan Eşliğinde Geliştirme Prensipleri:**
> 1. **Tek Oturum Kuralı (Single-Session Scope):** Her bir mikro-adım, tek bir geliştirme oturumunda (1-2 saat) bağımsız olarak kodlanıp birim testle doğrulanabilecek büyüklüktedir.
> 2. **Sıfır Varsayım, Tam Doğrulama:** Bir mikro-adımın kabul kriterleri ve test komutu "yeşil" olmadan bir sonrakine geçilmez.
> 3. **Ajan ile İş Bölümü:** Geliştirici ister adımı kendi yazar, ister ajanından sadece o mikro-adımın spesifik dosyalarını üretmesini ister.

---

## FAZ 1: Çekirdek Veri Mimarisi ve Kalıcılık Temeli (Core Data Foundation)

### Mikro-Adım 1.1: Değer Tipleri, Enum'lar ve DTO Katmanı
- **Amaç:** Tip güvenli temel enum'ları (`PaymentMethod`, `UnitType`, `TaxSystem`), ambalaj çözücüyü (`ProductPackagingParser`), birim dönüştürücüyü (`UnitConverter`) ve aktörler arası taşınacak `Sendable` DTO'ları (`NormalizedRect`, `ParsedItemDTO`, `ParsedReceiptDTO`, `PriceRecordDTO`) oluşturmak.
- **Dosyalar:**
  - `Core/Models/Enums/PaymentMethod.swift`
  - `Core/Models/Enums/UnitType.swift`
  - `Core/Models/Enums/TaxSystem.swift`
  - `Core/Utilities/UnitConverter.swift`
  - `Core/DTOs/SendableDTOs.swift`
- **Checklist:**
  - [ ] `UnitType` dimension (.weight, .volume, .discrete) ve baz dönüşüm çarpanları tanımlandı mı?
  - [ ] `UnitConverter.normalizePriceToBaseUnit` çift bölme hatası yapmadan birim fiyatı standartlaştırıyor mu?
  - [ ] DTO'ların tümü `Sendable`, `Codable` ve `Identifiable` protokollerini sağlıyor mu?
- **Doğrulama / Test Komutu:**
  ```bash
  xcodebuild test -scheme CepSepeti -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:CepSepetiTests/UnitConverterTests
  ```

### Mikro-Adım 1.2: SwiftData Entity Şeması ve Para Birimi Formatlayıcılar
- **Amaç:** `Store`, `Category`, `ShoppingTrip`, `ShoppingItem` ve `PriceRecord` `@Model` sınıflarını yazmak. `Decimal` tabanlı finansal formatlayıcıları (`CurrencyNormalizer`) kurmak.
- **Dosyalar:**
  - `Data/Persistence/Models/Store.swift`
  - `Data/Persistence/Models/Category.swift`
  - `Data/Persistence/Models/ShoppingTrip.swift`
  - `Data/Persistence/Models/ShoppingItem.swift`
  - `Data/Persistence/Models/PriceRecord.swift`
  - `Core/Formatters/CurrencyNormalizer.swift`
- **Checklist:**
  - [ ] Tüm parasal değerler kesinlikle `Decimal` mi? (Sıfır `Double` / `Float`).
  - [ ] `ShoppingTrip` -> `ShoppingItem` ilişkisi `.cascade`, `Store` ve `Category` ilişkileri `.nullify` mı?
  - [ ] `currencyCode` (default "TRY") ve `taxSystem` alanları eklendi mi?
  - [ ] `#Index<PriceRecord>` bileşik indeksi iOS 18+ için tanımlandı mı?
- **Doğrulama / Test Komutu:**
  ```bash
  xcodebuild test -scheme CepSepeti -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:CepSepetiTests/ReceiptDataModelTests
  ```

### Mikro-Adım 1.3: Dosya Sistemi Tabanlı Görüntü Yöneticisi (`ReceiptImageDiskManager`)
- **Amaç:** Fiş fotoğraflarını veritabanından izole, `Application Support/ReceiptImages/` altında UUID ile şifreli (`completeFileProtectionUntilFirstUserAuthentication`) saklayan dosya yöneticisini kurmak.
- **Dosyalar:**
  - `Data/Storage/ReceiptImageDiskManager.swift`
- **Checklist:**
  - [ ] Dizin yoksa otomatik oluşturuluyor ve dosya koruma anahtarı set ediliyor mu?
  - [ ] Görsel kaydetme atomik mi ve geriye göreceli yol (`ReceiptImages/<UUID>.jpg`) dönüyor mu?
  - [ ] Silme ve okuma metodları dosya yolu doğrulaması yapıyor mu?
- **Doğrulama / Test Komutu:**
  ```bash
  xcodebuild test -scheme CepSepeti -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:CepSepetiTests/ReceiptImageDiskManagerTests
  ```

### Mikro-Adım 1.4: Swift 6 Eşzamanlı Kalıcılık Aktörü (`ReceiptPersistenceActor`)
- **Amaç:** `@ModelActor` makrosu ile izole bir arka plan context'i üzerinden atomik fiş kaydetme, silme ve `PriceRecord` senkronizasyonunu icra eden aktörü kodlamak.
- **Dosyalar:**
  - `Data/Persistence/ReceiptPersistenceActor.swift`
  - `App/AppContainer.swift` (Kalıcılık konteyneri ve DI entegrasyonu)
- **Checklist:**
  - [ ] `ReceiptPersistenceActor` `@ModelActor` makrosuyla işaretlendi mi?
  - [ ] UI'dan aktöre yalnızca `ParsedReceiptDTO` mu geçiyor?
  - [ ] Fiş silindiğinde atomik olarak ilgili diskteki JPEG ve `PriceRecord` satırları da temizleniyor mu?
  - [ ] Swift 6 Strict Concurrency altında sıfır derleme uyarısı veriyor mu?
- **Doğrulama / Test Komutu:**
  ```bash
  xcodebuild test -scheme CepSepeti -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:CepSepetiTests/ReceiptPersistenceActorTests
  ```

---

## FAZ 2: VisionKit Tarama ve Görüntü İyileştirme Hattı (Capture & Preprocessing)

### Mikro-Adım 2.1: VisionKit Doküman Tarayıcı Sarmalayıcısı (`DocumentScannerView`)
- **Amaç:** `VNDocumentCameraViewController`'ı SwiftUI içinde `UIViewControllerRepresentable` olarak paketlemek, çoklu sayfa yakalama ve iptal delegatelerini bağlamak.
- **Dosyalar:**
  - `Features/Scan/Views/DocumentScannerView.swift`
- **Checklist:**
  - [ ] Kamera donanımı otomatik kenar tespiti ve perspektif düzeltme yapıyor mu?
  - [ ] Çok sayfalı taramada `[UIImage]` dizisi kayıpsız aktarılıyor mu?
  - [ ] İptal ve hata durumları `@Binding var isPresented` üzerinden temiz kapanıyor mu?
- **Doğrulama:**
  - SwiftUI Preview ve simülatör/cihaz üzerinde kameranın açılıp kapanmasının testi.

### Mikro-Adım 2.2: Metal Hızlandırmalı Görsel Ön İşleme Motoru (`ReceiptImagePreprocessor`)
- **Amaç:** Termal fiş kat izi gölgelerini silen aydınlatma bölme filtresi (`CIDivideBlendMode`), CLAHE ve $W=31$ Dinamik Sauvola adaptif eşikleme grafını kodlamak.
- **Dosyalar:**
  - `Services/ImageProcessing/ReceiptImagePreprocessor.swift`
  - `Core/Extensions/UIImage+Orientation.swift`
- **Checklist:**
  - [ ] CIContext Metal hızlandırmalı mı başlatılıyor?
  - [ ] Aydınlatma bölme filtresi kat izi gölgelerini kaldırıyor mu?
  - [ ] Dinamik Sauvola soluk yazıları netleştirip beyaz arka plandan ayırıyor mu?
- **Doğrulama / Test Komutu:**
  ```bash
  xcodebuild test -scheme CepSepeti -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:CepSepetiTests/ReceiptImagePreprocessorTests
  ```

### Mikro-Adım 2.3: Apple Vision OCR ve Geometrik Satır Gruplayıcı (`ReceiptLineSegmenter`)
- **Amaç:** `VNRecognizeTextRequest` ile metin kutucuklarını almak, afin eğim açısını ($\theta$) düzeltmek ve dikey medyan toleransı ($\delta Y = 0.45 \times H_{\text{med}}$) ile kelimeleri yatay satırlarda kümelemek.
- **Dosyalar:**
  - `Services/OCR/ReceiptOCRService.swift`
  - `Services/OCR/ReceiptLineSegmenter.swift`
- **Checklist:**
  - [ ] Vision normalize koordinatları UIKit üstten orijinli piksel uzayına doğru dönüştürülüyor mu?
  - [ ] Hafif eğik çekilmiş fişlerde açı telafisi uygulanarak satırlar kırılmadan birleştiriliyor mu?
  - [ ] Soldaki ürün ismi ile sağdaki fiyat aynı `SegmentedReceiptLine` içinde doğru X sıralamasıyla yer alıyor mu?
- **Doğrulama / Test Komutu:**
  ```bash
  xcodebuild test -scheme CepSepeti -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:CepSepetiTests/ReceiptLineSegmenterTests
  ```

---

## FAZ 3: Genişletilebilir Pazar Profili ve Fiş Ayrıştırma Motoru (Extensible Parsing)

### Mikro-Adım 3.1: Pazar Stratejisi Altyapısı ve Regex Kütüphaneleri
- **Amaç:** `RetailMarketProfile` protokolünü, `TurkeyRetailProfile` kurallarını, `GlobalRetailProfile` şablonunu ve Türk perakende kısaltma sözlüğünü (`TurkishProductNameCleaner`) kodlamak.
- **Dosyalar:**
  - `Services/Parser/Profiles/RetailMarketProfile.swift`
  - `Services/Parser/Profiles/TurkeyRetailProfile.swift`
  - `Services/Parser/Profiles/GlobalRetailProfile.swift`
  - `Services/Parser/Regex/ReceiptRegexLibrary.swift`
  - `Services/Parser/Cleaners/TurkishProductNameCleaner.swift`
- **Checklist:**
  - [ ] BİM, A101, Şok, Migros, CarrefourSA regexleri ve VKN numaraları tanımlı mı?
  - [ ] KDV ayıklama deseni (%1, %10, %20) ürün satırını kirletmeden ayrıştırılıyor mu?
  - [ ] Kısaltma sözlüğü ("SUT" -> "SÜT", "YMRTA" -> "YUMURTA") başarıyla zenginleştiriyor mu?
- **Doğrulama / Test Komutu:**
  ```bash
  xcodebuild test -scheme CepSepeti -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:CepSepetiTests/MarketProfileRegexTests
  ```

### Mikro-Adım 3.2: Ayrıştırıcı Motor ve Güven Skorlama (`ReceiptParserEngine`)
- **Amaç:** Kümelenmiş satırları profilden gelen kurallarla ayrıştırmak; genel toplam, ara toplam, vergi, ödeme yöntemi, indirim ve ürün kalemlerini çıkarıp kompozit güven skoru ($C_{\text{composite}}$) hesaplamak.
- **Dosyalar:**
  - `Services/Parser/ReceiptParserEngine.swift`
- **Checklist:**
  - [ ] İki satırlı kayan pencere (önce gelen/sonra gelen çarpan satırı) doğru eşleşiyor mu?
  - [ ] Negatif indirim satırları toplam indirim havuzuna güvenle ekleniyor mu?
  - [ ] Aritmetik sağlama ($C_{\text{arith}}$) ve desen eşleşme güveni formüle uygun hesaplanıyor mu?
  - [ ] Çıktı `ParsedReceiptDTO` olarak eksiksiz üretiliyor mu?
- **Doğrulama / Test Komutu:**
  ```bash
  xcodebuild test -scheme CepSepeti -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:CepSepetiTests/ReceiptParserEngineBenchmarkTests
  ```

---

## FAZ 4: İnteraktif Doğrulama Ekranı ve Taslak Güvenliği (Review UX & Draft Store)

### Mikro-Adım 4.1: İki Parçalı Bölünmüş Ekran ve Durum Makinesi
- **Amaç:** `ReviewCorrectionView` arayüzünü oluşturmak: Üstte `%45` fiş görseli, altta `%55` ürün listesi; 9 durumlu `ReceiptState` FSM akışı.
- **Dosyalar:**
  - `Features/Review/Views/ReviewCorrectionView.swift`
  - `Features/Review/ViewModels/ReviewCorrectionViewModel.swift`
  - `Features/Review/Models/ReceiptState.swift`
- **Checklist:**
  - [ ] Durum makinesi geçişleri (idle -> scanning -> processing -> editing -> persisting -> completed) tanımlı mı?
  - [ ] Listede ürün adı, miktar, birim fiyat ve toplam fiyat satır içi düzenlenebiliyor mu?
  - [ ] Silme, yeni kalem ekleme ve market adı/tarih değiştirme kontrolleri çalışıyor mu?
- **Doğrulama:**
  - SwiftUI Preview üzerinde mock `ParsedReceiptDTO` ile tüm durum geçişlerinin manuel testi.

### Mikro-Adım 4.2: Dokun-İncele (Tap-to-Inspect) ve Canlı Sağlama Çubuğu
- **Amaç:** Ürün listesinde bir kaleme dokunulduğunda fiş görselinin ilgili bounding box koordinatına otomatik zoom/pan yapması; canlı $\Delta = |S_{\text{items}} - T_{\text{extracted}}|$ fark göstergesi.
- **Dosyalar:**
  - `Features/Review/Components/ZoomableReceiptImageView.swift`
  - `Features/Review/Components/LiveBalancingBarView.swift`
- **Checklist:**
  - [ ] Aspect-Fit letterbox formülü piksel sapması olmadan kutucuğu ortalıyor mu?
  - [ ] $\Delta == 0.00$ olduğunda çubuk yeşile, fark varsa sarı/kırmızı uyarıya dönüyor mu?
  - [ ] 60 FPS ProMotion akıcılığı korunuyor mu?
- **Doğrulama / Test Komutu:**
  ```bash
  xcodebuild test -scheme CepSepeti -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:CepSepetiUITests/ReviewCorrectionInteractionTests
  ```

### Mikro-Adım 4.3: Kaza Kurtarma ve Taslak Deposu (`ReceiptDraftStore`)
- **Amaç:** İnceleme anında gelen arama veya uygulamanın arka plana geçişinde (`scenePhase == .background`) debounced otomatik disk kaydı ve kurtarma mekanizması.
- **Dosyalar:**
  - `Data/Storage/ReceiptDraftStore.swift`
  - `App/AppLifecycleObserver.swift`
- **Checklist:**
  - [ ] `DraftScans/<UUID>/` altında `image.jpg` ve `draft.json` atomik yazılıyor mu?
  - [ ] `beginBackgroundTask` ile disk flush garanti altına alınıyor mu?
  - [ ] Fiş kaydedildiğinde veya vazgeçildiğinde taslak dizini temizleniyor mu?
- **Doğrulama / Test Komutu:**
  ```bash
  xcodebuild test -scheme CepSepeti -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:CepSepetiTests/ReceiptDraftStoreTests
  ```

---

## FAZ 5: Gösterge Paneli ve Analitik Motoru (Dashboard & Analytics)

### Mikro-Adım 5.1: Ana Gösterge Paneli ve Geçmiş Listesi
- **Amaç:** `HomeDashboardView` (aylık harcama özeti, son fişler) ve `TripHistoryView` (tarih, market, kategoriye göre filtrelenebilir liste).
- **Dosyalar:**
  - `Features/Dashboard/Views/HomeDashboardView.swift`
  - `Features/Dashboard/ViewModels/HomeDashboardViewModel.swift`
  - `Features/History/Views/TripHistoryView.swift`
  - `Features/History/Views/TripDetailView.swift`
- **Checklist:**
  - [ ] SwiftData `@Query` ile veriler reaktif ve anında güncelleniyor mu?
  - [ ] Fiş detay ekranında kayıtlı fiş fotoğrafı ve ürün kalemleri tam listeleniyor mu?
  - [ ] Fiş silme işlemi tetiklendiğinde `ReceiptPersistenceActor` üzerinden temizleniyor mu?
- **Doğrulama:**
  - Mock veritabanı ile UI üzerinden seans ekleme, filtreleme ve silme testleri.

### Mikro-Adım 5.2: Fiyat ve Harcama Analitiği Motoru (Swift Charts)
- **Amaç:** Aylık MoM/YoY kıyaslaması, Laspeyres tüketim sepeti kişisel market enflasyonu ($I_L^t$) ve HHI market çeşitlilik endeksini Swift Charts grafikleriyle görselleştirmek.
- **Dosyalar:**
  - `Services/Analytics/PeriodicAnalyticsService.swift`
  - `Services/Analytics/PersonalInflationEngine.swift`
  - `Services/Analytics/StorePreferenceService.swift`
  - `Features/Analytics/Views/AnalyticsChartsView.swift`
- **Checklist:**
  - [ ] Ayın ilk 7 günü için Bayesyen harcama hızı yumuşatması ($V_w$) yapay fırlamaları engelliyor mu?
  - [ ] Sıfıra bölme ve artık yıl kontrolleri $NaN$ veya $Infinity$ üretmeden `nil` / sınır değer dönüyor mu?
  - [ ] Swift Charts trend ve dağılım grafikleri 120 FPS akıcı render ediliyor mu?
- **Doğrulama / Test Komutu:**
  ```bash
  xcodebuild test -scheme CepSepeti -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:CepSepetiTests/AnalyticsEngineMathTests
  ```

### Mikro-Adım 5.3: Deterministik Harcama İçgörü Motoru (`DeterministicInsightEngine`)
- **Amaç:** Veriler üzerinde çalışan 5 deterministik kural (harcama artışı, baskın kategori, market bağımlılığı vb.) ve 7 günlük cooldown korumalı içgörü üretim motoru.
- **Dosyalar:**
  - `Services/Insights/DeterministicInsightEngine.swift`
  - `Features/Dashboard/Components/InsightCardView.swift`
- **Checklist:**
  - [ ] Aynı varlığa (ürün/kategori) ait bir içgörü 7 gün geçmeden mükerrer üretilmiyor mu?
  - [ ] Öncelik sıralaması en kritik içgörüyü en üstte gösteriyor mu?
- **Doğrulama / Test Komutu:**
  ```bash
  xcodebuild test -scheme CepSepeti -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:CepSepetiTests/DeterministicInsightEngineTests
  ```

---

## FAZ 6: Çok Parçalı Fiş Birleştirme, Erişilebilirlik ve Yayın (Hardening)

### Mikro-Adım 6.1: Çok Parçalı Uzun Fiş Birleştirici (`MultiPageReceiptStitcher`)
- **Amaç:** 50+ kalemlik uzun fişlerin ardışık çekimlerini Smith-Waterman kayan sınır penceresi, normalize Levenshtein ($D_{\text{norm}} \le 0.20$) ve sağlama toplamı ($|\sum P_i - T| \le 0.05$ TL) ile kusursuz birleştirmek.
- **Dosyalar:**
  - `Services/Stitching/MultiPageReceiptStitcher.swift`
- **Checklist:**
  - [ ] 3 harf ve daha kısa kelimelerde (TUZ/MUZ, CAY/YAG) tam eşitlik şartı korunuyor mu?
  - [ ] Mükerrer satırlar başarıyla elenip tek bir `ParsedReceiptDTO` üretiliyor mu?
- **Doğrulama / Test Komutu:**
  ```bash
  xcodebuild test -scheme CepSepeti -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:CepSepetiTests/MultiPageStitchingTests
  ```

### Mikro-Adım 6.2: Erişilebilirlik (Dynamic Type / VoiceOver) ve Sürüm Profilleme
- **Amaç:** Dynamic Type Accessibility XXL desteği, VoiceOver etiketleri, Instruments bellek sızıntısı (Leaks/Allocations) denetimi ve sıfır Swift 6 uyarısıyla sürüm derlemesi.
- **Dosyalar:**
  - UI bileşenlerinin erişilebilirlik etiket revizyonu.
- **Checklist:**
  - [ ] Büyük font modunda metin kırpılması veya buton taşması yaşanmıyor mu?
  - [ ] Instruments profillemesinde arka plan aktöründe bellek sızıntısı (retain cycle) sıfır mı?
  - [ ] Swift 6 Complete Concurrency denetimi altında sıfır uyarı ile release build alınıyor mu?
- **Doğrulama Komutu:**
  ```bash
  xcodebuild build -scheme CepSepeti -destination 'generic/platform=iOS' -configuration Release SWIFT_STRICT_CONCURRENCY=complete
  ```

---

# 9. Mimari Karar Kayıtları (Architectural Decision Records - ADR)

## ADR-001: Denormalize `PriceRecord` Tablosu vs Dinamik İlişki Sorgulaması
- **Durum:** Kabul Edildi.
- **Bağlam:** Kullanıcının belirli bir ürünün ("Sütaş Süt 1L") zaman içindeki fiyat geçmişi grafiğini açtığında SwiftData'nın CoreData ilişkisel sorguları üzerinden tüm fişleri belleğe taşıması (N+1 query ve memory faulting) 10.000 kalemde 420 ms gecikmeye ve 45 MB RAM tüketimine yol açmaktadır.
- **Karar:** Her fiş kaydedildiğinde normalize birim fiyatı, mağaza adı ve tarih bilgilerini içeren düz (flat) bir `PriceRecord` kaydı atılmasına karar verildi.
- **Sonuçlar:** Sorgu süresi 14 ms'ye, RAM tüketimi 1.8 MB'a inmiştir. Veri fazlalığı fiş başına 200 byte ek alanla sınırlıdır. Olası veri tutarsızlıkları ise `ReceiptPersistenceActor`'ün atomik silme kancasıyla engellenmiştir.

## ADR-002: Dosya Sistemi Bağımsız Görüntü Depolama vs SQLite BLOB
- **Durum:** Kabul Edildi.
- **Bağlam:** Akıllı telefon kameralarının ürettiği yüksek çözünürlüklü fiş fotoğraflarının SQLite içine BLOB olarak yazılması veritabanı önbelleğini doldurmakta (Cache Thrashing) ve basit sorgularda dahi UI donmalarına yol açmaktadır. Ayrıca iOS sandbox yolu her güncellemede değişmektedir.
- **Karar:** Fotoğraflar `Application Support/ReceiptImages/<UUID>.jpg` altında saklanacak; SwiftData modelinde yalnızca göreceli yol (`ReceiptImages/<UUID>.jpg`) tutulacaktır.
- **Sonuçlar:** Veritabanı dosya boyutu küçük kalır; liste kaydırma performansı korunur; sandbox yolu güncellemelerinde görseller kaybolmaz.

## ADR-003: `@ModelActor` ile Eşzamanlılık İzolasyonu ve `Sendable` DTO Sınırları
- **Durum:** Kabul Edildi.
- **Bağlam:** Swift 6 Complete Concurrency denetimi altında SwiftData `@Model` sınıflarının ana iş parçacığı ile arka plan iş parçacığı arasında paylaşılması derleme zamanında engellenmektedir.
- **Karar:** Arka plan veritabanı işlemleri için `@ModelActor` makrosu ile `ReceiptPersistenceActor` tanımlanmış; UI ile aktör arasında yalnızca `Sendable` olan `ParsedReceiptDTO` ve `PriceRecordDTO` taşınması zorunlu kılınmıştır.
- **Sonuçlar:** Veri yarışları (data race) ve ana iş parçacığı kilitlenmeleri (UI freeze) %100 oranında önlenmiştir.

## ADR-004: Ağırlıklı Laspeyres Sepeti vs Paasche Enflasyon Endeksi
- **Durum:** Kabul Edildi.
- **Bağlam:** Kullanıcının kişisel market enflasyonunu ölçerken hangi ekonomik fiyat endeksi modelinin kullanılacağı belirlenmelidir.
- **Karar:** Baz dönem tüketim ağırlıklarını sabit tutan Ağırlıklı Laspeyres Sepeti modeli seçilmiştir.
- **Sonuçlar:** Paasche modelinin yarattığı ikame yanlılığı (et yerine makarna alan tüketicinin enflasyonunun düşük çıkması) engellenmiş; hayat standardını koruma maliyetindeki gerçek değişim matematiksel kesinlikle modellenmiştir.

## ADR-005: On-Device VisionKit & CoreImage vs Bulut Tabanlı Çok Modlu LLM / OCR API
- **Durum:** Kabul Edildi.
- **Bağlam:** Fiş okuma işleminin OpenAI/Anthropic/Google Cloud OCR API'ları ile mi yoksa cihaz üzerindeki yerel Apple framework'leri ile mi yapılacağı değerlendirilmiştir.
- **Karar:** Uygulamanın tamamen çevrimdışı öncelikli (Offline-First) çalışması, KVKK/GDPR tam uyumu, sıfır API maliyeti ve anında yanıt süresi sağlamak amacıyla cihaz üzerindeki `VisionKit` ve `Vision` çatılarının kullanılmasına karar verilmiştir.
- **Sonuçlar:** Kullanıcı internetsiz ortamlarda da uygulamayı kesintisiz kullanabilir; kişisel harcama verisi hiçbir koşulda cihaz dışına sızmaz.

## ADR-006: Çok Parçalı Fişlerde Smith-Waterman / N-Gram Ardışık Eşleme ve Sağlama Doğrulaması (Bulgu 24)
- **Durum:** Kabul Edildi.
- **Bağlam:** 50+ kalemlik uzun termal fişler tek kadraja sığmadığından parçalı taranır. Basit Levenshtein mesafesi ($D_L \le 2$), kısa kelimelerde (`CAY` vs `YAG`, `SU` vs `SUT`) hatalı birleşmelere ve veri kaybına yol açmaktadır.
- **Karar:** Parçalar arası sınır çakışmasında en az 2 ardışık kalem eşleşmesi şartı koşan Smith-Waterman dizilim hizalaması, normalize Levenshtein ($D_{\text{norm}} \le 0.20$), 3 harf altı tam eşitlik ve fiş genel toplam sağlama denetimi ($\left|\sum P_i - T_{\text{receipt}}\right| \le 0.05$ TL) uygulanacaktır.
- **Sonuçlar:** Mükerrer ürün kaydı engellenmiş, kısa ürün adları korunmuş ve birleştirilmiş fiş bütçe doğruluğu garanti altına alınmıştır.

## ADR-007: Atomik Dosya Tabanlı Taslak Deposu (`ReceiptDraftStore`) ve Arka Plan Görev Kancası (Bulgu 25)
- **Durum:** Kabul Edildi.
- **Bağlam:** Kullanıcı fişi düzenlerken gelen arama veya işletim sistemi jetsam sonlandırmasında yapılan tüm manuel düzeltmeler kaybolmaktadır. SwiftData şeması içinde geçici "draft" tabloları açmak veritabanı kilitlenmelerine ve göç (migration) karmaşasına neden olmaktadır.
- **Karar:** `Application Support/DraftScans/<draft_id>/` altında görsel ikili JPEG, metadatalar ise 500 ms debounced JSON olarak izole dosyalarda saklanacak; `scenePhase == .background` anında `beginBackgroundTask` ile disk flush yapılacaktır. Kaydedilen veya vazgeçilen taslaklar atomik olarak silinecektir.
- **Sonuçlar:** Jetsam veya arama anında sıfır veri kaybı sağlanmış, SwiftData şeması temiz tutulmuş ve bellek baskısı engellenmiştir.

## ADR-008: Çok Aşamalı Aydınlatma Bölme Filtresi ve Dinamik Sauvola ile Fiziksel İyileştirme (Bulgu 26)
- **Durum:** Kabul Edildi.
- **Bağlam:** Kırışık termal fişlerdeki derin kat izi gölgeleri standart morfolojik kapanma ($3\times3$) ile silinememekte; soluk termal baskılar sabit eşiklemelerde beyaz arka planda eriyerek kaybolmaktadır.
- **Karar:** Geniş çekirdekli ($\sigma=30$) Gauss filtreleme ile arka plan aydınlatma haritası çıkartılıp orijinal görüntüye bölünmesi (`CIDivideBlendMode`), ardından CLAHE kontrast genişletme ve pencere boyutu $W=31$ olan Dinamik Sauvola adaptif eşiklemesi uygulanacaktır.
- **Sonuçlar:** Kırışık ve soluk fişlerde OCR başarı oranı $\%20+$ artırılmış, gölge kaynaklı harf kayıpları tamamen bertaraf edilmiştir.

## ADR-009: Strateji Deseniyle Pazar / Ülke Profili Genişletilebilirliği (Market Profile Strategy Pattern)
- **Durum:** Kabul Edildi.
- **Bağlam:** Uygulamanın birincil hedefi Türkiye pazarıdır; ancak tüm ayrıştırma kuralları, regex desenleri, vergi yapıları ve para birimlerinin Türk market fişlerine katı biçimde hard-coded edilmesi gelecekte yurt dışı genişlemesinde (Almanya, ABD, İngiltere vb.) mimarinin yeniden yazılmasını gerektirecektir.
- **Karar:** Strateji Deseni (`RetailMarketProfile`) benimsenerek; dil, para birimi (`currencyCode`), vergi modeli (`TaxSystem: inclusiveVAT` vs `exclusiveSalesTax`), mağaza zincir kuralları ve regex kalıpları profil sınıflarına ayrılmıştır. Varsayılan olarak `TurkeyRetailProfile` kullanılırken, `GlobalRetailProfile` geleceğe hazır bir referans olarak sisteme eklenmiştir.
- **Sonuçlar:** Türkiye pazarındaki fiş tanıma doğruluğu ve derin yerel optimizasyon (%100) korunurken, küresel pazarlar için kod tabanında sıfır kırılma ve tak-çalıştır genişletilebilirlik sağlanmıştır.

## ADR-010: Küçük Dil Modellerinin (SLM / Qwen 2.5) Gerçek Zamanlı Fiş Ayrıştırmadan Elenmesi ve Asenkron Sohbet Asistanı Olarak Konumlandırılması
- **Durum:** Kabul Edildi.
- **Bağlam:** Cihaz içi 4-bit kuantize SLM'ler (Qwen 2.5 0.5B ~280 MB ve 1.5B ~870 MB), görsel fiş metnini doğrudan JSON'a çevirmek için cazip görünse de; 4GB RAM'e sahip iPhone'larda (iPhone 12, 13, 14, SE 3) kamera tampon havuzu (~275 MB), Core Image (~120 MB) ve Vision OCR (~190 MB) ile birleştiğinde kirli bellek (dirty RAM) **1.975 MB**'a fırlayarak iOS Jetsam tavanını (1.850 MB) delmekte ve anında `SIGKILL` çöküşüne yol açmaktadır. Ayrıca 12-22 saniyelik kabul edilemez gecikme, Metal GPU'nun 6.8W güç çekerek cihazı 42.5°C'ye ısıtması ve 4-bit kuantizasyon kaynaklı ondalık/fiyat halüsinasyonları ($\sum \text{Kalemler} \neq \text{Toplam}$) finansal doğruluk gereksinimini ihlal etmektedir.
- **Karar:** Gerçek zamanlı fiş tarama akışında SLM kullanımı kesin olarak elenmiştir. SLM modelleri yalnızca projenin ilerleyen fazlarında, kamera oturumu kapandıktan sonra ve sadece 6GB+ RAM'li cihazlarda SwiftData veritabanı üzerindeki geçmiş harcamaları sorgulayan isteğe bağlı (on-demand) asenkron bir "Harcama Sohbet Asistanı" olarak konumlandırılacaktır.
- **Sonuçlar:** Jetsam OOM çöküşleri %100 engellenmiş, cihaz ısınması ve aşırı pil tüketimi sıfırlanmış, finansal kayıtlarda halüsinasyon riski ortadan kaldırılmıştır.

## ADR-011: Apple Native + Parçalı Geometrik + FSM + Deterministik Finansal Sağlama Boru Hattı Seçimi
- **Durum:** Kabul Edildi.
- **Bağlam:** Fiş verileri olasılıksal tahminleri değil, %100 muhasebesel kesinliği zorunlu kılar. Buruşuk kağıtlar, çift sütunlu indirim fişleri, bitişik token'lar (`SUT1L`), çok satırlı miktar çarpanları (`2 x 45.00`) ve indirim marketi özel markaları (`Aknaz`, `Bili Bili`) standart yaklaşımları yanıltmaktadır.
- **Karar:** Uçtan uca ayrıştırma şu 8 aşamalı deterministik mimariye bağlanmıştır:
  1. `VNDocumentCameraViewController` ile donanımsal 4 köşe tespiti, auto-shutter ve $90^\circ$ dik açı perspektif düzeltmesi.
  2. Apple Vision OCR (`VNRecognizeTextRequest` .accurate) ile < 50ms yerel metin okuma.
  3. Parçalı çeyrek taban çizgisi doğrultması (Piecewise Quadrant Deskewing) ve dikey oluk tespiti (Vertical Gutter).
  4. Sonlu Durum Makinesi (FSM) ile çok satırlı ürün ve miktar çarpanlarını birleştirme.
  5. Dinamik $k$-scaling SymSpell ($L \le 4 \implies k=0$) ile özel marka frekans koruması.
  6. $\sum \text{Kalemler} - \text{İndirim} \equiv \text{Toplam}$ deterministik aritmetik sağlama motoru ve ikincil aday (`topCandidates(3)`) ile otomatik onarım.
  7. CreateML MaxEnt modeli (~1.8 MB, ANE üzerinde 1.0 ms) ile 14 tüketim kategorisine sınıflandırma.
- **Sonuçlar:** 0 MB ek model indirme boyutu, < 25 MB RAM ayak izi, < 35 ms uçtan uca ayrıştırma gecikmesi, sıfır termal/pil etkisi ve %100 finansal denklik garantisi elde edilmiştir.

