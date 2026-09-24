//
//  TurkeyRetailProfile.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Foundation

public struct TurkeyRetailProfile: RetailMarketProfile {
    public let countryCode: String = "TR"
    public let defaultCurrencyCode: String = "TRY"
    public let defaultLocale: Locale = Locale(identifier: "tr_TR")
    public let taxSystem: TaxSystem = .inclusiveVAT
    public let ocrLanguages: [String] = ["tr-TR", "en-US"]
    public let customRetailVocabulary: [String] = ReceiptOCRService.customRetailVocabulary

    public let storePatterns: [(name: String, pattern: String, vkn: String?)] = [
        ("Migros", #"(?i)\b(?:M[İI]GROS|M-JET|MACROCENTER)\b"#, "6220084500"),
        ("BİM", #"(?i)(?:\bB[İI]M\b(?!AR|\.)|B[İI]M\s*B[İI]RLEŞ[İI]K)"#, "1750051846"),
        ("A101", #"(?i)(?:\bA\s*[-.]?\s*101\b|YEN[İI]\s*MAĞAZACILIK)"#, "9480436853"),
        ("Şok", #"(?i)(?:\bŞOK\b|\bSOK\b(?!\.|\s*CAD|\s*SOK|AK)|ŞOK\s*MARKETLER)"#, "8150033488"),
        ("CarrefourSA", #"(?i)\bCARREFOUR(?:SA)?\b"#, "2030018507"),
        ("FİLE", #"(?i)(?:\bF[İI]LE\b|F[İI]LE\s*MARKET)"#, "3871427056")
    ]

    public let grandTotalPattern: String = ReceiptRegexLibrary.grandTotalPattern
    public let subtotalPattern: String = ReceiptRegexLibrary.subtotalPattern
    public let taxPattern: String = ReceiptRegexLibrary.totalVatPattern
    public let discountPattern: String = ReceiptRegexLibrary.discountKeywordPattern
    public let paymentMethodPattern: String = ReceiptRegexLibrary.paymentMethodPattern
    public let receiptNumberPattern: String = ReceiptRegexLibrary.receiptNoPattern

    public init() {}

    public func cleanProductName(rawName: String) -> String {
        TurkishProductNameCleaner.clean(rawName: rawName)
    }

    public func parsePrice(from text: String) -> Decimal? {
        CurrencyNormalizer.parseDecimal(from: text)
    }
}
