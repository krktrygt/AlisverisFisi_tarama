//
//  PriceRecordDTO.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Foundation

/// Fiyat takip transfer DTO'su
public struct PriceRecordDTO: Sendable, Identifiable, Codable {
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
