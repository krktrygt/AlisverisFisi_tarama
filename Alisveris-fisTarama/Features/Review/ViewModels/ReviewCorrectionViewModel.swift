//
//  ReviewCorrectionViewModel.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import SwiftUI
import Observation

@Observable
@MainActor
public final class ReviewCorrectionViewModel {
    public var receiptDTO: ParsedReceiptDTO
    public var receiptImage: UIImage?
    public var activeItemIndex: Int?
    public var isPersisting: Bool = false
    public var errorMessage: String?

    public var activeBoundingBox: NormalizedRect? {
        guard let idx = activeItemIndex, receiptDTO.items.indices.contains(idx) else {
            return nil
        }
        return receiptDTO.items[idx].boundingBox
    }

    public var calculatedItemsSum: Decimal {
        receiptDTO.items.reduce(Decimal(0)) { $0 + $1.totalPrice }
    }

    private let persistenceService: any ReceiptPersistenceServiceProtocol
    private let draftStore: ReceiptDraftStore
    private let draftId: UUID

    public init(
        receiptDTO: ParsedReceiptDTO,
        receiptImage: UIImage?,
        draftId: UUID = UUID(),
        persistenceService: (any ReceiptPersistenceServiceProtocol)? = nil,
        draftStore: ReceiptDraftStore = ReceiptDraftStore.shared
    ) {
        self.receiptDTO = receiptDTO
        self.receiptImage = receiptImage
        self.draftId = draftId
        self.persistenceService = persistenceService ?? AppContainer.shared.persistenceActor
        self.draftStore = draftStore

        // İlk taslak kaydını otomatik başlat
        saveDraftSnapshot()
    }

    public func selectItem(at index: Int) {
        if activeItemIndex == index {
            activeItemIndex = nil
        } else {
            activeItemIndex = index
        }
    }

    public func deleteItem(at index: Int) {
        guard receiptDTO.items.indices.contains(index) else { return }
        receiptDTO.items.remove(at: index)
        if activeItemIndex == index {
            activeItemIndex = nil
        } else if let active = activeItemIndex, active > index {
            activeItemIndex = active - 1
        }
        saveDraftSnapshot()
    }

    public func addNewItem() {
        let newItem = ParsedItemDTO(
            rawName: "YENİ ÜRÜN",
            normalizedName: "YENİ ÜRÜN",
            quantity: Decimal(1),
            unit: .piece,
            unitPrice: Decimal(0),
            totalPrice: Decimal(0),
            taxRate: Decimal(sign: .plus, exponent: -2, significand: 1),
            confidenceScore: 1.0,
            boundingBox: NormalizedRect(originX: 0, originY: 0, width: 0, height: 0)
        )
        receiptDTO.items.append(newItem)
        activeItemIndex = receiptDTO.items.count - 1
        saveDraftSnapshot()
    }

    public func updateItemName(at index: Int, newName: String) {
        guard receiptDTO.items.indices.contains(index) else { return }
        receiptDTO.items[index].normalizedName = newName
        receiptDTO.items[index].rawName = newName
        saveDraftSnapshot()
    }

    public func updateItemPrice(at index: Int, newPrice: Decimal) {
        guard receiptDTO.items.indices.contains(index) else { return }
        receiptDTO.items[index].totalPrice = newPrice
        if receiptDTO.items[index].quantity > 0 {
            receiptDTO.items[index].unitPrice = newPrice / receiptDTO.items[index].quantity
        }
        saveDraftSnapshot()
    }

    public func updateGrandTotal(newTotal: Decimal) {
        receiptDTO.totalAmount = newTotal
        saveDraftSnapshot()
    }

    public func saveReceipt() async -> Bool {
        isPersisting = true
        errorMessage = nil

        do {
            let imageData = receiptImage?.jpegData(compressionQuality: 0.85)
            _ = try await persistenceService.persistReceipt(dto: receiptDTO, imageData: imageData)
            try? await draftStore.deleteDraft(id: draftId)
            isPersisting = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isPersisting = false
            return false
        }
    }

    public func discard() async {
        try? await draftStore.deleteDraft(id: draftId)
    }

    private func saveDraftSnapshot() {
        let dto = self.receiptDTO
        let id = self.draftId
        let store = self.draftStore
        let imgData = self.receiptImage?.jpegData(compressionQuality: 0.7)

        Task {
            try? await store.saveDraft(id: id, image: imgData, dto: dto)
        }
    }
}
