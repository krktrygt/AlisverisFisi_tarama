//
//  ParsedItemDTO.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Foundation

/// Ayrıştırılmış ürün kalemi DTO'su
public struct ParsedItemDTO: Sendable, Identifiable, Codable {
    public let id: UUID
    public var rawName: String
    public var normalizedName: String
    public var quantity: Decimal
    public var unit: UnitType
    public var unitPrice: Decimal
    public var totalPrice: Decimal
    public var taxRate: Decimal
    public var categoryId: UUID?
    public var confidenceScore: Double
    public var boundingBox: NormalizedRect

    // Yapılandırılmış Ambalaj ve Gramaj Özellikleri (Veri Koruma Standardı)
    public var packageQuantity: Decimal?
    public var packageUnit: UnitType?
    public var packCount: Int?

    public init(
        id: UUID = UUID(),
        rawName: String,
        normalizedName: String,
        quantity: Decimal = 1.0,
        unit: UnitType = .piece,
        unitPrice: Decimal,
        totalPrice: Decimal,
        taxRate: Decimal = 0.01,
        categoryId: UUID? = nil,
        confidenceScore: Double = 1.0,
        boundingBox: NormalizedRect = NormalizedRect(originX: 0, originY: 0, width: 0, height: 0),
        packageQuantity: Decimal? = nil,
        packageUnit: UnitType? = nil,
        packCount: Int? = nil
    ) {
        self.id = id
        self.rawName = rawName
        self.normalizedName = normalizedName
        self.quantity = quantity
        self.unit = unit
        self.unitPrice = unitPrice
        self.totalPrice = totalPrice
        self.taxRate = taxRate
        self.categoryId = categoryId
        self.confidenceScore = confidenceScore
        self.boundingBox = boundingBox
        self.packageQuantity = packageQuantity
        self.packageUnit = packageUnit
        self.packCount = packCount
    }
}
