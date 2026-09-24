//
//  ReceiptDraftStoreTests.swift
//  Alisveris-fisTaramaTests
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Testing
import Foundation
import UIKit
@testable import Alisveris_fisTarama

struct ReceiptDraftStoreTests {

    @Test func testSaveLoadAndDeleteDraft() async throws {
        let store = ReceiptDraftStore.shared
        let draftId = UUID()

        let dummyDTO = ParsedReceiptDTO(
            storeName: "BİM",
            storeBranch: nil,
            storeAddress: nil,
            storeTaxNumber: "1750051846",
            date: Date(),
            receiptNumber: "0099",
            subtotal: Decimal(100),
            discountTotal: Decimal(0),
            totalAmount: Decimal(100),
            taxTotal: Decimal(1),
            paymentMethod: .cash,
            items: [
                ParsedItemDTO(
                    rawName: "DOST SUT 1L",
                    normalizedName: "DOST SÜT 1L",
                    quantity: Decimal(2),
                    unit: .piece,
                    unitPrice: Decimal(50),
                    totalPrice: Decimal(100),
                    taxRate: Decimal(0.01),
                    confidenceScore: 0.95,
                    boundingBox: NormalizedRect(originX: 0, originY: 0, width: 0, height: 0)
                )
            ],
            rawOcrText: "BİM DOST SUT 100",
            confidenceScore: 0.9
        )

        // 1. Taslak Kaydet
        try await store.saveDraft(id: draftId, image: nil, dto: dummyDTO)

        // 2. Taslak Yükle
        let loaded = try await store.loadDraft(id: draftId)
        #expect(loaded != nil)
        #expect(loaded?.0.storeName == "BİM")
        #expect(loaded?.0.receiptNumber == "0099")
        #expect(loaded?.0.items.count == 1)

        // 3. Taslak Sil
        try await store.deleteDraft(id: draftId)
        let deleted = try await store.loadDraft(id: draftId)
        #expect(deleted == nil)
    }

    @Test func testReviewCorrectionViewModelCalculations() async {
        let dummyDTO = ParsedReceiptDTO(
            storeName: "MİGROS",
            storeBranch: nil,
            storeAddress: nil,
            storeTaxNumber: nil,
            date: Date(),
            receiptNumber: "1234",
            subtotal: Decimal(150),
            discountTotal: Decimal(10),
            totalAmount: Decimal(140),
            taxTotal: Decimal(1),
            paymentMethod: .creditCard,
            items: [
                ParsedItemDTO(
                    rawName: "SUT",
                    normalizedName: "SÜT",
                    quantity: Decimal(1),
                    unit: .piece,
                    unitPrice: Decimal(50),
                    totalPrice: Decimal(50),
                    taxRate: Decimal(0.01),
                    confidenceScore: 0.9,
                    boundingBox: NormalizedRect(originX: 0, originY: 0, width: 0, height: 0)
                ),
                ParsedItemDTO(
                    rawName: "PEYNIR",
                    normalizedName: "PEYNİR",
                    quantity: Decimal(1),
                    unit: .piece,
                    unitPrice: Decimal(100),
                    totalPrice: Decimal(100),
                    taxRate: Decimal(0.01),
                    confidenceScore: 0.9,
                    boundingBox: NormalizedRect(originX: 0, originY: 0, width: 0, height: 0)
                )
            ],
            rawOcrText: "MİGROS",
            confidenceScore: 0.95
        )

        let vm = await ReviewCorrectionViewModel(receiptDTO: dummyDTO, receiptImage: nil)
        let sum = await vm.calculatedItemsSum
        #expect(sum == Decimal(150))

        // Kalem düzenleme testi
        await vm.updateItemPrice(at: 0, newPrice: Decimal(60))
        let updatedSum = await vm.calculatedItemsSum
        #expect(updatedSum == Decimal(160))

        // Kalem silme testi
        await vm.deleteItem(at: 1)
        let countAfterDelete = await vm.receiptDTO.items.count
        #expect(countAfterDelete == 1)

        // Yeni kalem ekleme testi
        await vm.addNewItem()
        let countAfterAdd = await vm.receiptDTO.items.count
        #expect(countAfterAdd == 2)
    }
}
