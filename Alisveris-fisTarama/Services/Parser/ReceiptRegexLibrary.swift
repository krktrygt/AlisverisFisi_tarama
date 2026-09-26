//
//  ReceiptRegexLibrary.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Foundation

/// Türkiye Fiş ve Fatura Formatları için Optimize Edilmiş Regex Kütüphanesi
public struct ReceiptRegexLibrary: Sendable {

    // Tarih: 14.08.2026, 14/08/2026, 14-08-2026, 14.08.26
    public static let datePattern = #"\b([0-3]?[0-9])[\./\-]([0-1]?[0-9])[\./\-](20\d{2}|\d{2})\b"#

    // Saat: 14:25, 14.25, 14:25:03, SAAT: 14:25
    public static let timePattern = #"(?i)(?:SAAT\s*[:\.]?\s*)?\b([01]?[0-9]|2[0-3])[:\.]([0-5][0-9])(?::([0-5][0-9]))?\b"#

    // Fiş No: FİŞ NO: 0142, FIS NO:0042, İŞLEM NO : 129, FATURA NO: Y092026007744519, SIRA NO: 408
    public static let receiptNoPattern = #"(?i)(?:F[Iİ][SŞ]\s*NO|FATURA\s*NO|BELGE\s*NO|S[Iİ]RA\s*NO|[Iİ]ŞLEM\s*NO|ISLEM\s*NO)\s*[:\.]?\s*([A-Z0-9]{1,25})"#

    // VKN / MERSİS / TCKN / ETTN
    public static let vknPattern = #"(?i)\b(?:VKN|VERG[İI]\s*DA[İI]RES[İI]|VERG[İI]\s*NO|TCKN(?:\/VKN)?)\s*[:\.]?\s*(\d{10,11})\b"#
    public static let mersisPattern = #"(?i)\b(?:MERS[İI]S\s*NO)\s*[:\.]?\s*(\d{16})\b"#
    public static let ettnPattern = #"(?i)\b(?:ETTN)\s*[:\.]?\s*([a-z0-9\-]{20,40})\b"#

    // Para Tutarı: 39,50, 1.250,00, *120,50, *67.00
    public static let pricePattern = #"(?i)[*]?\s*(\d{1,4}(?:[\.,]\d{3})*[\.,]\d{2})\s*(?:TL|₺)?"#

    // KDV Oranı: *01, *1, %10, %20, *08, *18, %1., X1., 31 ., X20
    public static let vatRatePattern = #"(?i)(?:[%*·•#Xx3!Iİl]|KDV\s*[%*]?)\s*(0?[18]|10|18|20)\b"#

    // Miktar ve Birim: 1,250 kg x 45,00, 3 ADET * 12,50 TL, 0.462 kg X 1,390.00, 0.85 kg X 89.90
    public static let quantityUnitPattern = #"(?i)(\d+[\.,]?\d*)\s*(KG|KİLO|KILO|GR|G|GRAM|ADET|AD|LT|L|LİTRE|LITRE|PK|PAKET)\s*[xX\*]\s*(\d{1,4}(?:[\.,]\d{3})*[\.,]\d{1,2})"#

    // Toplam ve Ara Toplam
    // "TOPLAM", "GENEL TOPLAM", "ODENECEK KDV DAHIL TUTAR", "ÖDENECEK TUTAR"
    public static let grandTotalPattern = #"(?i)(?:(?:GENEL\s+|[ÖO]DENECEK\s+(?:KDV\s+DAH[İI]L\s+)?)?TOPLAM|[ÖO]DENECEK(?:\s+KDV\s+DAH[İI]L)?\s+TUTAR)\s*[:\.]?\s*[*]?\s*(\d{1,4}(?:[\.,]\d{3})*[\.,]\d{2})"#
    public static let subtotalPattern = #"(?i)ARA\s+TOPLAM\s*[:\.]?\s*[*]?\s*(\d{1,4}(?:[\.,]\d{3})*[\.,]\d{2})"#
    public static let totalVatPattern = #"(?i)(?:TOP(?:LAM)?\s*KDV|KDV\s*TOPLAM)\s*[:\.]?\s*[*]?\s*(\d{1,4}(?:[\.,]\d{3})*[\.,]\d{2})"#

    // İndirimler
    public static let discountKeywordPattern = #"(?i)\b(IND|İND|INDIRIM|İNDİRİM|ISKONTO|PROMOSYON)\b"#

    // Ödeme Tipleri
    public static let paymentMethodPattern = #"(?i)\b(NAK[İI]T|KRED[İI]\s*KARTI|BANKA\s*KARTI|IPPOS|TEMASSIZ|TROY|VISA|MASTERCARD)\b"#

    // Başlık ve Üstveri Desenleri
    public static let headerMetadataPattern = #"(?i)\b(TICARET|TİCARET|A\.S\.|A\.Ş\.|LTD|ŞTİ|STI|MAĞAZACILIK|MAGAZACILIK|SUBE|ŞUBE|FATURA|IRSALIYE|İRSALİYE|BILGI FISI|BİLGİ FİŞİ|E-ARSIV|E-ARŞİV|MUKELLEF|MÜKELLEF|VDM|VERGI DAIRESI|VERGİ DAİRESİ|MERSIS|MERSİS|SICIL|SİCİL|KASİYER|KASIYER|KASA NO|TERMINAL|SERI NO|SERİ NO)\b"#

    // Fiş Kapanış / Altbilgi / Gürültü Belirteçleri
    public static let receiptFooterSentinelPattern = #"(?i)\b(MALI DEGERI YOKTUR|MALİ DEĞERİ YOKTUR|BILGI AMACLIDIR|BİLGİ AMAÇLIDIR|GULE GULE|GÜLE GÜLE|YINE BEKLERIZ|YİNE BEKLERİZ|TESSEKKUR|TEŞEKKÜR|IYI GUNLER|İYİ GÜNLER|BUNU SAKLAYINIZ|GECERSIZDIR|GEÇERSİZDİR|KART SAHIBI|KART SAHİBİ|KOPYA|AIDIR|AYDIR)\b"#
}
