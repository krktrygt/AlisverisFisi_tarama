//
//  ReceiptRegexLibrary.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Foundation

public struct ReceiptRegexLibrary {
    // Tarih: 14.08.2026, 14/08/2026, 14-08-26
    public static let datePattern = #"(?i)\b(0?[1-9]|[12][0-9]|3[01])[\.\/\-](0?[1-9]|1[012])[\.\/\-](20\d\d|\d\d)\b"#

    // Saat: 14:25, 14:25:30, SAAT: 09:15
    public static let timePattern = #"(?i)(?:SAAT\s*[:\.]?\s*)?\b([01]?[0-9]|2[0-3])[:\.]([0-5][0-9])(?::([0-5][0-9]))?\b"#

    // Fiş No: FİŞ NO: 0142, FIS NO:0042, İŞLEM NO : 129, FATURA NO: Y092026007744519, SIRA NO: 408
    public static let receiptNoPattern = #"(?i)(?:F[Iİ][SŞ]\s*NO|FATURA\s*NO|BELGE\s*NO|S[Iİ]RA\s*NO|[Iİ]ŞLEM\s*NO|ISLEM\s*NO)\s*[:\.]?\s*([A-Z0-9]{1,25})"#

    // VKN / MERSİS / TCKN / ETTN
    public static let vknPattern = #"(?i)\b(?:VKN|VERG[İI]\s*DA[İI]RES[İI]|VERG[İI]\s*NO|TCKN(?:\/VKN)?)\s*[:\.]?\s*(\d{10,11})\b"#
    public static let mersisPattern = #"(?i)\b(?:MERS[İI]S\s*NO)\s*[:\.]?\s*(\d{16})\b"#
    public static let ettnPattern = #"(?i)\b(?:ETTN)\s*[:\.]?\s*([a-z0-9\-]{20,40})\b"#

    // Para Tutarı: 39,50, 1.250,00, *120,50, *67.00
    public static let pricePattern = #"(?i)[*]?\s*(\d{1,4}(?:[\.,]\d{3})*[\.,]\d{2})\s*(?:TL|₺)?"#

    // KDV Oranı: *01, *1, %10, %20, *08, *18, %1.
    public static let vatRatePattern = #"(?i)(?:[*%]|KDV\s*[%*]?)\s*(0?1|0?8|10|18|20)\b"#

    // Miktar ve Birim: 1,250 kg x 45,00, 3 ADET * 12,50 TL, 0.462 kg X 1,390.00
    public static let quantityUnitPattern = #"(?i)(\d+[\.,]?\d*)\s*(KG|GR|G|ADET|AD|LT|L|PK|PAKET)\s*[xX\*]\s*(\d{1,4}(?:[\.,]\d{3})*[\.,]\d{2})"#

    // Toplam ve Ara Toplam
    // "TOPLAM", "GENEL TOPLAM", "ODENECEK KDV DAHIL TUTAR", "ÖDENECEK TUTAR"
    public static let grandTotalPattern = #"(?i)(?:(?:GENEL\s+|[ÖO]DENECEK\s+(?:KDV\s+DAH[İI]L\s+)?)?TOPLAM|[ÖO]DENECEK(?:\s+KDV\s+DAH[İI]L)?\s+TUTAR)\s*[:\.]?\s*[*]?\s*(\d{1,4}(?:[\.,]\d{3})*[\.,]\d{2})"#
    public static let subtotalPattern = #"(?i)ARA\s+TOPLAM\s*[:\.]?\s*[*]?\s*(\d{1,4}(?:[\.,]\d{3})*[\.,]\d{2})"#
    public static let totalVatPattern = #"(?i)(?:TOP(?:LAM)?\s*KDV|KDV\s*TOPLAM)\s*[:\.]?\s*[*]?\s*(\d{1,4}(?:[\.,]\d{3})*[\.,]\d{2})"#

    // İndirimler
    public static let discountKeywordPattern = #"(?i)(?:[İI]ND[İI]R[İI]M|KAMPANYA|MONEY|W[İI]N|ISKONTO|TENZ[İI]LAT)"#
    public static let negativeAmountPattern = #"(?i)(?:-\s*|\(\s*)(\d{1,4}(?:[\.,]\d{3})*[\.,]\d{2})\s*\)?"#

    // Ödeme Yöntemi
    public static let paymentMethodPattern = #"(?i)\b(NAK[İI]T|KRED[İI]\s*KARTI?|BANKA\s*KARTI?|TEMASSIZ|HED[İI]YE\s*ÇEK[İI]|YEMEK\s*KARTI?|SODEXO|MULTINET|TICKET|IPPOS)\b"#

    // Üstbilgi / Fatura / Kurumsal Başlık Satırları Deseni
    public static let headerMetadataPattern = #"(?i)(?:E-AR[SŞ][İI]V|E-FATURA|E-ARALU|E-FRALV|FATURA\s*NO|VERG[İI]\s*DA[İI]RES[İI]|VDM|TICARET\s*SICIL|MERSIS|MERS[İI]S|TCKN|VKN|ETTN|MAH\.|CAD\.|NO\s*:\s*\d|TALAS|KAYSER[İI]|SARIGAZ[İI]|SAR[İI]GAZ[İI]|N[İI]HA[İI]\s*T[ÜU]KET[İI]C[İI]|SIRA\s*NO)"#

    // Altbilgi / Fiş Kapanış / Stop Sentinel Deseni (Ürün taramasını kesin olarak durduran anahtar kelimeler)
    public static let receiptFooterSentinelPattern = #"(?i)(?:TOPLAM\s*KDV|[ÖO]DENECEK|KRED[İI]\s*KARTI?|IPPOS|IS\s*BANKASI|[İI]Ş\s*BANKASI|ONAY\s*NO|REF\s*\.?\s*NO|MATRAH|KDV\s*TUTAR|KDV\s*DAH[İI]L|ATRC|FOS\s*:|POS\s*:|B\s*:\s*\d+\s+S\s*:|TERMINAL|G[ÜU]LE\s*G[ÜU]LE)"#
}
