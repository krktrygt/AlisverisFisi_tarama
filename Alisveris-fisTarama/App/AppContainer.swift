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
    public let modelContainer: ModelContainer
    public let persistenceActor: ReceiptPersistenceActor
    public let imageDiskManager: any ReceiptImageDiskManagerProtocol

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
