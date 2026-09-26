//
//  ReceiptParserEngineBenchmarkTests.swift
//  Alisveris-fisTaramaTests
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Testing
import Foundation
import CoreGraphics
@testable import Alisveris_fisTarama

@Suite(.serialized)
struct ReceiptParserEngineBenchmarkTests {

    @Test func testParseSimpleReceiptSuccess() {
        let engine = TurkishReceiptParserEngine()
        let imageSize = CGSize(width: 1000, height: 2000)

        // Sentetik BİM fişi satırları
        let rawLines: [(String, CGFloat)] = [
            ("BIM BIRLESIK MAGAZALAR A.S.", 100),
            ("KADIKOY SUBESI ISTANBUL", 130),
            ("VKN: 1750051846", 160),
            ("TARIH: 22.09.2026 SAAT: 14:30", 190),
            ("FIS NO: 0042", 220),
            ("DOST SUT 1L %1 *29.50", 350),
            ("EFSANE UN 2KG %1 *45.00", 390),
            ("TOPKDV *1.45", 500),
            ("TOPLAM *74.50", 550),
            ("KREDI KARTI *74.50", 600)
        ]

        let segmentedLines: [SegmentedReceiptLine] = rawLines.map { text, y in
            let words = text.components(separatedBy: " ").enumerated().map { idx, w in
                OCRWordBox(text: w, confidence: 0.95, boundingBox: CGRect(x: CGFloat(50 + idx * 80), y: y, width: 70, height: 24))
            }
            return SegmentedReceiptLine(words: words)
        }

        let parsed = engine.parse(segmentedLines: segmentedLines, imageSize: imageSize)

        // Mağaza ve Üstveri Doğrulaması
        #expect(parsed.storeName == "BİM")
        #expect(parsed.receiptNumber == "0042")
        #expect(parsed.paymentMethod == .creditCard)
        #expect(parsed.totalAmount == Decimal(string: "74.50"))

        // Kalem Doğrulaması
        #expect(parsed.items.count == 2)
        #expect(parsed.items[0].normalizedName == "DOST SÜT 1L")
        #expect(parsed.items[0].totalPrice == Decimal(string: "29.50"))
        #expect(parsed.items[1].normalizedName == "EFSANE UN 2KG")
        #expect(parsed.items[1].totalPrice == Decimal(string: "45.00"))

        // Güven Skoru Doğrulaması
        #expect(parsed.confidenceScore > 0.8)
    }

    @Test func testParseWeightedItemSubline() {
        let engine = TurkishReceiptParserEngine()
        let imageSize = CGSize(width: 1000, height: 2000)

        // Manav / Tartılı Kalem Senaryosu:
        // DOMATES SALKIM
        // 1.450 KG X 35.00 *50.75
        let rawLines: [(String, CGFloat)] = [
            ("MIGROS TICARET A.S.", 100),
            ("DOMATES SALKIM", 300),
            ("1.450 KG X 35.00 *50.75", 340),
            ("TOPLAM *50.75", 500)
        ]

        let segmentedLines: [SegmentedReceiptLine] = rawLines.map { text, y in
            let words = text.components(separatedBy: " ").enumerated().map { idx, w in
                OCRWordBox(text: w, confidence: 0.95, boundingBox: CGRect(x: CGFloat(50 + idx * 80), y: y, width: 70, height: 24))
            }
            return SegmentedReceiptLine(words: words)
        }

        let parsed = engine.parse(segmentedLines: segmentedLines, imageSize: imageSize)

        #expect(parsed.storeName.localizedCaseInsensitiveContains("Migros"))
        #expect(parsed.items.count == 1)

        let item = parsed.items[0]
        #expect(item.normalizedName == "DOMATES SALKIM")
        #expect(item.quantity == Decimal(string: "1.45"))
        #expect(item.unit == .kilogram)
        #expect(item.unitPrice == Decimal(string: "35.00"))
        #expect(item.totalPrice == Decimal(string: "50.75"))
    }

    @Test func testParseRealLifeFileReceipt() {
        let engine = TurkishReceiptParserEngine()
        let imageSize = CGSize(width: 962, height: 3565)

        // Gerçek hayat FİLE Market Fişi (Kullanıcının paylaştığı birebir OCR çıktısı)
        let rawLines: [(String, CGFloat)] = [
            ("E-Arelv Fatura", 692),
            ("FILE TIMUCIN CADOEST / TALAS / KAYS", 791),
            ("FILE MARKET MAGAZACILIK ANONIM SIRKETI", 842),
            ("MEVLANA MAH. MEHMET TIMUCIN CAD. NO:4/A", 900),
            ("TALAS / KAYSERI", 987),
            ("Sarigazi VDM 3871427056", 1039),
            ("FATURA NO:V092026007744519", 1141),
            ("23.09.2026 16:57", 1198),
            ("Sira No : 408", 1235),
            ("ETTN5e401dfd-5cf5-45da-a7ba-884f94cae761", 1255),
            ("22040012309608000408", 1405),
            ("TCKN/VKN:11111111111-NIHAI TUKETICI", 1462),
            ("PEPSI MAX 1,5L %10 *67.00", 1588),
            ("ALISVERIS POSETI %20", 1645),
            ("LEZITA CITIR KIT 700 %1. *1.00", 1678),
            ("*289.00", 1734),
            ("TOPLAM KDV", 1808),
            ("Odenecek KDV Dahil Tutar *9.12", 1854),
            ("*357.00", 1912),
            ("Ippos Kredi Kartı (1)", 1985),
            ("*357.00", 2023),
            ("IS BANKASI", 2093),
            ("I:695297101 T:S1A65A01", 2148),
            ("23.09.2026 16:57 B:1054 S:126 658768******1168", 2185),
            ("Onay No:229748", 2264),
            ("Ref .No:626635020991", 2290),
            ("KDV MATRAH", 2379),
            ("%1. 286.14 KDV TUTAR KDV DAHIL", 2414),
            ("%10 60.91 *2.86 *289.00", 2475),
            ("%20 0.83 *6.09 *67.00", 2531),
            ("*0.17 *1.00", 2591),
            ("POS:1 - 463441 - K**** D****", 3273),
            ("2204, TIMUCIN CADDESI / TALAS GS No: 800 940122041", 3325)
        ]

        let segmentedLines: [SegmentedReceiptLine] = rawLines.map { text, y in
            let words = text.components(separatedBy: " ").enumerated().map { idx, w in
                OCRWordBox(text: w, confidence: 0.95, boundingBox: CGRect(x: CGFloat(50 + idx * 80), y: y, width: 70, height: 24))
            }
            return SegmentedReceiptLine(words: words)
        }

        let parsed = engine.parse(segmentedLines: segmentedLines, imageSize: imageSize)

        // Mağaza: FİLE
        #expect(parsed.storeName == "FİLE")
        // Fatura No: V092026007744519
        #expect(parsed.receiptNumber == "V092026007744519")
        // VKN: 3871427056
        #expect(parsed.storeTaxNumber == "3871427056")
        // Genel Toplam: 357.00 TL (E-arşiv faturalarda 22 milyar değil!)
        #expect(parsed.totalAmount == Decimal(string: "357.00"))
        // KDV Toplamı: 9.12 TL
        #expect(parsed.taxTotal == Decimal(string: "9.12"))
        // Ödeme Yöntemi: Kredi Kartı
        #expect(parsed.paymentMethod == .creditCard)
    }

    @Test func testParseRealLifeFileReceiptWithWeightedSucuk() {
        let engine = TurkishReceiptParserEngine()
        let imageSize = CGSize(width: 991, height: 3389)

        // Gerçek hayat FİLE Market Tartılı Sucuk Fişi
        // "0.462 kg X 1,390.00
        //  HARRAS ACILI SUCUK
        //  21 - *642.18"
        let rawLines: [(String, CGFloat)] = [
            ("FILE MARKET MAGAZACILIK ANONIM SIRKETI", 854),
            ("Sarigazi VDM 3871427056", 1048),
            ("FATURA NO: V092026007348690", 1171),
            ("22.09.2026 15:10 Sira No : 327", 1221),
            ("0.462 kg X 1,390.00", 1637),
            ("HARRAS ACILI SUCUK 21 - *642.18", 1677),
            ("TOPLAM KDV", 1822),
            ("Odenecek KDV Dahil Tutar *6.36", 1860),
            ("*642.18", 1974),
            ("Ippos Kredi Kartı (1) *642.18", 2118),
            ("KDV TUTAR KDV DAHIL", 2378),
            ("KDV *6.36 *642.18", 2421),
            ("21 - 635.82", 2471)
        ]

        let segmentedLines: [SegmentedReceiptLine] = rawLines.map { text, y in
            let words = text.components(separatedBy: " ").enumerated().map { idx, w in
                OCRWordBox(text: w, confidence: 0.95, boundingBox: CGRect(x: CGFloat(50 + idx * 80), y: y, width: 70, height: 24))
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

    @Test func testFileSucukRegressionWithCoreMLHybridEngine() async {
        let mlService = ReceiptMLInferenceService.shared
        let engine = TurkishReceiptParserEngine(mlService: mlService)
        let imageSize = CGSize(width: 1000, height: 2000)

        let rawLines: [(String, CGFloat)] = [
            ("0.462 kg X 1,390.00 ·1 - *642.18", 100),
            ("HARRAS ACILI SUCUK", 140),
            ("*6.36", 180),
            ("TOPLAM KDV", 220),
            ("Odenecek KDV Dahil Tutar", 260),
            ("*642.18", 300)
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

        let start = ContinuousClock.now
        let parsed = await engine.parse(segmentedLines: segmentedLines, imageSize: imageSize)
        let elapsed = ContinuousClock.now - start

        #expect(parsed.items.count == 1)
        if let item = parsed.items.first {
            #expect(item.normalizedName.contains("SUCUK") || item.rawName.contains("SUCUK"))
            #expect(item.quantity == Decimal(string: "0.462"))
            #expect(item.unit == .kilogram)
            #expect(item.unitPrice == Decimal(1390))
            #expect(item.totalPrice == Decimal(string: "642.18"))
        }

        #expect(parsed.totalAmount == Decimal(string: "642.18"))
        #expect(parsed.taxTotal == Decimal(string: "6.36"))
        #expect(elapsed < .milliseconds(500))
    }

    @Test func testRealDeviceSession1CatastrophicRegressionFix() async {
        let mlService = ReceiptMLInferenceService.shared
        let engine = TurkishReceiptParserEngine(mlService: mlService)
        let imageSize = CGSize(width: 911, height: 3486)

        // Gerçek cihazdan gelen Session 1 OCR satırları
        let session1Lines: [(String, CGFloat)] = [
            ("E-Arelv Fatura", 605),
            ("FILE TIMUCIN CADDESI / TALAS / KAYS", 690),
            ("FİLE MARKET MAĞAZACILIK ANONIM SIRKETI", 741),
            ("MEVLANA MAH. MEHMET TIMUCIN CAD. NO:4/A", 789),
            ("TALAS / KAYSERI", 849),
            ("Sarıgazi VDM 3871427056", 911),
            ("FATURA NO: Y092026007744519", 1009),
            ("23.09.2026 16:57 Sira No : 408", 1067),
            ("ET ba401dfd-5cf5-45da-a7ba-884f94cae761", 1116),
            ("PELE", 1165),
            ("22040012309608000408", 1234),
            ("TCKN/VKN:11111111111-NIHAI TÜKETICI", 1295),
            ("PEPS1 MAX 1,5L %10 *67.00", 1411),
            ("ALIŞVERİŞ POSETI %20 *1.00", 1465),
            ("LEZİTA ÇITIR KIT 700 %1. *289.00", 1526),
            ("TOPLAM KDV *9.12", 1640),
            ("Odenecek KDV Dahil Tutar *357.00", 1693),
            ("Ippos Kredi Kartı (1) *357.00", 1815),
            ("IS BANKASI", 1934),
            ("1:695297101 T:S1A65A01 658768******1168", 1982),
            ("23.09.2026 16:57 B:1054 S:126", 2042),
            ("Onay No:229748 Ref .No:626635020991", 2099),
            ("KDV MATRAH KDV TUTAR KDV DAHIL", 2220),
            ("%1 286.14 *2.86 *289.00", 2277),
            ("%10 60.91 *6.09 *67.00", 2338),
            ("%20 0.83 *0.17 *1.00", 2399),
            ("POS:1 - 463441 - K**** D**** 940122041", 3158),
            ("2204, TIMUCIN CADDES1 / TALAS GS No: 800", 3204)
        ]

        let segmentedLines = session1Lines.map { text, y in
            let words = text.components(separatedBy: " ").enumerated().map { idx, w in
                OCRWordBox(text: w, confidence: 0.98, boundingBox: CGRect(x: CGFloat(50 + idx * 80), y: y, width: 70, height: 24))
            }
            return SegmentedReceiptLine(words: words)
        }

        let parsed = await engine.parse(segmentedLines: segmentedLines, imageSize: imageSize)

        // 1. Üç ürün de başarıyla ayrıştırılmalı (Poşet veya Lezita KDV diye yutulmamalı!)
        #expect(parsed.items.count == 3)

        // 2. Tutar doğrulaması
        let totalSum = parsed.items.reduce(Decimal(0)) { $0 + $1.totalPrice }
        #expect(totalSum == Decimal(357))
        #expect(parsed.totalAmount == Decimal(357))

        // 3. KDV tutarı doğru yakalanmalı
        #expect(parsed.taxTotal == Decimal(string: "9.12"))

        // 4. Aritmetik tam tuttuğu için güven skoru yüksek olmalı
        #expect(parsed.confidenceScore >= 0.85)

        // 5. Mağaza FİLE olarak tanınmalı
        #expect(parsed.storeName == "FİLE")
    }

    @Test func testRealDeviceSession3SucukReceiptFix() async {
        let mlService = ReceiptMLInferenceService.shared
        let engine = TurkishReceiptParserEngine(mlService: mlService)
        let imageSize = CGSize(width: 1088, height: 3381)

        // Gerçek cihazdan gelen Session 3 Sucuk OCR satırları
        let session3Lines: [(String, CGFloat)] = [
            ("E-Argiv Fatura", 715),
            ("FILE TIMUÇIN CADDESI / TALAS / KAYS", 819),
            ("FİLE MARKET MAGAZACILIK ANONIM ŞİRKETI", 877),
            ("MEVLANA MAH. MEHMET TIMUÇIN CAD. NO:4/A", 941),
            ("TALAS / KAYSER!", 1024),
            ("Sarigazi VDM 3871427056", 1084),
            ("FATURA NO: Y092026007318690", 1212),
            ("22.09.2026 15:10 Sira No : 327", 1258),
            ("ETTN8fb059a3-e0cc-490a-8424-327804f1c514", 1322),
            ("22040012209607980327", 1480),
            ("TCKN/VKN:1111 11111 '¿NIHAI TUKETICI", 1547),
            ("0.462 kg X 1,390.00 #642.18", 1688),
            ("HARRAS ACILI SUDUK I1.", 1746),
            ("*6.30", 1853),
            ("TOPLAM KDV $642.18", 1886),
            ("Odenecek KDV Dahil Tutar", 1929),
            ("*642.18", 2030),
            ("Ippos kredi Karti (1)", 2055),
            ("IS BANKASI", 2203),
            ("I:695297101 T:51A65A01 658768******1168", 2212),
            ("22.09.2026 15:10 B:1052 S:54", 2281),
            ("Ref. No:626522629557", 2337),
            ("Onay No: 603527", 2374),
            ("KOV TUTAR KDV DAHIL", 2470),
            ("KDV MATRAH *6.36 *642.18", 2507),
            ("21 - 635.82", 2579)
        ]

        let segmentedLines = session3Lines.map { text, y in
            let words = text.components(separatedBy: " ").enumerated().map { idx, w in
                OCRWordBox(text: w, confidence: 0.98, boundingBox: CGRect(x: CGFloat(50 + idx * 80), y: y, width: 70, height: 24))
            }
            return SegmentedReceiptLine(words: words)
        }

        let parsed = await engine.parse(segmentedLines: segmentedLines, imageSize: imageSize)

        // 1. Tartılı ürün başarıyla çıkarılmalı
        #expect(parsed.items.count == 1)
        if let item = parsed.items.first {
            #expect(item.normalizedName.contains("SUCUK") || item.rawName.contains("SUCUK") || item.normalizedName.contains("SUDUK") || item.rawName.contains("SUDUK"))
            #expect(item.totalPrice == Decimal(string: "642.18"))
            #expect(item.quantity == Decimal(string: "0.462"))
        }

        // 2. Çok satırlı Odenecek KDV Dahil Tutar başarıyla bağlanmalı
        #expect(parsed.totalAmount == Decimal(string: "642.18"))

        // 3. Güven skoru yüksek olmalı
        #expect(parsed.confidenceScore >= 0.85)
    }

    @Test func testRealDeviceSession4FileMultiItemWeightedAndStackedReceiptFix() async {
        let mlService = ReceiptMLInferenceService.shared
        let engine = TurkishReceiptParserEngine(mlService: mlService)
        let imageSize = CGSize(width: 1088, height: 3500)

        // Gerçek cihazdan gelen Session 4 (26.09.2026 FİLE Market) OCR satırları
        let session4Lines: [(String, CGFloat)] = [
            ("E-Arsiv Fatura", 380),
            ("FILE TIMUÇIN CADDESI / TALAS / KAYS", 456),
            ("FİLE MARKET MAGAZACILIK ANONIM ŞİRKETİ", 500),
            ("MEVLANA MAH. MEHMET TIMUÇIN CAD. NO:4/A", 543),
            ("TALAS / KAYSERİ", 588),
            ("Sarigazi VDM 3871427056", 644),
            ("FATURA NO: Y092026007744519", 747),
            ("26.09.2026 13:21 Sira No : 408", 787),
            ("ETTN:e7ff388e-7164-4fe1-ba5d-e08a6bba59c7", 845),
            ("22040012209607980408", 965),
            ("TCKN/VKN: 11111111111 '¿NİHAİ TÜKETİCİ", 1022),
            ("2011", 1236),
            ("N.ANKARA A.SEHR.500G %1. *37.50", 1284),
            ("YUMURTA OLU ABALICİ %1. *169.00", 1332),
            ("0.85 kg X 89.9îŚ", 1374),
            ("GOLDEN ELMA *76.42", 1417),
            ("SÜZMEPEY 500G HARRAS %1. *119.00", 1462),
            ("0.6 kg X 49.90", 1516),
            ("ÇENGELKÖY SALATALIK %1. *29.94", 1558),
            ("0.826 kg X 39.90", 1608),
            ("PATATES (DÖKME) %1. *32.96", 1654),
            ("0.854 kg X 39.90", 1703),
            ("DOMATES %1 . *34.07", 1749),
            ("ALIŞVERİŞ POŞETİ %20 *1.00", 1797),
            ("Disimeno ns", 1883),
            ("TOPLAM KDV *5.11", 1935),
            ("Odenecek KDV Dahil Tutar", 1974),
            ("*499.89", 2043),
            ("Ippos kredi Karti (1)", 2073),
            ("IS BANKASI", 2172),
            ("T:51A65A01", 2185),
            ("658768******1168", 2217),
            ("26.09.2026 13:21 B:1052 S:46", 2235),
            ("Ref. No:626918804595", 2276),
            ("Onay No: 121175", 2307),
            ("KOV TUTAR KDV DAHIL", 2383),
            ("KDV MATRAH *5.11 *499.89", 2411),
            ("21 - 493.94", 2469),
            ("%20 0.83 *0.17 *1.00", 2515)
        ]

        let segmentedLines = session4Lines.map { text, y in
            let words = text.components(separatedBy: " ").enumerated().map { idx, w in
                OCRWordBox(text: w, confidence: 0.98, boundingBox: CGRect(x: CGFloat(50 + idx * 80), y: y, width: 70, height: 24))
            }
            return SegmentedReceiptLine(words: words)
        }

        let parsed = await engine.parse(segmentedLines: segmentedLines, imageSize: imageSize)

        // 1. Toplam 8 adet gerçek ürün tespit edilmeli (Disimeno ns gürültüsü atılmalı, 4 adet tartılı ürün doğru bağlanmalı)
        #expect(parsed.items.count == 8)

        // 2. Tartılı ürünlerin miktarları ve isimleri doğru sentezlenmeli
        let elma = parsed.items.first(where: { $0.rawName.contains("ELMA") || $0.normalizedName.contains("ELMA") })
        #expect(elma != nil)
        #expect(elma?.totalPrice == Decimal(string: "76.42"))
        #expect(elma?.quantity == Decimal(string: "0.85"))

        let salatalik = parsed.items.first(where: { $0.rawName.contains("SALATALIK") || $0.normalizedName.contains("SALATALIK") })
        #expect(salatalik != nil)
        #expect(salatalik?.totalPrice == Decimal(string: "29.94"))
        #expect(salatalik?.quantity == Decimal(string: "0.6"))

        let patates = parsed.items.first(where: { $0.rawName.contains("PATATES") || $0.normalizedName.contains("PATATES") })
        #expect(patates != nil)
        #expect(patates?.totalPrice == Decimal(string: "32.96"))
        #expect(patates?.quantity == Decimal(string: "0.826"))

        let domates = parsed.items.first(where: { $0.rawName.contains("DOMATES") || $0.normalizedName.contains("DOMATES") })
        #expect(domates != nil)
        #expect(domates?.totalPrice == Decimal(string: "34.07"))
        #expect(domates?.quantity == Decimal(string: "0.854"))

        // 3. Kalem toplamı ile genel toplam kuruşu kuruşuna eşit olmalı
        let totalSum = parsed.items.reduce(Decimal(0)) { $0 + $1.totalPrice }
        #expect(totalSum == Decimal(string: "499.89"))
        #expect(parsed.totalAmount == Decimal(string: "499.89"))

        // 4. KDV tutarı doğru yakalanmalı
        #expect(parsed.taxTotal == Decimal(string: "5.11"))

        // 5. Aritmetik %100 tuttuğu için güven skoru yüksek olmalı
        #expect(parsed.confidenceScore >= 0.85)

        // 6. Mağaza FİLE olarak tanınmalı
        #expect(parsed.storeName == "FİLE")
    }
}
