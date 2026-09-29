//
//  ReceiptDataModelTests.swift
//  Alisveris-fisTaramaTests
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Testing
import Foundation
import SwiftData
@testable import Alisveris_fisTarama

private typealias Category = Alisveris_fisTarama.Category

@MainActor
struct ReceiptDataModelTests {

    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            Store.self,
            Category.self,
            ShoppingTrip.self,
            ShoppingItem.self,
            PriceRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    @Test func testCategoryClassificationAndSeeding() throws {
        let container = try makeInMemoryContainer()
        AppContainer.seedStandardCategories(in: container)

        let context = container.mainContext
        let categories = try context.fetch(FetchDescriptor<Category>())
        #expect(categories.count == 20)

        // CoreML Model Çıkarım Doğrulaması
        let mlService = ReceiptMLInferenceService()
        
        let sut = mlService.predictCategory(for: "DOST SÜT")
        #expect(sut.category == .dairyBreakfast)
        #expect(sut.rawCode == "DAIRY_BREAKFAST")

        let sucuk = mlService.predictCategory(for: "HARRAS KASAP SUCUK")
        #expect(sucuk.category == .meatPoultry)

        let domates = mlService.predictCategory(for: "DOMATES")
        #expect(domates.category == .produce)

        let deterjan = mlService.predictCategory(for: "ARIEL TOZ DETERJAN")
        #expect(deterjan.category == .cleaningHousehold)

        let poset = mlService.predictCategory(for: "ALIŞVERİŞ POŞETİ")
        #expect(poset.category == .otherNonFood)
    }

    @Test func testModelPersistenceAndRelationships() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let store = Store(name: "Migros", normalizedName: "migros", branch: "Kadıköy")
        let category = Category(name: "Gıda", iconName: "fork.knife", colorHex: "#34C759")

        let trip = ShoppingTrip(
            date: Date(),
            receiptNumber: "00123",
            totalAmount: Decimal(120),
            subtotal: Decimal(120),
            taxTotal: Decimal(1.20),
            paymentMethod: .creditCard,
            store: store
        )

        let item = ShoppingItem(
            rawName: "SUT 1L",
            normalizedName: "Süt 1 L",
            quantity: Decimal(2),
            unit: .liter,
            unitPrice: Decimal(35),
            totalPrice: Decimal(70),
            taxRate: Decimal(0.01),
            category: category,
            trip: trip
        )

        trip.items.append(item)

        context.insert(store)
        context.insert(category)
        context.insert(trip)
        try context.save()

        // Fetch back and assert
        let tripDescriptor = FetchDescriptor<ShoppingTrip>()
        let savedTrips = try context.fetch(tripDescriptor)
        #expect(savedTrips.count == 1)
        #expect(savedTrips.first?.store?.name == "Migros")
        #expect(savedTrips.first?.items.count == 1)
        #expect(savedTrips.first?.items.first?.totalPrice == Decimal(70))
        #expect(savedTrips.first?.items.first?.category?.name == "Gıda")
    }

    @Test func testCascadeAndNullifyDeleteRules() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let store = Store(name: "A101", normalizedName: "a101")
        let category = Category(name: "Temizlik", iconName: "sparkles")
        let trip = ShoppingTrip(
            date: Date(),
            totalAmount: Decimal(50),
            subtotal: Decimal(50),
            taxTotal: Decimal(10),
            paymentMethod: .cash,
            store: store
        )
        let item = ShoppingItem(
            rawName: "SABUN",
            normalizedName: "Sabun",
            quantity: Decimal(1),
            unit: .piece,
            unitPrice: Decimal(50),
            totalPrice: Decimal(50),
            taxRate: Decimal(0.20),
            category: category,
            trip: trip
        )
        trip.items.append(item)

        context.insert(store)
        context.insert(category)
        context.insert(trip)
        try context.save()

        // Delete the trip
        context.delete(trip)
        try context.save()

        // ShoppingItem should be cascade deleted
        let itemDescriptor = FetchDescriptor<ShoppingItem>()
        let items = try context.fetch(itemDescriptor)
        #expect(items.isEmpty)

        // Store and Category must NOT be deleted (Nullify rule)
        let storeDescriptor = FetchDescriptor<Store>()
        let stores = try context.fetch(storeDescriptor)
        #expect(stores.count == 1)

        let catDescriptor = FetchDescriptor<Category>()
        let categories = try context.fetch(catDescriptor)
        #expect(categories.count == 1)
    }

    @Test func testCurrencyFormatterAndNormalizer() {
        let amount = Decimal(1250.50)
        let currencyStr = amount.formattedAsCurrency()
        #expect(currencyStr.contains("1.250,50") || currencyStr.contains("1250,50"))

        let unitAmount = Decimal(34.5025)
        let detailedStr = unitAmount.formattedAsDetailedUnitPrice()
        #expect(detailedStr.contains("34,5025"))

        // Parsing Turkish currency strings
        let parsed1 = TurkishCurrencyNormalizer.parseDecimal(from: "1.250,50 TL")
        #expect(parsed1 == Decimal(1250.50))

        let parsed2 = TurkishCurrencyNormalizer.parseDecimal(from: "-45,00")
        #expect(parsed2 == Decimal(-45.00))

        let parsed3 = TurkishCurrencyNormalizer.parseDecimal(from: "₺ 89,90")
        #expect(parsed3 == Decimal(89.90))

        // Dot matrix OCR letter substitution (O -> 0, B -> 8)
        let parsedOCR = TurkishCurrencyNormalizer.parseDecimal(from: "1O,5O")
        #expect(parsedOCR == Decimal(10.50))
    }
}
