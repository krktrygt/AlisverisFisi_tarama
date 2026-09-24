//
//  RetailMarketProfile.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Foundation

public protocol RetailMarketProfile: Sendable {
    var countryCode: String { get }              // "TR", "US", "DE" vb.
    var defaultCurrencyCode: String { get }       // "TRY", "USD", "EUR" vb.
    var defaultLocale: Locale { get }
    var taxSystem: TaxSystem { get }              // .inclusiveVAT veya .exclusiveSalesTax
    var ocrLanguages: [String] { get }            // ["tr-TR", "en-US"]
    var customRetailVocabulary: [String] { get }
    var storePatterns: [(name: String, pattern: String, vkn: String?)] { get }
    var grandTotalPattern: String { get }
    var subtotalPattern: String { get }
    var taxPattern: String { get }
    var discountPattern: String { get }
    var paymentMethodPattern: String { get }
    var receiptNumberPattern: String { get }
    func cleanProductName(rawName: String) -> String
    func parsePrice(from text: String) -> Decimal?
}
