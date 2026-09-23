//
//  ReceiptPersistenceActorTests.swift
//  Alisveris-fisTaramaTests
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Testing
import Foundation
import SwiftData
import UIKit
@testable import Alisveris_fisTarama

private typealias Category = Alisveris_fisTarama.Category

@MainActor
struct ReceiptPersistenceActorTests {

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

    private func createTestImageData() -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40), format: format)
        let image = renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 40, height: 40))
        }
        return image.jpegData(compressionQuality: 0.8) ?? Data()
    }

    @Test func testPersistReceiptAndPriceHistory() async throws {
        let container = try makeInMemoryContainer()
        let actor = ReceiptPersistenceActor(modelContainer: container)

        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let diskManager = ReceiptImageDiskManager(fileManager: .default, customBaseURL: tempDir)
        await actor.setImageDiskManager(diskManager)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let item1 = ParsedItemDTO(
            rawName: "SUT 1L",
            normalizedName: "Süt 1 L",
            quantity: Decimal(2),
            unit: .liter,
            unitPrice: Decimal(35),
            totalPrice: Decimal(70),
            taxRate: Decimal(0.01)
        )

        let item2 = ParsedItemDTO(
            rawName: "KASAR 500G",
            normalizedName: "Kaşar Peyniri 500 g",
            quantity: Decimal(500),
            unit: .gram,
            unitPrice: Decimal(150),
            totalPrice: Decimal(150),
            taxRate: Decimal(0.01)
        )

        let receiptDTO = ParsedReceiptDTO(
            storeName: "MİGROS",
            storeBranch: "Ataşehir",
            storeTaxNumber: "1234567890",
            date: Date(),
            receiptNumber: "F-98765",
            subtotal: Decimal(220),
            totalAmount: Decimal(220),
            taxTotal: Decimal(2.20),
            paymentMethod: .creditCard,
            items: [item1, item2],
            confidenceScore: 0.95
        )

        let testImageData = createTestImageData()
        let tripID = try await actor.persistReceipt(dto: receiptDTO, imageData: testImageData)

        // Query price history
        let history = try await actor.fetchPriceHistoryDTOs(productNameNormalized: "Kaşar Peyniri 500 g", since: Date().addingTimeInterval(-86400))
        #expect(history.count == 1)
        #expect(history.first?.storeName == "MİGROS")
        // 500g for 150 TL -> normalized unit price should be 300 TL / kg
        #expect(history.first?.unitPriceNormalized == Decimal(300))
        #expect(history.first?.unit == .kilogram)

        // Delete trip
        try await actor.deleteTrip(id: tripID)

        // Price history should be purged for this deleted trip
        let historyAfterDelete = try await actor.fetchPriceHistoryDTOs(productNameNormalized: "Kaşar Peyniri 500 g", since: Date().addingTimeInterval(-86400))
        #expect(historyAfterDelete.isEmpty)
    }

    @Test func testStoreDeduplication() async throws {
        let container = try makeInMemoryContainer()
        let actor = ReceiptPersistenceActor(modelContainer: container)

        let item = ParsedItemDTO(
            rawName: "EKMEK",
            normalizedName: "Ekmek",
            quantity: Decimal(1),
            unit: .piece,
            unitPrice: Decimal(10),
            totalPrice: Decimal(10)
        )

        let dto1 = ParsedReceiptDTO(
            storeName: "BİM",
            date: Date(),
            subtotal: Decimal(10),
            totalAmount: Decimal(10),
            items: [item]
        )

        let dto2 = ParsedReceiptDTO(
            storeName: "  BİM  ",
            date: Date(),
            subtotal: Decimal(10),
            totalAmount: Decimal(10),
            items: [item]
        )

        _ = try await actor.persistReceipt(dto: dto1, imageData: nil)
        _ = try await actor.persistReceipt(dto: dto2, imageData: nil)

        // Context check: Store should be deduplicated (count == 1)
        let context = container.mainContext
        let stores = try context.fetch(FetchDescriptor<Store>())
        #expect(stores.count == 1)
        #expect(stores.first?.name == "BİM")
    }
}

private extension ReceiptPersistenceActor {
    func setImageDiskManager(_ manager: any ReceiptImageDiskManagerProtocol) {
        self.imageDiskManager = manager
    }
}
