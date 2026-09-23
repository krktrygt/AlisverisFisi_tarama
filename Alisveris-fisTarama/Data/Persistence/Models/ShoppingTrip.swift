//
//  ShoppingTrip.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Foundation
import SwiftData

@Model
public final class ShoppingTrip {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var receiptNumber: String?
    public var totalAmount: Decimal
    public var subtotal: Decimal
    public var discountTotal: Decimal
    public var taxTotal: Decimal
    public var paymentMethodRaw: String
    public var currencyCode: String
    public var countryCode: String
    public var taxSystemRaw: String
    public var imageRelativePath: String?
    public var confidenceScore: Double
    public var createdAt: Date
    public var updatedAt: Date

    public var store: Store?

    @Relationship(deleteRule: .cascade, inverse: \ShoppingItem.trip)
    public var items: [ShoppingItem] = []

    public var paymentMethod: PaymentMethod {
        get { PaymentMethod(rawValue: paymentMethodRaw) ?? .other }
        set { paymentMethodRaw = newValue.rawValue }
    }

    public var taxSystem: TaxSystem {
        get { TaxSystem(rawValue: taxSystemRaw) ?? .inclusiveVAT }
        set { taxSystemRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        date: Date,
        receiptNumber: String? = nil,
        totalAmount: Decimal,
        subtotal: Decimal,
        discountTotal: Decimal = Decimal(0),
        taxTotal: Decimal,
        paymentMethod: PaymentMethod,
        currencyCode: String = "TRY",
        countryCode: String = "TR",
        taxSystem: TaxSystem = .inclusiveVAT,
        imageRelativePath: String? = nil,
        store: Store? = nil,
        confidenceScore: Double = 1.0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.receiptNumber = receiptNumber
        self.totalAmount = totalAmount
        self.subtotal = subtotal
        self.discountTotal = discountTotal
        self.taxTotal = taxTotal
        self.paymentMethodRaw = paymentMethod.rawValue
        self.currencyCode = currencyCode
        self.countryCode = countryCode
        self.taxSystemRaw = taxSystem.rawValue
        self.imageRelativePath = imageRelativePath
        self.store = store
        self.confidenceScore = confidenceScore
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
