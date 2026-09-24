//
//  ReceiptParserEngineBenchmarkTests.swift
//  Alisveris-fisTaramaTests
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Testing
import Foundation
import CoreGraphics
@testable import Alisveris_fisTarama

struct ReceiptParserEngineBenchmarkTests {

    private func makeWord(text: String, x: CGFloat, y: CGFloat, width: CGFloat = 50, height: CGFloat = 16) -> OCRWordBox {
        OCRWordBox(
            text: text,
            confidence: 0.95,
            boundingBox: CGRect(x: x, y: y, width: width, height: height)
        )
    }

    @Test func testParseSimpleReceiptSuccess() {
        let engine = TurkishReceiptParserEngine()
        let imageSize = CGSize(width: 400, height: 800)

        // Simüle edilmiş fiş satırları
        let line1 = SegmentedReceiptLine(words: [
            makeWord(text: "MİGROS", x: 150, y: 30)
        ])
        let line2 = SegmentedReceiptLine(words: [
            makeWord(text: "TARİH:", x: 30, y: 70),
            makeWord(text: "14.08.2026", x: 90, y: 70),
            makeWord(text: "SAAT:", x: 180, y: 70),
            makeWord(text: "15:30", x: 230, y: 70)
        ])
        let line3 = SegmentedReceiptLine(words: [
            makeWord(text: "FİŞ", x: 30, y: 100),
            makeWord(text: "NO:", x: 60, y: 100),
            makeWord(text: "0123", x: 90, y: 100)
        ])
        let line4 = SegmentedReceiptLine(words: [
            makeWord(text: "SUT", x: 30, y: 150),
            makeWord(text: "1L", x: 80, y: 150),
            makeWord(text: "*01", x: 280, y: 150),
            makeWord(text: "35,50", x: 320, y: 150)
        ])
        let line5 = SegmentedReceiptLine(words: [
            makeWord(text: "EKM", x: 30, y: 180),
            makeWord(text: "*01", x: 280, y: 180),
            makeWord(text: "10,00", x: 320, y: 180)
        ])
        let line6 = SegmentedReceiptLine(words: [
            makeWord(text: "TOPLAM", x: 30, y: 240),
            makeWord(text: "45,50", x: 320, y: 240)
        ])
        let line7 = SegmentedReceiptLine(words: [
            makeWord(text: "KREDİ", x: 30, y: 270),
            makeWord(text: "KARTI", x: 90, y: 270)
        ])

        let parsed = engine.parse(
            segmentedLines: [line1, line2, line3, line4, line5, line6, line7],
            imageSize: imageSize
        )

        #expect(parsed.storeName == "Migros")
        #expect(parsed.receiptNumber == "0123")
        #expect(parsed.items.count == 2)
        #expect(parsed.items[0].normalizedName.contains("SÜT"))
        #expect(parsed.items[0].totalPrice == Decimal(string: "35.50"))
        #expect(parsed.items[1].normalizedName.contains("EKMEK"))
        #expect(parsed.items[1].totalPrice == Decimal(string: "10.00"))
        #expect(parsed.totalAmount == Decimal(string: "45.50"))
        #expect(parsed.paymentMethod == .creditCard)
        // Aritmetik tam tuttuğu ve store/date/receiptNo/total eşleştiği için güven skoru yüksek olmalı
        #expect(parsed.confidenceScore >= 0.85)
    }

    @Test func testParseWeightedItemSubline() {
        let engine = TurkishReceiptParserEngine()
        let imageSize = CGSize(width: 400, height: 800)

        let line1 = SegmentedReceiptLine(words: [
            makeWord(text: "DOM", x: 30, y: 100),
            makeWord(text: "46,31", x: 320, y: 100)
        ])
        let line2 = SegmentedReceiptLine(words: [
            makeWord(text: "2,450", x: 30, y: 120),
            makeWord(text: "KG", x: 90, y: 120),
            makeWord(text: "x", x: 120, y: 120),
            makeWord(text: "18,90", x: 140, y: 120),
            makeWord(text: "TL", x: 190, y: 120)
        ])
        let line3 = SegmentedReceiptLine(words: [
            makeWord(text: "TOPLAM", x: 30, y: 180),
            makeWord(text: "46,31", x: 320, y: 180)
        ])

        let parsed = engine.parse(
            segmentedLines: [line1, line2, line3],
            imageSize: imageSize
        )

        #expect(parsed.items.count == 1)
        let item = parsed.items[0]
        #expect(item.normalizedName == "DOMATES")
        #expect(item.quantity == Decimal(string: "2.45"))
        #expect(item.unit == .kilogram)
        #expect(item.unitPrice == Decimal(string: "18.90"))
        #expect(item.totalPrice == Decimal(string: "46.31"))
    }

    @Test func testParseRealLifeFileReceipt() {
        let engine = TurkishReceiptParserEngine()
        let imageSize = CGSize(width: 1000, height: 4000)

        // Kullanıcının taranan 357 TL'lik FİLE market fişi
        let rawLines: [(String, CGFloat)] = [
            ("GErAsi tiS'i'.", 643),
            ("E-fralv Fatura", 848),
            ("FILE TiMUCiN CADDESI / TALAS / KAYS", 958),
            ("FİLE MARKET MAĞAZACILIK ANONİM ŞİRKETI", 1012),
            ("MEVLANA MAH. MEHMET TIMUÇIN CAD. NO:4/A", 1086),
            ("TALAS / KAYSERI", 1168),
            ("Sarıgazi VDM 3871427056", 1237),
            ("FATURA NO: Y092026007744519", 1359),
            ("23.09.2026 16:57 Sira No : 408", 1421),
            ("ETTN5a401dfd-5cf5-45da-a7ba-884f94cae761", 1491),
            ("22040012309608000408", 1666),
            ("TCKN/VKN:11111111111-NIHAI TÜKETICI", 1728),
            ("PEPSI MAX 1,5L %10 *67.00", 1868),
            ("ALIŞVERİŞ POSETI %20 *1.00", 1929),
            ("LEZITA CITIR KIT 700 %1. *289.00", 1987),
            ("TOPLAM KDV *9.12", 2123),
            ("Odenecek KDV Dahil Tutar *357.00", 2191),
            ("Ippos Kredi Kartı (1) *357.00", 2319),
            ("IS BANKASI", 2447),
            ("I:695297101 T:S1A65A01 658768******1168", 2511),
            ("23.09.2026 16:57 B:1054 S:126", 2571),
            ("Onay No:229748 Ref .No:626635020991", 2635),
            ("KDV MATRAH KDV TUTAR KDV DAHIL", 2761),
            ("21 - 286.14 *2.86 *289.00", 2822),
            ("%10 60.91 *6.09 *67.00", 2886),
            ("·20 0.83 *0.17 *1.00", 2955),
            ("POS:1 - 463441 - K**** D**** 940122041", 3779),
            ("2204, TiMUÇiN CADDESi / TALAS GS No: 800", 3828)
        ]

        let segmentedLines: [SegmentedReceiptLine] = rawLines.map { text, y in
            let words = text.components(separatedBy: " ").enumerated().map { idx, w in
                OCRWordBox(
                    text: w,
                    confidence: 0.98,
                    boundingBox: CGRect(x: CGFloat(50 + idx * 80), y: y, width: 70, height: 24)
                )
            }
            return SegmentedReceiptLine(words: words)
        }

        let parsed = engine.parse(segmentedLines: segmentedLines, imageSize: imageSize)

        // Mağaza: FİLE
        #expect(parsed.storeName == "FİLE")
        // Toplam Tutar: 357 TL (3343 TL DEĞİL!)
        #expect(parsed.totalAmount == Decimal(357))
        // Kalem Sayısı: Sadece 3 gerçek ürün (Pepsi, Poşet, Lezita Çıtır Kit)
        #expect(parsed.items.count == 3)

        #expect(parsed.items[0].normalizedName.contains("PEPSI"))
        #expect(parsed.items[0].totalPrice == Decimal(67))

        #expect(parsed.items[1].normalizedName.contains("POŞET"))
        #expect(parsed.items[1].totalPrice == Decimal(1))

        #expect(parsed.items[2].normalizedName.contains("LEZITA"))
        #expect(parsed.items[2].totalPrice == Decimal(289))

        // Ödeme Yöntemi: Kredi Kartı
        #expect(parsed.paymentMethod == .creditCard)
        // Güven skoru: Aritmetik (67 + 1 + 289 = 357) tam tuttuğu için mükemmel olmalı!
        #expect(parsed.confidenceScore >= 0.85)
    }

    @Test func testParseRealLifeFileReceiptWithWeightedSucuk() {
        let engine = TurkishReceiptParserEngine()
        let imageSize = CGSize(width: 1000, height: 4000)

        // Kullanıcının taranan 642.18 TL'lik tartılı Harris Sucuk fişi
        let rawLines: [(String, CGFloat)] = [
            ("E-Aralu Fatura", 747),
            ("FILE TIMUCIN CADDESI / TALAS / KAYS", 829),
            ("FILE MARKET MAGAZACILIK AMONIM ŞİRKETI - NO:4/A", 886),
            ("MEVLANA MAN. MEHMET TIMUÇIN CAD.", 983),
            ("TALAS / KAYSERI", 1061),
            ("Sarigazi VDM 3871427056", 1104),
            ("FATURA NO: Y092026007348690 Sira No : 327", 1243),
            ("22.09.2026 15:10", 1311),
            ("ETTN8FL059a3-e0cc-190a-8424-327804f1c614", 1304),
            ("22040012209607980327", 1473),
            ("TCKN/VKN:1111 111-NINAI TÜKETICI", 1544),
            ("0.462 kg X 1,390.00", 1667),
            ("HARRAS ACILI SUCUK %1. *642.18", 1704),
            ("TOPLAM KDV *6.36", 1830),
            ("Odenecek KDV Dahil Tutar *642.18", 1890),
            ("Ippos Kredi Kartı (1) *642.18", 2014),
            ("IS BANKASI", 2135),
            ("1 :695297101 T:S1A65A01 658768******1168", 2185),
            ("22.09.2026 15:10 B:1052 S:54", 2247),
            ("Onay No:603527 Ref. No:626522629557", 2301),
            ("KDV MATRAH KDV TUTAR KDV DAHIL", 2419),
            ("%1 . 635.82 *6.36 *642.18", 2476),
            ("ATRC", 2634),
            ("FOS:I - 463441 - K**** D**** 940122041", 3116),
            ("204, TiMUÇiN CADDES1 / TALAS GS No: 798", 3169)
        ]

        let segmentedLines: [SegmentedReceiptLine] = rawLines.map { text, y in
            let words = text.components(separatedBy: " ").enumerated().map { idx, w in
                OCRWordBox(
                    text: w,
                    confidence: 0.98,
                    boundingBox: CGRect(x: CGFloat(50 + idx * 80), y: y, width: 70, height: 24)
                )
            }
            return SegmentedReceiptLine(words: words)
        }

        let parsed = engine.parse(segmentedLines: segmentedLines, imageSize: imageSize)

        // Mağaza: FİLE
        #expect(parsed.storeName == "FİLE")
        // Toplam Tutar: 642.18 TL (3234 TL DEĞİL!)
        #expect(parsed.totalAmount == Decimal(string: "642.18"))
        // Kalem Sayısı: Sadece 1 tartılı ürün (Harras Acılı Sucuk)
        #expect(parsed.items.count == 1)

        let item = parsed.items[0]
        #expect(item.normalizedName.contains("SUCUK"))
        #expect(item.quantity == Decimal(string: "0.462"))
        #expect(item.unit == .kilogram)
        #expect(item.unitPrice == Decimal(1390))
        #expect(item.totalPrice == Decimal(string: "642.18"))
    }
}
