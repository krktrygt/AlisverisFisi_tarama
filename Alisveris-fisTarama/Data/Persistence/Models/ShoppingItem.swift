//
//  ShoppingItem.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Foundation
import SwiftData

@Model
public final class ShoppingItem {
    @Attribute(.unique) public var id: UUID
    public var rawName: String
    public var normalizedName: String
    public var quantity: Decimal
    public var unitRaw: String
    public var unitPrice: Decimal
    public var totalPrice: Decimal
    public var currencyCode: String
    public var taxRate: Decimal
    public var confidenceScore: Double

    public var category: Category?
    public var trip: ShoppingTrip?

    public var unit: UnitType {
        get { UnitType(rawValue: unitRaw) ?? .piece }
        set { unitRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        rawName: String,
        normalizedName: String,
        quantity: Decimal,
        unit: UnitType,
        unitPrice: Decimal,
        totalPrice: Decimal,
        currencyCode: String = "TRY",
        taxRate: Decimal,
        category: Category? = nil,
        trip: ShoppingTrip? = nil,
        confidenceScore: Double = 1.0
    ) {
        self.id = id
        self.rawName = rawName
        self.normalizedName = normalizedName
        self.quantity = quantity
        self.unitRaw = unit.rawValue
        self.unitPrice = unitPrice
        self.totalPrice = totalPrice
        self.currencyCode = currencyCode
        self.taxRate = taxRate
        self.category = category
        self.trip = trip
        self.confidenceScore = confidenceScore
    }
}
