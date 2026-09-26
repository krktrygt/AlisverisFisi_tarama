//
//  TurkishProductNameCleaner.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Foundation

/// Temizlenmiş ve yapılandırılmış ürün adı sonucu
public struct CleanedProductResult: Sendable, Equatable {
    public let cleanName: String
    public let rawName: String
    public let packageQuantity: Decimal?
    public let packageUnit: UnitType?
    public let packCount: Int?
    public let detectedTaxRate: Decimal?

    public init(
        cleanName: String,
        rawName: String,
        packageQuantity: Decimal? = nil,
        packageUnit: UnitType? = nil,
        packCount: Int? = nil,
        detectedTaxRate: Decimal? = nil
    ) {
        self.cleanName = cleanName
        self.rawName = rawName
        self.packageQuantity = packageQuantity
        self.packageUnit = packageUnit
        self.packCount = packCount
        self.detectedTaxRate = detectedTaxRate
    }
}

/// Fiş üzerindeki ürün metinlerini vergi, gramaj, birim ve OCR parazitlerinden arındırarak
/// temiz ürün ismine dönüştüren ve yapısal verileri koruyan standart temizleme motoru.
public final class TurkishProductNameCleaner: Sendable {
    private static let abbreviationDictionary: [String: String] = [
        "SUT": "SÜT", "PIRINC": "PİRİNÇ", "YMRTA": "YUMURTA", "YMRT": "YUMURTA",
        "DOM": "DOMATES", "PATE": "PATATES", "KASAR": "KAŞAR", "PEY": "PEYNİR",
        "PEYN": "PEYNİR", "ZYT": "ZEYTİN", "CUK": "ÇİKOLATA", "GOFR": "GOFRET",
        "EKM": "EKMEK", "MAKAR": "MAKARNA", "MBN": "MERCİMEK", "CVD": "ÇAVDAR",
        "T.YAGLI": "TAM YAĞLI", "Y.YAGLI": "YARIM YAĞLI", "YAG": "YAĞ",
        "AYC": "AYÇİÇEK", "Z.YAGI": "ZEYTİNYAĞI", "PILAV": "PİLAVLIK",
        "GOGUS": "GÖĞÜS", "KIY": "KIYMA", "POSETI": "POŞETİ", "POSET": "POŞET"
    ]

    // 1. KDV kalıpları (Satır sonunda veya KDV sütunundaki etiketler: %1., X1., 31 ., X20, ·20, *01, !1 vb.)
    private static let vatSuffixRegex = try! NSRegularExpression(
        pattern: #"(?i)\s*(?:[%*·•#Xx3!Iİl]\s*(0?[18]|10|18|20)|\b(0?[18]|10|18|20))\s*[\.]?\s*$"#
    )

    // 2. Sonda kalan tekil OCR parazitleri (örn. arta kalan X, x, 3, *, #, ., -)
    private static let trailingNoiseRegex = try! NSRegularExpression(
        pattern: #"(?i)\s*[\*#%\-_\.,/\\Xx3!·•]+\s*$"#
    )

    // 3. Başta kalan sıra no / madde imi parazitleri (*, -, #, 01., 1.)
    private static let leadingNoiseRegex = try! NSRegularExpression(
        pattern: #"(?i)^\s*(?:[\*#%\-_·•]\s*|\d{1,2}[\.\)]\s*)+"#
    )

    // 4. Tartı/Dökme satır sonu birim artıkları (HARRAS SUCUK KG -> HARRAS SUCUK)
    private static let trailingUnitRegex = try! NSRegularExpression(
        pattern: #"(?i)\s+(?:KG|KİLO|KILO|GR|GRAM|ADET|AD|PK|PAKET)\s*$"#
    )

    /// Ham ürün satırını temizler, varsa vergi oranı ve gramaj/ambalaj bilgilerini çıkararak
    /// hiçbir veriyi kaybetmeden hem temiz ismi hem de yapılandırılmış özellikleri döner.
    public static func cleanAndExtractDetails(rawName: String) -> CleanedProductResult {
        var text = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return CleanedProductResult(cleanName: "", rawName: rawName)
        }

        // A. Başlangıçtaki sıra no ve sembol gürültülerini temizle
        let leadingRange = NSRange(text.startIndex..., in: text)
        text = leadingNoiseRegex.stringByReplacingMatches(in: text, options: [], range: leadingRange, withTemplate: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // B. Sondaki KDV etiketini ve oranını tespit et
        var detectedTax: Decimal? = nil
        let vatRange = NSRange(text.startIndex..., in: text)
        if let match = vatSuffixRegex.firstMatch(in: text, options: [], range: vatRange) {
            let nsText = text as NSString
            var matchedDigits: String? = nil
            if match.range(at: 1).location != NSNotFound {
                matchedDigits = nsText.substring(with: match.range(at: 1))
            } else if match.range(at: 2).location != NSNotFound {
                matchedDigits = nsText.substring(with: match.range(at: 2))
            }

            if let digits = matchedDigits {
                switch digits {
                case "1", "01": detectedTax = Decimal(sign: .plus, exponent: -2, significand: 1) // 0.01
                case "8", "08": detectedTax = Decimal(sign: .plus, exponent: -2, significand: 8) // 0.08
                case "10": detectedTax = Decimal(sign: .plus, exponent: -1, significand: 1) // 0.10
                case "18": detectedTax = Decimal(sign: .plus, exponent: -2, significand: 18) // 0.18
                case "20": detectedTax = Decimal(sign: .plus, exponent: -1, significand: 2) // 0.20
                default: break
                }
            }

            text = nsText.replacingCharacters(in: match.range, with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // C. KDV sonrası sonda tek başına kalan OCR parazitlerini temizle (X, 3, *, .)
        let trailRange = NSRange(text.startIndex..., in: text)
        text = trailingNoiseRegex.stringByReplacingMatches(in: text, options: [], range: trailRange, withTemplate: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // D. Gramaj / Ambalaj bilgisini çıkar ve isimden ayır
        var packageQty: Decimal? = nil
        var packageUnit: UnitType? = nil
        var packCount: Int? = nil

        if let pkg = ProductPackagingParser.extract(from: text) {
            packageQty = pkg.rawQuantity
            packageUnit = pkg.unit
            packCount = pkg.packCount
            text = pkg.remainingText
        } else {
            // Rakam içermeyen satır sonu birimlerini temizle (örn. "SUCUK KG")
            let unitRange = NSRange(text.startIndex..., in: text)
            text = trailingUnitRegex.stringByReplacingMatches(in: text, options: [], range: unitRange, withTemplate: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // E. Noktalama ve boşluk standardizasyonu
        let punctuationSet = CharacterSet(charactersIn: "*%#-._/\\ \t")
        text = text.trimmingCharacters(in: punctuationSet)
        text = text.replacingOccurrences(of: "()", with: "")
            .replacingOccurrences(of: "( )", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        while text.contains("  ") {
            text = text.replacingOccurrences(of: "  ", with: " ")
        }

        // F. Kısaltmaları genişlet
        let tokens = text.split(separator: " ")
        let enriched = tokens.map { token -> String in
            let upper = String(token).uppercased(with: Locale(identifier: "tr-TR"))
            return abbreviationDictionary[upper] ?? upper
        }
        let cleanName = enriched.joined(separator: " ").trimmingCharacters(in: punctuationSet)

        return CleanedProductResult(
            cleanName: cleanName.isEmpty ? rawName : cleanName,
            rawName: rawName,
            packageQuantity: packageQty,
            packageUnit: packageUnit,
            packCount: packCount,
            detectedTaxRate: detectedTax
        )
    }

    /// Basit temizleme metodu (Geriye dönük uyumluluk)
    public static func clean(rawName: String) -> String {
        return cleanAndExtractDetails(rawName: rawName).cleanName
    }
}
