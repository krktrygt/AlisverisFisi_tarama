//
//  TurkishReceiptParserEngine.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Foundation
import CoreGraphics

public final class TurkishReceiptParserEngine: Sendable {
    private static let vatTagPattern = #"^(?:\*|%|KDV)?\s*(?:0?1|0?8|10|18|20|[A-D])\.?$"#

    public init() {}

    public func parse(segmentedLines: [SegmentedReceiptLine], imageSize: CGSize) -> ParsedReceiptDTO {
        let storeMetadata = parseStoreMetadata(from: segmentedLines)
        let (parsedDate, receiptTime) = parseDateTime(from: segmentedLines)
        let receiptNo = parseReceiptNumber(from: segmentedLines)

        var lineItems: [ParsedItemDTO] = []
        var grandTotalValue: Decimal?
        var subtotalValue: Decimal?
        var totalTaxValue: Decimal?
        var totalDiscountValue: Decimal = 0.0
        var detectedPaymentMethod: PaymentMethod = .creditCard

        var pendingItemName: String?
        var pendingItemBoxes: [OCRWordBox] = []
        var pendingSubline: (qty: Decimal, unit: UnitType, uPrice: Decimal)? = nil
        var isPastItemSection = false

        for line in segmentedLines {
            let lineText = line.fullText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !lineText.isEmpty else { continue }

            // 0. Genel Toplam / Ödenecek KDV Dahil Tutar
            if let match = evaluateRegex(pattern: ReceiptRegexLibrary.grandTotalPattern, text: lineText) {
                if let amount = CurrencyNormalizer.parseDecimal(from: match) {
                    if grandTotalValue == nil || amount > (grandTotalValue ?? 0) {
                        grandTotalValue = amount
                    }
                    isPastItemSection = true
                    pendingItemName = nil
                    pendingItemBoxes = []
                    pendingSubline = nil
                    continue
                }
            }

            // 1. Ara Toplam
            if let match = evaluateRegex(pattern: ReceiptRegexLibrary.subtotalPattern, text: lineText) {
                if let amount = CurrencyNormalizer.parseDecimal(from: match) {
                    subtotalValue = amount
                    continue
                }
            }

            // 2. Toplam KDV
            if let match = evaluateRegex(pattern: ReceiptRegexLibrary.totalVatPattern, text: lineText) {
                if let amount = CurrencyNormalizer.parseDecimal(from: match) {
                    totalTaxValue = amount
                    continue
                }
            }

            // 3. Altbilgi / Fiş Kapanış / Ödeme Satırları (Stop Sentinel)
            if isReceiptFooterSentinel(lineText) {
                isPastItemSection = true
                pendingItemName = nil
                pendingItemBoxes = []
                pendingSubline = nil
            }

            // 4. Ödeme Yöntemi
            if let match = evaluateRegex(pattern: ReceiptRegexLibrary.paymentMethodPattern, text: lineText) {
                detectedPaymentMethod = mapPaymentMethod(from: match)
                if lineText.range(of: #"(?i)KRED[İI]\s*KARTI?|IPPOS|BANKA"#, options: .regularExpression) != nil {
                    // Ödeme tutarını genel toplam boşsa yedek toplam olarak alabiliriz
                    if grandTotalValue == nil, let (payAmount, _) = findRightmostPrice(in: line) {
                        grandTotalValue = payAmount
                    }
                }
                continue
            }

            // 5. İndirim / Eksi Bakiye Satırı
            if isDiscountLine(lineText) {
                if let amount = extractAmount(from: lineText) {
                    totalDiscountValue += abs(amount)
                }
                continue
            }

            // Eğer ürün bölümü sona erdiyse (altbilgiye geçildiyse), artık ürün aramıyoruz
            if isPastItemSection {
                continue
            }

            // 6. Miktar ve Birim Alt Satırı (0.462 kg x 1,390.00 veya 2 ADET * 15,00)
            if let subline = parseQuantitySubline(lineText) {
                if let (totalP, _) = findRightmostPrice(in: line), let pendingName = pendingItemName {
                    let combinedBoxes = pendingItemBoxes + line.words
                    let minX = combinedBoxes.map(\.boundingBox.minX).min() ?? line.boundingBox.minX
                    let minY = combinedBoxes.map(\.boundingBox.minY).min() ?? line.boundingBox.minY
                    let maxX = combinedBoxes.map(\.boundingBox.maxX).max() ?? line.boundingBox.maxX
                    let maxY = combinedBoxes.map(\.boundingBox.maxY).max() ?? line.boundingBox.maxY
                    let unionRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
                    let normRect = NormalizedRect(
                        originX: unionRect.origin.x / max(imageSize.width, 1),
                        originY: unionRect.origin.y / max(imageSize.height, 1),
                        width: unionRect.width / max(imageSize.width, 1),
                        height: unionRect.height / max(imageSize.height, 1)
                    )
                    let cleaned = TurkishProductNameCleaner.clean(rawName: pendingName)
                    let dynConfidence = Double(calculateConfidence(boxes: combinedBoxes))

                    let item = ParsedItemDTO(
                        rawName: pendingName,
                        normalizedName: cleaned,
                        quantity: subline.0,
                        unit: subline.1,
                        unitPrice: subline.2,
                        totalPrice: totalP,
                        taxRate: parseTaxRate(from: lineText),
                        confidenceScore: dynConfidence,
                        boundingBox: normRect
                    )
                    lineItems.append(item)
                    pendingItemName = nil
                    pendingItemBoxes = []
                    continue
                } else if let lastIdx = lineItems.indices.last, pendingItemName == nil,
                           abs(subline.0 * subline.2 - lineItems[lastIdx].totalPrice) <= 0.05 {
                    lineItems[lastIdx].quantity = subline.0
                    lineItems[lastIdx].unit = subline.1
                    lineItems[lastIdx].unitPrice = subline.2
                    continue
                } else {
                    pendingSubline = subline
                    continue
                }
            }

            // 7. Üstveri / Başlık Satırlarını Ürün Analizinden Hariç Tut
            if isHeaderOrMetadataLine(lineText) {
                pendingItemName = nil
                pendingItemBoxes = []
                continue
            }

            // 8. Standart Ürün ve Fiyat Satırı Eşleme
            if let (price, priceBox) = findRightmostPrice(in: line) {
                let rawItemName: String
                let allBoxes: [OCRWordBox]

                if let pending = pendingItemName {
                    rawItemName = pending + " " + extractNamePart(from: line, before: priceBox)
                    allBoxes = pendingItemBoxes + line.words
                    pendingItemName = nil
                    pendingItemBoxes = []
                } else {
                    rawItemName = extractNamePart(from: line, before: priceBox)
                    allBoxes = line.words
                }

                let trimmedItemName = rawItemName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedItemName.isEmpty, !isPureMetadataOrHeader(trimmedItemName) else {
                    continue
                }

                let cleanedName = TurkishProductNameCleaner.clean(rawName: trimmedItemName)
                let taxRate = parseTaxRate(from: lineText)
                let lineConfidence = calculateConfidence(boxes: allBoxes)

                let normRect = NormalizedRect(
                    originX: line.boundingBox.origin.x / max(imageSize.width, 1),
                    originY: line.boundingBox.origin.y / max(imageSize.height, 1),
                    width: line.boundingBox.width / max(imageSize.width, 1),
                    height: line.boundingBox.height / max(imageSize.height, 1)
                )

                let qty = pendingSubline?.qty ?? Decimal(1.0)
                let unit = pendingSubline?.unit ?? .piece
                let uPrice = pendingSubline?.uPrice ?? price
                pendingSubline = nil

                let item = ParsedItemDTO(
                    rawName: trimmedItemName,
                    normalizedName: cleanedName,
                    quantity: qty,
                    unit: unit,
                    unitPrice: uPrice,
                    totalPrice: price,
                    taxRate: taxRate,
                    confidenceScore: Double(lineConfidence),
                    boundingBox: normRect
                )
                lineItems.append(item)
            } else {
                if isLikelyItemName(lineText) {
                    if let pending = pendingItemName {
                        pendingItemName = pending + " " + lineText
                        pendingItemBoxes.append(contentsOf: line.words)
                    } else {
                        pendingItemName = lineText
                        pendingItemBoxes = line.words
                    }
                }
            }
        }

        // Aritmetik Çapraz Doğrulama ve Dinamik Güven Skoru
        let calculatedSum = lineItems.reduce(Decimal(0)) { $0 + $1.totalPrice }
        let patternScore = calculatePatternConfidence(
            store: storeMetadata.storeName,
            date: parsedDate,
            receiptNo: receiptNo,
            grandTotal: grandTotalValue
        )

        let arithScore: Double
        let effectiveTotal: Decimal

        if let grandTotal = grandTotalValue {
            effectiveTotal = grandTotal
            let delta = abs(calculatedSum - totalDiscountValue - grandTotal)
            if delta <= 0.02 {
                arithScore = 1.0
            } else if delta <= 0.10 {
                arithScore = 0.85
            } else if delta <= 1.00 {
                arithScore = 0.50
            } else {
                arithScore = 0.0
            }
        } else {
            arithScore = 0.0
            effectiveTotal = calculatedSum
        }

        let avgOcr = lineItems.isEmpty ? 0.0 : (lineItems.reduce(0.0) { $0 + $1.confidenceScore } / Double(lineItems.count))
        let overallConfidence = (0.25 * avgOcr) + (0.25 * patternScore) + (0.50 * arithScore)

        return ParsedReceiptDTO(
            storeName: storeMetadata.storeName,
            storeBranch: storeMetadata.branch,
            storeAddress: nil,
            storeTaxNumber: storeMetadata.vkn,
            date: parsedDate ?? Date(),
            receiptNumber: receiptNo,
            subtotal: subtotalValue ?? calculatedSum,
            discountTotal: totalDiscountValue,
            totalAmount: effectiveTotal,
            taxTotal: totalTaxValue ?? Decimal(0),
            paymentMethod: detectedPaymentMethod,
            items: lineItems,
            rawOcrText: segmentedLines.map(\.fullText).joined(separator: "\n"),
            confidenceScore: overallConfidence
        )
    }

    // MARK: - Yardımcı Metotlar

    private func isReceiptFooterSentinel(_ text: String) -> Bool {
        text.range(of: ReceiptRegexLibrary.receiptFooterSentinelPattern, options: .regularExpression) != nil
    }

    private func isPureMetadataOrHeader(_ text: String) -> Bool {
        let upper = text.uppercased()
        if text.range(of: ReceiptRegexLibrary.datePattern, options: .regularExpression) != nil { return true }
        if text.range(of: ReceiptRegexLibrary.receiptNoPattern, options: .regularExpression) != nil { return true }
        if text.range(of: ReceiptRegexLibrary.vknPattern, options: .regularExpression) != nil { return true }
        if text.range(of: ReceiptRegexLibrary.ettnPattern, options: .regularExpression) != nil { return true }
        if text.range(of: ReceiptRegexLibrary.headerMetadataPattern, options: .regularExpression) != nil { return true }
        if upper.contains("TARİH") || upper.contains("TARIH") || upper.contains("SAAT") { return true }
        return false
    }

    private func isHeaderOrMetadataLine(_ text: String) -> Bool {
        if isPureMetadataOrHeader(text) { return true }
        for store in TurkeyRetailProfile().storePatterns {
            if text.range(of: store.pattern, options: .regularExpression) != nil {
                return true
            }
        }
        return false
    }

    private func calculatePatternConfidence(store: String, date: Date?, receiptNo: String?, grandTotal: Decimal?) -> Double {
        var score = 0.0
        if store != "Bilinmeyen Market" { score += 0.25 }
        if date != nil { score += 0.25 }
        if receiptNo != nil { score += 0.15 }
        if grandTotal != nil { score += 0.35 }
        return score
    }

    private func parseStoreMetadata(from lines: [SegmentedReceiptLine]) -> (storeName: String, branch: String?, vkn: String?) {
        let topText = lines.prefix(12).map(\.fullText).joined(separator: " ")
        for store in TurkeyRetailProfile().storePatterns {
            if topText.range(of: store.pattern, options: .regularExpression) != nil {
                let vkn = evaluateRegex(pattern: ReceiptRegexLibrary.vknPattern, text: topText) ?? store.vkn
                return (store.name, nil, vkn)
            }
        }
        let vkn = evaluateRegex(pattern: ReceiptRegexLibrary.vknPattern, text: topText)
        return ("Bilinmeyen Market", nil, vkn)
    }

    private func parseDateTime(from lines: [SegmentedReceiptLine]) -> (Date?, String?) {
        let text = lines.map(\.fullText).joined(separator: "\n")
        var detectedDate: Date? = nil
        var timeStr: String?

        if let dMatch = evaluateFullMatchRegex(pattern: ReceiptRegexLibrary.datePattern, text: text) {
            let df = DateFormatter()
            df.locale = Locale(identifier: "tr_TR")
            for sep in [".", "/", "-"] {
                df.dateFormat = "dd\(sep)MM\(sep)yyyy"
                if let parsed = df.date(from: dMatch) { detectedDate = parsed; break }
                df.dateFormat = "dd\(sep)MM\(sep)yy"
                if let parsed = df.date(from: dMatch) { detectedDate = parsed; break }
            }
        }

        if let tMatch = evaluateRegex(pattern: ReceiptRegexLibrary.timePattern, text: text) {
            timeStr = tMatch
        }

        return (detectedDate, timeStr)
    }

    private func parseReceiptNumber(from lines: [SegmentedReceiptLine]) -> String? {
        let text = lines.map(\.fullText).joined(separator: "\n")
        return evaluateRegex(pattern: ReceiptRegexLibrary.receiptNoPattern, text: text)
    }

    private func findRightmostPrice(in line: SegmentedReceiptLine) -> (Decimal, OCRWordBox)? {
        for word in line.words.reversed() {
            let trimmed = word.text.trimmingCharacters(in: .whitespaces)
            if trimmed.range(of: Self.vatTagPattern, options: .regularExpression) != nil {
                continue
            }
            if let dec = CurrencyNormalizer.parseDecimal(from: trimmed) {
                if dec > 0.05 && (trimmed.contains(",") || trimmed.contains(".") || trimmed.hasPrefix("*") || trimmed.hasSuffix("TL") || trimmed.hasSuffix("₺")) {
                    return (dec, word)
                }
            }
        }
        return nil
    }

    private func extractNamePart(from line: SegmentedReceiptLine, before priceBox: OCRWordBox) -> String {
        let words = line.words.filter { $0.boundingBox.maxX <= priceBox.boundingBox.minX + 5 }
        return words.map(\.text).joined(separator: " ")
    }

    private func parseQuantitySubline(_ text: String) -> (Decimal, UnitType, Decimal)? {
        guard let regex = try? NSRegularExpression(pattern: ReceiptRegexLibrary.quantityUnitPattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }
        guard let qtyRange = Range(match.range(at: 1), in: text),
              let unitRange = Range(match.range(at: 2), in: text),
              let priceRange = Range(match.range(at: 3), in: text) else {
            return nil
        }
        let qtyStr = String(text[qtyRange])
        let unitStr = String(text[unitRange]).uppercased()
        let priceStr = String(text[priceRange])

        guard let qty = CurrencyNormalizer.parseQuantity(from: qtyStr),
              let price = CurrencyNormalizer.parseDecimal(from: priceStr) else {
            return nil
        }

        let unit: UnitType
        switch unitStr {
        case "KG", "KİLO": unit = .kilogram
        case "GR", "G", "GRAM": unit = .gram
        case "LT", "L", "LİTRE": unit = .liter
        case "ML": unit = .milliliter
        case "PK", "PAKET": unit = .pack
        default: unit = .piece
        }

        return (qty, unit, price)
    }

    private func parseTaxRate(from text: String) -> Decimal {
        guard let match = evaluateRegex(pattern: ReceiptRegexLibrary.vatRatePattern, text: text) else {
            return Decimal(sign: .plus, exponent: -2, significand: 1) // %1 varsayılan
        }
        switch match {
        case "1", "01": return Decimal(sign: .plus, exponent: -2, significand: 1) // 0.01
        case "8", "08": return Decimal(sign: .plus, exponent: -2, significand: 8) // 0.08
        case "10": return Decimal(sign: .plus, exponent: -1, significand: 1) // 0.10
        case "18": return Decimal(sign: .plus, exponent: -2, significand: 18) // 0.18
        case "20": return Decimal(sign: .plus, exponent: -1, significand: 2) // 0.20
        default: return Decimal(sign: .plus, exponent: -2, significand: 1)
        }
    }

    private func isDiscountLine(_ text: String) -> Bool {
        let hasDiscountKeyword = evaluateRegex(pattern: ReceiptRegexLibrary.discountKeywordPattern, text: text) != nil
        let hasExplicitNegativeAmount = text.range(of: #"-\s*\d{1,4}(?:[\.,]\d{3})*[\.,]\d{2}"#, options: .regularExpression) != nil
        return hasDiscountKeyword || hasExplicitNegativeAmount
    }

    private func extractAmount(from text: String) -> Decimal? {
        guard let match = evaluateRegex(pattern: ReceiptRegexLibrary.pricePattern, text: text) else { return nil }
        return CurrencyNormalizer.parseDecimal(from: match)
    }

    private func isLikelyItemName(_ text: String) -> Bool {
        let upper = text.uppercased()
        if upper.contains("TOPLAM") || upper.contains("KDV") || upper.contains("TARİH") || upper.contains("TARIH") {
            return false
        }
        if isHeaderOrMetadataLine(text) || isReceiptFooterSentinel(text) {
            return false
        }
        return text.count >= 3
    }

    private func calculateConfidence(boxes: [OCRWordBox]) -> Float {
        guard !boxes.isEmpty else { return 0.5 }
        let total = boxes.reduce(0.0) { $0 + $1.confidence }
        return total / Float(boxes.count)
    }

    private func evaluateFullMatchRegex(pattern: String, text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }
        if let range = Range(match.range(at: 0), in: text) {
            return String(text[range])
        }
        return nil
    }

    private func evaluateRegex(pattern: String, text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }
        if match.numberOfRanges > 1, let range = Range(match.range(at: 1), in: text) {
            return String(text[range])
        } else if let range = Range(match.range(at: 0), in: text) {
            return String(text[range])
        }
        return nil
    }

    private func mapPaymentMethod(from text: String) -> PaymentMethod {
        let upper = text.uppercased()
        if upper.contains("NAKİT") || upper.contains("NAKIT") {
            return .cash
        } else if upper.contains("KREDİ") || upper.contains("KREDI") || upper.contains("BANKA") || upper.contains("IPPOS") {
            return .creditCard
        } else if upper.contains("YEMEK") || upper.contains("SODEXO") || upper.contains("MULTINET") || upper.contains("TICKET") {
            return .mealCard
        }
        return .other
    }
}
