//
//  PriceRecord.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Foundation
import SwiftData

@Model
public final class PriceRecord {
    // iOS 18+ SwiftData Bileşik İndeks Tanımı
    #Index<PriceRecord>([\.productNameNormalized, \.date], [\.storeId])

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
