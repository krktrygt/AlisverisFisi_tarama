//
//  CurrencyNormalizer.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Foundation

public enum NumberFormatterCache: Sendable {
    public static let trLocale = Locale(identifier: "tr_TR")

    public static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = trLocale
        formatter.currencySymbol = "₺"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.roundingMode = .halfEven
        return formatter
    }()

    public static let unitPriceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = trLocale
        formatter.currencySymbol = "₺"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 4
        formatter.roundingMode = .halfEven
        return formatter
    }()
}

public extension Decimal {
    /// Standart Türk Lirası para gösterimi (Örn: ₺1.250,50)
    func formattedAsCurrency() -> String {
        NumberFormatterCache.currencyFormatter.string(from: self as NSDecimalNumber) ?? "\(self) ₺"
    }

    /// Birim fiyatlar için 4 basamaklı hassas gösterim (Örn: ₺34,5025 / L)
    func formattedAsDetailedUnitPrice() -> String {
        NumberFormatterCache.unitPriceFormatter.string(from: self as NSDecimalNumber) ?? "\(self) ₺"
    }
}

public enum TurkishCurrencyNormalizer: Sendable {
    public static func parseDecimal(from rawText: String) -> Decimal? {
        var cleaned = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "TL", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "₺", with: "")
            .replacingOccurrences(of: "*", with: "")
            .trimmingCharacters(in: .whitespaces)

        var isNegative = false
        if cleaned.hasPrefix("-") {
            isNegative = true
            cleaned.removeFirst()
        }

        // Nokta vuruşlu yazıcı hataları ikamesi (B->8, O->0, aksanlar virgül)
        cleaned = cleaned.replacingOccurrences(of: "O", with: "0")
            .replacingOccurrences(of: "o", with: "0")
            .replacingOccurrences(of: "B", with: "8")
            .replacingOccurrences(of: "'", with: ",")
            .replacingOccurrences(of: "`", with: ",")

        // Türk Lirası noktalama standardizasyonu
        if cleaned.contains(",") && cleaned.contains(".") {
            cleaned = cleaned.replacingOccurrences(of: ".", with: "")
            cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
        } else if cleaned.contains(",") {
            cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
        } else if cleaned.contains(".") {
            if let lastDotIndex = cleaned.lastIndex(of: ".") {
                let integerPart = cleaned[..<lastDotIndex].replacingOccurrences(of: ".", with: "")
                let fractionPart = cleaned[cleaned.index(after: lastDotIndex)...]
                if fractionPart.count <= 2 {
                    cleaned = "\(integerPart).\(fractionPart)"
                } else {
                    cleaned = "\(integerPart)\(fractionPart)"
                }
            }
        }

        guard let decVal = Decimal(string: cleaned, locale: Locale(identifier: "en_US")) else {
            return nil
        }
        return isNegative ? -decVal : decVal
    }
}

public typealias CurrencyNormalizer = TurkishCurrencyNormalizer
