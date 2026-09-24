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
