//
//  AppContainer.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Foundation
import Combine
import SwiftData
import SwiftUI

@MainActor
public final class AppContainer: ObservableObject {
    public static let shared = AppContainer()

    public let modelContainer: ModelContainer
    public let persistenceActor: ReceiptPersistenceActor
    public let imageDiskManager: any ReceiptImageDiskManagerProtocol
    public let receiptMLService: ReceiptMLInferenceService

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
            self.receiptMLService = ReceiptMLInferenceService.shared

            Self.seedStandardCategories(in: container)
        } catch {
            fatalError("SwiftData ModelContainer başlatılamadı: \(error.localizedDescription)")
        }
    }

    public static func seedStandardCategories(in container: ModelContainer) {
        let context = container.mainContext
        let fetchDescriptor = FetchDescriptor<Category>()
        guard let existing = try? context.fetch(fetchDescriptor) else { return }
        let existingCodes = Set(existing.compactMap { $0.rawCode })

        var didInsert = false
        for standard in StandardCategory.allCases {
            if !existingCodes.contains(standard.rawCode) {
                let cat = Category(standard: standard)
                context.insert(cat)
                didInsert = true
            }
        }

        if didInsert {
            try? context.save()
        }
    }
}
