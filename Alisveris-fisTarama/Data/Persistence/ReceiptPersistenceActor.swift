//
//  ReceiptPersistenceActor.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Foundation
import SwiftData

@ModelActor
public actor ReceiptPersistenceActor: ReceiptPersistenceServiceProtocol {

    public var imageDiskManager: any ReceiptImageDiskManagerProtocol = ReceiptImageDiskManager.shared

    public func persistReceipt(
        dto: ParsedReceiptDTO,
        imageData: Data?
    ) throws -> PersistentIdentifier {
        let context = self.modelContext

        // 1. Görseli dosya sistemine kaydet
        var storedRelativePath: String? = dto.imageRelativePath
        if let imageData = imageData, storedRelativePath == nil {
            let filename = "\(UUID().uuidString).jpg"
            storedRelativePath = try imageDiskManager.saveReceiptImage(
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

            // Ambalaj çözümü ve birim fiyat normalizasyonu
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
            try? imageDiskManager.deleteImage(relativePath: relativePath)
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
