//
//  TurkishProductNameCleaner.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Foundation

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

    private static let vatSuffixPattern = #"(?i)\s*[%*]?\s*(?:0?1|0?8|10|18|20)\.?\s*$"#

    public static func clean(rawName: String) -> String {
        var cleaned = rawName.trimmingCharacters(in: .whitespacesAndNewlines)

        // Sondaki KDV etiketini temizle (%1., %10, %20, *01, vb.)
        if let regex = try? NSRegularExpression(pattern: vatSuffixPattern) {
            cleaned = regex.stringByReplacingMatches(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned), withTemplate: "")
        }

        let characterSet = CharacterSet(charactersIn: "*%#-._/\\ ")
        cleaned = cleaned.trimmingCharacters(in: characterSet)
        while cleaned.contains("  ") {
            cleaned = cleaned.replacingOccurrences(of: "  ", with: " ")
        }
        let tokens = cleaned.split(separator: " ")
        let enriched = tokens.map { token -> String in
            let upper = String(token).uppercased(with: Locale(identifier: "tr-TR"))
            return abbreviationDictionary[upper] ?? upper
        }
        return enriched.joined(separator: " ")
    }
}
