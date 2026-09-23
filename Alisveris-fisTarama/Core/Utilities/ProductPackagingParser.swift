//
//  ProductPackagingParser.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Foundation

/// Ürün metinlerinden gramaj, hacim ve paket adetlerini ayrıştırır (Örn: "3x200ml", "1.5 kg", "500 gr")
public struct ProductPackagingParser: Sendable {
    private static let packagingRegex = try! NSRegularExpression(
        pattern: #"(?i)(?:(?<packCount>\d+)\s*[*xX]\s*)?(?<quantity>\d+(?:[.,]\d+)?)\s*['’]?\s*(?<unit>kg|kilo|gr|g|gram|lt|l|litre|ml|cl|adet|ad|pk|paket|li|lu|lü|lı)\b"#
    )

    public static func parse(from text: String) -> (rawQuantity: Decimal, unit: UnitType, packCount: Int)? {
        let range = NSRange(text.startIndex..., in: text)
        guard let match = packagingRegex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }

        var packCount = 1
        if let packRange = Range(match.range(withName: "packCount"), in: text) {
            packCount = Int(text[packRange]) ?? 1
        }

        guard let qtyRange = Range(match.range(withName: "quantity"), in: text),
              let unitRange = Range(match.range(withName: "unit"), in: text) else {
            return nil
        }

        let qtyString = String(text[qtyRange]).replacingOccurrences(of: ",", with: ".")
        guard let rawQty = Decimal(string: qtyString, locale: Locale(identifier: "en_US")), rawQty > 0 else {
            return nil
        }

        let unitRaw = String(text[unitRange]).lowercased()
        var finalQty = rawQty
        let unit: UnitType
        switch unitRaw {
        case "kg", "kilo": unit = .kilogram
        case "gr", "g", "gram": unit = .gram
        case "lt", "l", "litre": unit = .liter
        case "ml": unit = .milliliter
        case "cl":
            // 1 cl = 10 ml = 0.01 L; baz hacim birimi mililitreye çevrilir (0.01 L çarpanı)
            finalQty = rawQty * Decimal(10)
            unit = .milliliter
        case "pk", "paket": unit = .pack
        default: unit = .piece
        }

        return (finalQty, unit, packCount)
    }
}
