//
//  ReceiptPersistenceServiceProtocol.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Foundation
import SwiftData

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
