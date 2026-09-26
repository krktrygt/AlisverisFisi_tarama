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

    public struct PackagingResult: Sendable, Equatable {
        public let remainingText: String
        public let rawQuantity: Decimal
        public let unit: UnitType
        public let packCount: Int

        public init(remainingText: String, rawQuantity: Decimal, unit: UnitType, packCount: Int) {
            self.remainingText = remainingText
            self.rawQuantity = rawQuantity
            self.unit = unit
            self.packCount = packCount
        }
    }

    /// Ham metinden ambalaj bilgisini çıkarır ve geriye kalan temiz metni ile yapılandırılmış gramajı döner
    public static func extract(from text: String) -> PackagingResult? {
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
        case "adet", "ad", "li", "lu", "lü", "lı":
            unit = .piece
            if packCount == 1 && (unitRaw == "li" || unitRaw == "lu" || unitRaw == "lü" || unitRaw == "lı") {
                packCount = NSDecimalNumber(decimal: rawQty).intValue
            }
        default:
            unit = .piece
        }

        let nsText = text as NSString
        let remaining = nsText.replacingCharacters(in: match.range, with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return PackagingResult(
            remainingText: remaining,
            rawQuantity: finalQty,
            unit: unit,
            packCount: packCount
        )
    }

    /// Geriye dönük uyumluluk: Sadece ambalaj sayı ve birimini döner
    public static func parse(from text: String) -> (rawQuantity: Decimal, unit: UnitType, packCount: Int)? {
        guard let res = extract(from: text) else { return nil }
        return (res.rawQuantity, res.unit, res.packCount)
    }
}
