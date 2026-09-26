//
//  MarketProfileRegexTests.swift
//  Alisveris-fisTaramaTests
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Testing
import Foundation
@testable import Alisveris_fisTarama

struct MarketProfileRegexTests {

    @Test func testTurkishProductNameCleanerTaxAndPackagingExtraction() {
        // 1. Gramaj ve KDV içeren satır
        let r1 = TurkishProductNameCleaner.cleanAndExtractDetails(rawName: "N.ANKARA A.SEHR.500G %1.")
        #expect(r1.cleanName == "N.ANKARA A.SEHR")
        #expect(r1.packageQuantity == Decimal(500))
        #expect(r1.packageUnit == .gram)
        #expect(r1.detectedTaxRate == Decimal(sign: .plus, exponent: -2, significand: 1))
        #expect(r1.rawName == "N.ANKARA A.SEHR.500G %1.")

        // 2. OCR X1. paraziti (X1. -> KDV %1)
        let r2 = TurkishProductNameCleaner.cleanAndExtractDetails(rawName: "ÇENGELKÖY SALATALIK X1.")
        #expect(r2.cleanName == "ÇENGELKÖY SALATALIK")
        #expect(r2.detectedTaxRate == Decimal(sign: .plus, exponent: -2, significand: 1))

        // 3. OCR 31 . paraziti (31 . -> KDV %1)
        let r3 = TurkishProductNameCleaner.cleanAndExtractDetails(rawName: "PATATES (DÖKME) 31 .")
        #expect(r3.cleanName == "PATATES (DÖKME)")
        #expect(r3.detectedTaxRate == Decimal(sign: .plus, exponent: -2, significand: 1))

        let r4 = TurkishProductNameCleaner.cleanAndExtractDetails(rawName: "DOMATES 31 .")
        #expect(r4.cleanName == "DOMATES")
        #expect(r4.detectedTaxRate == Decimal(sign: .plus, exponent: -2, significand: 1))

        // 4. Poşet KDV %20 OCR X20 paraziti
        let r5 = TurkishProductNameCleaner.cleanAndExtractDetails(rawName: "ALIŞVERiS POSETI X20")
        #expect(r5.cleanName == "ALIŞVERİS POŞETİ")
        #expect(r5.detectedTaxRate == Decimal(sign: .plus, exponent: -1, significand: 2))

        // 5. Tartılı ürün sonundaki yalın KG birimi
        let r6 = TurkishProductNameCleaner.cleanAndExtractDetails(rawName: "HARRAS KASAP SUCUK KG")
        #expect(r6.cleanName == "HARRAS KASAP SUCUK")

        // 6. Çoklu paket (3x200ml)
        let r7 = TurkishProductNameCleaner.cleanAndExtractDetails(rawName: "3x200ml MEYVE SUYU %10")
        #expect(r7.cleanName == "MEYVE SUYU")
        #expect(r7.packageQuantity == Decimal(200))
        #expect(r7.packageUnit == .milliliter)
        #expect(r7.packCount == 3)
        #expect(r7.detectedTaxRate == Decimal(sign: .plus, exponent: -1, significand: 1))
    }

    @Test func testTurkishProductNameCleanerAbbreviations() {
        let raw = "SUT YMRTA DOM PATE KASAR PEY ZYT CUK EKM"
        let cleaned = TurkishProductNameCleaner.clean(rawName: raw)
        #expect(cleaned == "SÜT YUMURTA DOMATES PATATES KAŞAR PEYNİR ZEYTİN ÇİKOLATA EKMEK")

        let rawSpecialChars = "**%# SUT 1L - T.YAGLI //"
        let cleanedSpecial = TurkishProductNameCleaner.clean(rawName: rawSpecialChars)
        #expect(cleanedSpecial.contains("SÜT"))
        #expect(cleanedSpecial.contains("TAM YAĞLI"))
    }

    @Test func testRegexLibraryDateAndTotalMatches() {
        let sampleReceiptLine = "TARİH: 14.08.2026 SAAT: 14:25 FİŞ NO: 0142"
        let range = NSRange(sampleReceiptLine.startIndex..., in: sampleReceiptLine)

        let dateRegex = try? NSRegularExpression(pattern: ReceiptRegexLibrary.datePattern)
        let dateMatch = dateRegex?.firstMatch(in: sampleReceiptLine, range: range)
        #expect(dateMatch != nil)

        let timeRegex = try? NSRegularExpression(pattern: ReceiptRegexLibrary.timePattern)
        let timeMatch = timeRegex?.firstMatch(in: sampleReceiptLine, range: range)
        #expect(timeMatch != nil)

        let receiptNoRegex = try? NSRegularExpression(pattern: ReceiptRegexLibrary.receiptNoPattern)
        let receiptNoMatch = receiptNoRegex?.firstMatch(in: sampleReceiptLine, range: range)
        #expect(receiptNoMatch != nil)
    }

    @Test func testTurkeyRetailProfileStorePatterns() {
        let profile = TurkeyRetailProfile()
        let storeHeaders = [
            "MİGROS TİCARET A.Ş.",
            "BİM BİRLEŞİK MAĞAZALAR A.Ş.",
            "YENİ MAĞAZACILIK A.Ş. A101",
            "ŞOK MARKETLER T.A.Ş.",
            "CARREFOURSA CARREFOUR SABANCI"
        ]

        for header in storeHeaders {
            let matched = profile.storePatterns.contains { pattern in
                header.range(of: pattern.pattern, options: .regularExpression) != nil
            }
            #expect(matched == true)
        }
    }
}
