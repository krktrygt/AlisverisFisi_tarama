//
//  ParsedReceiptDTO.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Foundation

/// Ayrıştırılmış fiş seansı DTO'su
public struct ParsedReceiptDTO: Sendable, Identifiable, Codable {
    public let id: UUID
    public var storeName: String
    public var storeBranch: String?
    public var storeAddress: String?
    public var storeTaxNumber: String?
    public var date: Date
    public var receiptNumber: String?
    public var subtotal: Decimal
    public var discountTotal: Decimal
    public var totalAmount: Decimal
    public var taxTotal: Decimal
    public var paymentMethod: PaymentMethod
    public var items: [ParsedItemDTO]
    public var rawOcrText: String
    public var confidenceScore: Double
    public var imageRelativePath: String?
    public var auditLog: [String]

    public init(
        id: UUID = UUID(),
        storeName: String,
        storeBranch: String? = nil,
        storeAddress: String? = nil,
        storeTaxNumber: String? = nil,
        date: Date = Date(),
        receiptNumber: String? = nil,
        subtotal: Decimal = Decimal(0),
        discountTotal: Decimal = Decimal(0),
        totalAmount: Decimal,
        taxTotal: Decimal = Decimal(0),
        paymentMethod: PaymentMethod = .creditCard,
        items: [ParsedItemDTO],
        rawOcrText: String = "",
        confidenceScore: Double = 1.0,
        imageRelativePath: String? = nil,
        auditLog: [String] = []
    ) {
        self.id = id
        self.storeName = storeName
        self.storeBranch = storeBranch
        self.storeAddress = storeAddress
        self.storeTaxNumber = storeTaxNumber
        self.date = date
        self.receiptNumber = receiptNumber
        self.subtotal = subtotal
        self.discountTotal = discountTotal
        self.totalAmount = totalAmount
        self.taxTotal = taxTotal
        self.paymentMethod = paymentMethod
        self.items = items
        self.rawOcrText = rawOcrText
        self.confidenceScore = confidenceScore
        self.imageRelativePath = imageRelativePath
        self.auditLog = auditLog
    }
}
