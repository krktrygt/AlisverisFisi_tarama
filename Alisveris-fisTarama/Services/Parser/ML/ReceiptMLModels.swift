//
//  ReceiptMLModels.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Foundation

public enum ReceiptLineRole: String, Sendable, CaseIterable {
    case productLine = "PRODUCT_LINE"
    case weightQtyPrice = "WEIGHT_QTY_PRICE"
    case totalLine = "TOTAL_LINE"
    case subtotalLine = "SUBTOTAL_LINE"
    case taxSummaryLine = "TAX_SUMMARY_LINE"
    case storeHeader = "STORE_HEADER"
    case paymentLine = "PAYMENT_LINE"
    case metadataLine = "METADATA_LINE"
    case discountLine = "DISCOUNT_LINE"
    case campaignInfo = "CAMPAIGN_INFO"
    case noise = "NOISE"
    case unknown

    public static func from(rawLabel: String) -> ReceiptLineRole {
        switch rawLabel {
        case "PRODUCT_LINE", "ITEM_FULL", "ITEM_NAME_ONLY":
            return .productLine
        case "WEIGHT_QTY_PRICE":
            return .weightQtyPrice
        case "GRAND_TOTAL_LINE", "TOTAL_LINE":
            return .totalLine
        case "SUBTOTAL_LINE":
            return .subtotalLine
        case "TAX_SUMMARY_LINE":
            return .taxSummaryLine
        case "STORE_HEADER":
            return .storeHeader
        case "METADATA_LINE", "HEADER_METADATA":
            return .metadataLine
        case "PAYMENT_LINE":
            return .paymentLine
        case "DISCOUNT_LINE":
            return .discountLine
        case "CAMPAIGN_INFO":
            return .campaignInfo
        case "NOISE", "FOOTER_NOISE":
            return .noise
        default:
            return ReceiptLineRole(rawValue: rawLabel) ?? .unknown
        }
    }
}

public struct TaggedTokenResult: Sendable, Equatable {
    public let token: String
    public let label: String
    public let location: Int
    public let length: Int

    public init(token: String, label: String, location: Int, length: Int) {
        self.token = token
        self.label = label
        self.location = location
        self.length = length
    }
}

public struct ClassifiedReceiptLine: Sendable {
    public let line: SegmentedReceiptLine
    public let role: ReceiptLineRole
    public let rawLabel: String
    public let confidence: Double

    public init(line: SegmentedReceiptLine, role: ReceiptLineRole, rawLabel: String = "", confidence: Double) {
        self.line = line
        self.role = role
        self.rawLabel = rawLabel.isEmpty ? role.rawValue : rawLabel
        self.confidence = confidence
    }
}
