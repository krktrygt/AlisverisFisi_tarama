//
//  TurkishReceiptParserEngine.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 23.09.2026.
//

import Foundation
import CoreGraphics

/// Hibrit Kural Tabanlı & CoreML Destekli Türk Perakende Fiş Çözümleme Motoru
public final class TurkishReceiptParserEngine: Sendable {

    private let profile: RetailMarketProfile
    private let mlService: ReceiptMLInferenceService?

    private static let vatTagPattern = #"(?i)^[%*·]?\s*0?[18]0?\.?$"#

    public init(
        profile: RetailMarketProfile = TurkeyRetailProfile(),
        mlService: ReceiptMLInferenceService? = nil
    ) {
        self.profile = profile
        self.mlService = mlService
    }

    /// Asenkron CoreML destekli ayrıştırma metodu (Adım 3 Entegrasyonu)
    public func parse(
        segmentedLines: [SegmentedReceiptLine],
        imageSize: CGSize
    ) async -> ParsedReceiptDTO {
        if let ml = mlService {
            let classifiedLines = await ml.classifyLines(segmentedLines)
            var taggedTokensByLine: [[TaggedTokenResult]] = []
            taggedTokensByLine.reserveCapacity(segmentedLines.count)
            for line in segmentedLines {
                let tags = await ml.tagTokens(in: line.fullText)
                taggedTokensByLine.append(tags)
            }
            return parse(
                segmentedLines: segmentedLines,
                imageSize: imageSize,
                classifiedLines: classifiedLines,
                taggedTokensByLine: taggedTokensByLine
            )
        } else {
            return parse(
                segmentedLines: segmentedLines,
                imageSize: imageSize,
                classifiedLines: nil,
                taggedTokensByLine: nil
            )
        }
    }

    /// Senkron deterministik ve sınıflandırılmış satır destekli ayrıştırma metodu (Geriye dönük uyumluluk)
    public func parse(
        segmentedLines: [SegmentedReceiptLine],
        imageSize: CGSize,
        classifiedLines: [ClassifiedReceiptLine]? = nil,
        taggedTokensByLine: [[TaggedTokenResult]]? = nil
    ) -> ParsedReceiptDTO {
        var auditLog: [String] = []

        let storeMetadata = parseStoreMetadata(from: segmentedLines)
        let (parsedDate, receiptTime) = parseDateTime(from: segmentedLines)
        let receiptNo = parseReceiptNumber(from: segmentedLines)

        auditLog.append("=== BAŞLIK ANALİZİ ===")
        auditLog.append("Mağaza: \(storeMetadata.storeName)")
        if let branch = storeMetadata.branch { auditLog.append("Şube: \(branch)") }
        if let vkn = storeMetadata.vkn { auditLog.append("VKN: \(vkn)") }
        if let d = parsedDate { auditLog.append("Tarih: \(d.formatted(date: .numeric, time: .omitted)) Saat: \(receiptTime ?? "-")") }
        if let rNo = receiptNo { auditLog.append("Fiş/Fatura No: \(rNo)") }
        auditLog.append("======================")

        var lineItems: [ParsedItemDTO] = []
        var grandTotalValue: Decimal?
        var subtotalValue: Decimal?
        var totalTaxValue: Decimal?
        var totalDiscountValue: Decimal = 0.0
        var detectedPaymentMethod: PaymentMethod = .creditCard

        var pendingItemName: String?
        var pendingItemBoxes: [OCRWordBox] = []
        var pendingSubline: PendingSubline? = nil
        var pendingGrandTotalLabel: Bool = false
        var pendingTaxLabel: Bool = false
        var isPastItemSection = false

        for (index, line) in segmentedLines.enumerated() {
            let lineText = line.fullText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !lineText.isEmpty else { continue }

            let classifiedLine = classifiedLines != nil && index < classifiedLines!.count ? classifiedLines![index] : nil
            let classifiedRole = classifiedLine?.role ?? .unknown
            let rawMLTag = classifiedLine?.rawLabel ?? classifiedRole.rawValue
            let tokensForLine = (taggedTokensByLine != nil && index < taggedTokensByLine!.count) ? taggedTokensByLine![index] : []

            var lineLog = "[L\(index + 1)] \"\(lineText)\""
            if classifiedRole != .unknown {
                lineLog += " [ML: \(rawMLTag)]"
            }

            let upperText = lineText.uppercased()

            // 0. ÜSTVERİ / BAŞLIK HAKEMİ (Header & Metadata Gate)
            // Ürünler henüz başlamamışken veya satır bariz bir üstveriyse (Fatura, ETTN, Barkod, VKN, Tarih, Mağaza)
            // model ne derse desin (TOTAL_LINE veya TAX_SUMMARY_LINE dahil) başlık olarak işaretlenir.
            if isHeaderOrMetadataLine(lineText) && (lineItems.isEmpty || isPureMetadataOrHeader(lineText)) {
                pendingItemName = nil
                pendingItemBoxes = []
                pendingGrandTotalLabel = false
                auditLog.append("\(lineLog) -> [ATLANDI: Başlık / Üstveri]")
                continue
            }

            // 1. BEKLEYEN VERGİ ETİKETİ ÇÖZÜMLEME
            if pendingTaxLabel {
                if let (amount, _) = findRightmostPrice(in: line) {
                    if totalTaxValue == nil {
                        totalTaxValue = amount
                        auditLog.append("\(lineLog) -> [KDV BAĞLANDI] \(amount) TL")
                    }
                }
                pendingTaxLabel = false
                // Eğer satır sadece KDV tutarıysa devam et
                if line.words.count <= 2 {
                    continue
                }
            }

            // 2. BEKLEYEN GENEL TOPLAM ETİKETİ ÇÖZÜMLEME (Multi-line Total)
            if pendingGrandTotalLabel {
                if let (amount, _) = findRightmostPrice(in: line) {
                    if grandTotalValue == nil || amount > (grandTotalValue ?? 0) {
                        grandTotalValue = amount
                    }
                    isPastItemSection = true
                    auditLog.append("\(lineLog) -> [GENEL TOPLAM BAĞLANDI] \(amount) TL")
                }
                pendingGrandTotalLabel = false
                if line.words.count <= 2 {
                    continue
                }
            }

            // 3. GENEL TOPLAM ANALİZİ (GRAND TOTAL GATE)
            let isRegexGrandTotal = isGrandTotalMatch(lineText)
            let hasGrandTotalKeywords = upperText.contains("TOPLAM") || upperText.contains("ÖDENECEK") || upperText.contains("ODENECEK")
            let isMLGrandTotal = (classifiedRole == .totalLine) && hasGrandTotalKeywords && !upperText.contains("TOPLAM KDV")

            if (isRegexGrandTotal || isMLGrandTotal) && !lineItems.isEmpty {
                // Özel Durum: Eğer bu satır "Odenecek KDV Dahil Tutar" ise ve önceki satır fiyatsız "TOPLAM KDV" idiyse
                // bu satırdaki fiyat KDV'ye ait olabilir, asıl toplam sonraki satırda olabilir.
                let hasOdenecek = upperText.contains("ODENECEK") || upperText.contains("ÖDENECEK")

                if let match = evaluateRegex(pattern: ReceiptRegexLibrary.grandTotalPattern, text: lineText),
                   let amount = CurrencyNormalizer.parseDecimal(from: match) {
                    if grandTotalValue == nil || amount > (grandTotalValue ?? 0) {
                        grandTotalValue = amount
                    }
                    isPastItemSection = true
                    pendingGrandTotalLabel = false
                    pendingItemName = nil
                    pendingItemBoxes = []
                    pendingSubline = nil
                    auditLog.append("\(lineLog) -> [GENEL TOPLAM (Regex)] \(amount) TL")
                    continue
                } else if let (amount, _) = findRightmostPrice(in: line) {
                    // Eğer Odenecek KDV Dahil Tutar satırında ufak bir tutar (< %20 kalem toplamı) varsa bu KDV tutarıdır
                    let sumSoFar = lineItems.reduce(Decimal(0)) { $0 + $1.totalPrice }
                    if hasOdenecek && sumSoFar > 0 && amount < (sumSoFar * 0.3) {
                        if totalTaxValue == nil { totalTaxValue = amount }
                        pendingGrandTotalLabel = true
                        isPastItemSection = true
                        auditLog.append("\(lineLog) -> [KDV TESPİT EDİLDİ - GENEL TOPLAM SONRAKİ SATIRDA] KDV: \(amount) TL")
                        continue
                    } else {
                        if grandTotalValue == nil || amount > (grandTotalValue ?? 0) {
                            grandTotalValue = amount
                        }
                        isPastItemSection = true
                        pendingGrandTotalLabel = false
                        pendingItemName = nil
                        pendingItemBoxes = []
                        pendingSubline = nil
                        auditLog.append("\(lineLog) -> [GENEL TOPLAM (Fiyat)] \(amount) TL")
                        continue
                    }
                } else {
                    // Etiket var ama tutar hemen bir sonraki satırda
                    pendingGrandTotalLabel = true
                    pendingItemName = nil
                    pendingItemBoxes = []
                    pendingSubline = nil
                    auditLog.append("\(lineLog) -> [GENEL TOPLAM ETİKETİ BEKLİYOR]")
                    continue
                }
            }

            // 4. ARA TOPLAM
            if classifiedRole == .subtotalLine || upperText.contains("ARA TOPLAM") || upperText.contains("ARATOPLAM") {
                if let match = evaluateRegex(pattern: ReceiptRegexLibrary.subtotalPattern, text: lineText),
                   let amount = CurrencyNormalizer.parseDecimal(from: match) {
                    subtotalValue = amount
                    auditLog.append("\(lineLog) -> [ARA TOPLAM] \(amount) TL")
                    continue
                }
            }

            // 5. KDV ÖZETİ VE TABLOSU (TAX SUMMARY GATE)
            if isRealTaxSummaryLine(role: classifiedRole, text: lineText, tokens: tokensForLine) {
                var foundTax: Decimal?
                if let taxToken = tokensForLine.first(where: { $0.label == "TAX_AMOUNT" }),
                   let dec = CurrencyNormalizer.parseDecimal(from: taxToken.token) {
                    foundTax = dec
                } else if let match = evaluateRegex(pattern: ReceiptRegexLibrary.totalVatPattern, text: lineText),
                          let amount = CurrencyNormalizer.parseDecimal(from: match) {
                    foundTax = amount
                } else if let (amount, _) = findRightmostPrice(in: line) {
                    foundTax = amount
                } else {
                    pendingTaxLabel = true
                }

                if let ft = foundTax, totalTaxValue == nil {
                    totalTaxValue = ft
                }

                pendingItemName = nil
                pendingItemBoxes = []
                pendingSubline = nil
                auditLog.append("\(lineLog) -> [KDV SATIRI] (Tutar: \(foundTax ?? 0) TL)")
                continue
            }

            // 6. ALTBİLGİ / FİŞ KAPANIŞ SATIRLARI (Sentinel / Gürültü)
            if classifiedRole == .noise || isReceiptFooterSentinel(lineText) {
                if !lineItems.isEmpty {
                    isPastItemSection = true
                }
                pendingItemName = nil
                pendingItemBoxes = []
                pendingSubline = nil
                auditLog.append("\(lineLog) -> [ATLANDI: Fiş Sonu / Gürültü]")
                continue
            }

            // 7. ÖDEME YÖNTEMİ
            if classifiedRole == .paymentLine || isPaymentMatch(lineText) {
                if let match = evaluateRegex(pattern: ReceiptRegexLibrary.paymentMethodPattern, text: lineText) {
                    detectedPaymentMethod = mapPaymentMethod(from: match)
                } else {
                    detectedPaymentMethod = mapPaymentMethod(from: lineText)
                }

                if let (payAmount, _) = findRightmostPrice(in: line) {
                    if grandTotalValue == nil || payAmount > (grandTotalValue ?? 0) {
                        grandTotalValue = payAmount
                    }
                }
                pendingItemName = nil
                pendingItemBoxes = []
                pendingSubline = nil
                auditLog.append("\(lineLog) -> [ÖDEME BİLGİSİ] \(detectedPaymentMethod.rawValue)")
                continue
            }

            // 8. İNDİRİM SATIRI
            if !isPastItemSection && (classifiedRole == .discountLine || isDiscountLine(lineText)) {
                if let amount = extractAmount(from: lineText) {
                    totalDiscountValue += abs(amount)
                    auditLog.append("\(lineLog) -> [İNDİRİM SATIRI] -\(abs(amount)) TL")
                }
                pendingItemName = nil
                pendingItemBoxes = []
                pendingSubline = nil
                continue
            }

            // Eğer ürün bölümü kesin olarak bittiyse (altbilgiye geçildiyse)
            if isPastItemSection {
                // Eğer satır tek başına bir fiyatsa ve mevcut toplamdan büyükse genel toplamı güncelle
                if let (trailingPrice, _) = findRightmostPrice(in: line), line.words.count <= 2 {
                    if let cur = grandTotalValue, trailingPrice > cur {
                        grandTotalValue = trailingPrice
                        auditLog.append("\(lineLog) -> [GENEL TOPLAM GÜNCELLENDİ] \(trailingPrice) TL")
                        continue
                    }
                }
                auditLog.append("\(lineLog) -> [ATLANDI: Fiş Sonu Sonrası]")
                continue
            }

            // 9. ÇİFT YÖNLÜ FSM: MİKTAR VE BİRİM ALT SATIRI (WEIGHT_QTY_PRICE)
            if classifiedRole == .weightQtyPrice || isQuantitySubline(lineText) {
                if let subline = parseQuantitySubline(lineText) {
                    let (subQty, subUnit, subUPrice) = subline
                    let rightmostPrice = findRightmostPrice(in: line)?.0

                    var lineTotalFromSubline: Decimal? = nil
                    if let rp = rightmostPrice, rp != subUPrice, abs(subQty * subUPrice - rp) <= 0.05 {
                        lineTotalFromSubline = rp
                    }

                    // Akış A: Önce ürün adı gelmiş, ardından tartı gelmiş
                    if let pendingName = pendingItemName {
                        let totalP = lineTotalFromSubline ?? rightmostPrice ?? (subQty * subUPrice)
                        let combinedBoxes = pendingItemBoxes + line.words
                        let normRect = computeNormalizedRect(boxes: combinedBoxes, imageSize: imageSize)
                        let cleaned = TurkishProductNameCleaner.clean(rawName: pendingName)
                        let dynConfidence = Double(calculateConfidence(boxes: combinedBoxes))

                        let item = ParsedItemDTO(
                            rawName: pendingName,
                            normalizedName: cleaned,
                            quantity: subQty,
                            unit: subUnit,
                            unitPrice: subUPrice,
                            totalPrice: totalP,
                            taxRate: parseTaxRate(from: lineText),
                            confidenceScore: dynConfidence,
                            boundingBox: normRect
                        )
                        lineItems.append(item)
                        auditLog.append("\(lineLog) -> [ÜRÜN EKLENDİ - Akış A] \"\(item.normalizedName)\" (\(subQty) \(subUnit.rawValue) x \(subUPrice) = \(totalP) TL)")
                        pendingItemName = nil
                        pendingItemBoxes = []
                        pendingSubline = nil
                        continue
                    } else if let lastIdx = lineItems.indices.last,
                              pendingSubline == nil,
                              abs(subQty * subUPrice - lineItems[lastIdx].totalPrice) <= 0.05 {
                        lineItems[lastIdx].quantity = subQty
                        lineItems[lastIdx].unit = subUnit
                        lineItems[lastIdx].unitPrice = subUPrice
                        auditLog.append("\(lineLog) -> [ÖNCEKİ ÜRÜNE MİKTAR EKLENDİ] \"\(lineItems[lastIdx].normalizedName)\" (\(subQty) \(subUnit.rawValue))")
                        continue
                    } else {
                        // Akış B (FİLE Market): Önce tartı satırı geldi, ürün adı bir sonraki satırda gelecek!
                        pendingSubline = PendingSubline(
                            quantity: subQty,
                            unit: subUnit,
                            unitPrice: subUPrice,
                            lineTotal: lineTotalFromSubline,
                            words: line.words
                        )
                        auditLog.append("\(lineLog) -> [TARTI SAKLANDI - Akış B] \(subQty) \(subUnit.rawValue) x \(subUPrice) TL")
                        continue
                    }
                }
            }

            // 10. ÜRÜN VE FİYAT SATIRI EŞLEME (PRODUCT_LINE / Regex Hakemi)
            if let (price, priceBox) = findRightmostPrice(in: line) {
                let namePartInLine = extractNamePart(from: line, before: priceBox).trimmingCharacters(in: .whitespacesAndNewlines)
                let prodTokens = tokensForLine.filter { $0.label == "PROD_NAME" }
                let hasDistinctProdName = !namePartInLine.isEmpty && (namePartInLine.count >= 4 || !prodTokens.isEmpty)

                // Çoklu Satır Ayrıştırma (Eğimli Fişlerde Poşet 1 TL ve Lezita Ayrımı):
                if let pending = pendingItemName, hasDistinctProdName {
                    let cleanedPending = TurkishProductNameCleaner.clean(rawName: pending)
                    let pendingItem = ParsedItemDTO(
                        rawName: pending,
                        normalizedName: cleanedPending,
                        quantity: 1,
                        unit: .piece,
                        unitPrice: price,
                        totalPrice: price,
                        taxRate: parseTaxRate(from: pending),
                        confidenceScore: Double(calculateConfidence(boxes: pendingItemBoxes)),
                        boundingBox: computeNormalizedRect(boxes: pendingItemBoxes, imageSize: imageSize)
                    )
                    lineItems.append(pendingItem)
                    auditLog.append("\(lineLog) -> [BEKLEYEN ÜRÜN KAPATILDI] \"\(cleanedPending)\": \(price) TL")

                    pendingItemName = namePartInLine
                    pendingItemBoxes = line.words.filter { $0.boundingBox.maxX <= priceBox.boundingBox.minX + 5 }
                    continue
                }

                var rawItemName: String
                let allBoxes: [OCRWordBox]

                if let pending = pendingItemName {
                    rawItemName = pending + " " + namePartInLine
                    allBoxes = pendingItemBoxes + line.words
                    pendingItemName = nil
                    pendingItemBoxes = []
                } else {
                    rawItemName = namePartInLine
                    allBoxes = line.words
                }

                if !prodTokens.isEmpty {
                    let taggedName = prodTokens.map(\.token).joined(separator: " ")
                    if taggedName.count >= 3 {
                        rawItemName = taggedName
                    }
                }

                let trimmedItemName = rawItemName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedItemName.isEmpty, !isPureMetadataOrHeader(trimmedItemName) else {
                    auditLog.append("\(lineLog) -> [ATLANDI: Boş veya Başlık Ürünü]")
                    continue
                }

                let cleanedName = TurkishProductNameCleaner.clean(rawName: trimmedItemName)
                let taxRate = parseTaxRate(from: lineText)
                let lineConfidence = calculateConfidence(boxes: allBoxes)
                let normRect = computeNormalizedRect(boxes: allBoxes, imageSize: imageSize)

                let qty: Decimal
                let unit: UnitType
                let uPrice: Decimal

                if let sub = pendingSubline {
                    qty = sub.quantity
                    unit = sub.unit
                    uPrice = sub.unitPrice
                    pendingSubline = nil
                } else {
                    qty = Decimal(1.0)
                    unit = .piece
                    uPrice = price
                }

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
                auditLog.append("\(lineLog) -> [ÜRÜN EKLENDİ] \"\(cleanedName)\": \(price) TL (\(qty) \(unit.rawValue))")
            } else {
                // Fiyatsız satır: Ya ürün adıdır ya da Akış B'nin bekleyen tartı satırına isim sağlamaktadır
                if classifiedRole == .productLine || isLikelyItemName(lineText) {
                    var candidateName = lineText
                    let prodTokens = tokensForLine.filter { $0.label == "PROD_NAME" }
                    if !prodTokens.isEmpty {
                        candidateName = prodTokens.map(\.token).joined(separator: " ")
                    }

                    if let sub = pendingSubline {
                        let combinedBoxes = sub.words + line.words
                        let cleanedName = TurkishProductNameCleaner.clean(rawName: candidateName)
                        let dynConfidence = Double(calculateConfidence(boxes: combinedBoxes))
                        let normRect = computeNormalizedRect(boxes: combinedBoxes, imageSize: imageSize)
                        let itemTotal = sub.lineTotal ?? (sub.quantity * sub.unitPrice)

                        let item = ParsedItemDTO(
                            rawName: candidateName,
                            normalizedName: cleanedName,
                            quantity: sub.quantity,
                            unit: sub.unit,
                            unitPrice: sub.unitPrice,
                            totalPrice: itemTotal,
                            taxRate: parseTaxRate(from: lineText),
                            confidenceScore: dynConfidence,
                            boundingBox: normRect
                        )
                        lineItems.append(item)
                        auditLog.append("\(lineLog) -> [ÜRÜN TAMAMLANDI - Akış B] \"\(cleanedName)\": \(itemTotal) TL (\(sub.quantity) \(sub.unit.rawValue) x \(sub.unitPrice))")
                        pendingSubline = nil
                        pendingItemName = nil
                        pendingItemBoxes = []
                    } else {
                        if let pending = pendingItemName {
                            pendingItemName = pending + " " + candidateName
                            pendingItemBoxes.append(contentsOf: line.words)
                        } else {
                            pendingItemName = candidateName
                            pendingItemBoxes = line.words
                        }
                        auditLog.append("\(lineLog) -> [ÜRÜN ADI BEKLEMEDE] \"\(candidateName)\"")
                    }
                } else {
                    auditLog.append("\(lineLog) -> [İŞLENMEDİ / ATLANDI]")
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

        let arithmeticDiff = abs(calculatedSum - totalDiscountValue - effectiveTotal)
        auditLog.append("=== PARSER SONUCU ===")
        auditLog.append("Mağaza: \(storeMetadata.storeName)")
        auditLog.append("Kalem Sayısı: \(lineItems.count) (Toplamı: \(calculatedSum) TL)")
        auditLog.append("İndirim: \(totalDiscountValue) TL")
        auditLog.append("KDV: \(totalTaxValue ?? 0) TL")
        auditLog.append("Fiş Genel Toplamı: \(effectiveTotal) TL (Aritmetik Fark: \(arithmeticDiff) TL)")
        auditLog.append("Ödeme Yöntemi: \(detectedPaymentMethod.rawValue)")
        auditLog.append("Aritmetik Puan: \(Int(arithScore * 100))% | Model & Regex Güven Skoru: \(Int(overallConfidence * 100))%")
        auditLog.append("=====================")

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
            confidenceScore: overallConfidence,
            auditLog: auditLog
        )
    }

    // MARK: - Yardımcı Metotlar

    private func isGrandTotalMatch(_ text: String) -> Bool {
        if text.range(of: ReceiptRegexLibrary.grandTotalPattern, options: .regularExpression) != nil {
            return true
        }
        let upper = text.uppercased()
        if upper.contains("TOPLAM KDV") || upper.contains("KDV TUTAR") || upper.contains("KDV MATRAH") {
            return false
        }
        if upper.contains("GENEL TOPLAM") || upper.contains("ODENECEK") || upper.contains("ÖDENECEK") {
            return true
        }
        if upper == "TOPLAM" || upper.hasPrefix("TOPLAM ") || upper.hasSuffix(" TOPLAM") {
            return true
        }
        return false
    }

    private func isPaymentMatch(_ text: String) -> Bool {
        text.range(of: ReceiptRegexLibrary.paymentMethodPattern, options: .regularExpression) != nil
    }

    private func isTaxSummaryMatch(_ text: String) -> Bool {
        let upper = text.uppercased()
        if text.range(of: ReceiptRegexLibrary.totalVatPattern, options: .regularExpression) != nil {
            return true
        }
        if upper.contains("TOPLAM KDV") || upper.contains("KDV MATRAH") || upper.contains("KDV TUTAR") {
            return true
        }
        if upper.contains("KDV DAHIL") || upper.contains("KDV DAHİL") {
            return true
        }
        return false
    }

    /// Hakem Mekanizması: Modelin taxSummaryLine dediği satırın gerçekten KDV satırı olup olmadığını doğrular
    private func isRealTaxSummaryLine(
        role: ReceiptLineRole,
        text: String,
        tokens: [TaggedTokenResult]
    ) -> Bool {
        let upper = text.uppercased()

        // 1. Bariz KDV anahtar kelimeleri
        if isTaxSummaryMatch(text) {
            return true
        }

        // 2. Hakem: Eğer Word Tagger bu satırda güçlü bir ürün adı (PROD_NAME) bulduysa bu KESİNLİKLE vergi satırı değildir!
        let prodTokens = tokens.filter { $0.label == "PROD_NAME" }
        let prodNameLen = prodTokens.map(\.token).joined(separator: " ").count
        if prodNameLen >= 3 && !upper.contains("KDV") {
            return false
        }

        // 3. Tablo satırı: örn. "%1 286.14 *2.86 *289.00" veya "21 - 286.14 *2.86 *289.00"
        if text.range(of: #"^[%\·\d]{1,3}\s*[-–]?\s*\d+[\.,]\d{2}\s+\*?\d+[\.,]\d{2}"#, options: .regularExpression) != nil {
            return true
        }

        // 4. Eğer ML modeli taxSummaryLine dediyse: SADECE belirgin bir ürün adı yoksa kabul et
        if role == .taxSummaryLine {
            let lettersOnly = text.filter { $0.isLetter }
            if lettersOnly.count >= 4 && !upper.contains("KDV") && !upper.contains("MATRAH") {
                return false
            }
            return true
        }

        return false
    }

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
        if upper.contains("FATURA") || upper.contains("E-ARŞİV") || upper.contains("E-ARSIV") || upper.contains("E-ARALV") || upper.contains("E-ARELV") { return true }
        if upper.contains("SIRA NO") || upper.contains("SIRA:") { return true }
        if upper.contains("TCKN") || upper.contains("VKN") || upper.contains("TÜKETİCİ") || upper.contains("TUKETICI") { return true }
        if upper.contains("CADDESİ") || upper.contains("CADDESI") || upper.contains("MAHALLESİ") || upper.contains("SOKAK") || upper.contains("NO:") { return true }
        if text.range(of: #"^\d{16,}$"#, options: .regularExpression) != nil { return true }
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
        var storeName = "Bilinmeyen Market"
        var detectedVkn: String?

        for line in lines.prefix(12) {
            let t = line.fullText
            for store in TurkeyRetailProfile().storePatterns {
                if t.range(of: store.pattern, options: .regularExpression) != nil {
                    storeName = store.name
                    if detectedVkn == nil { detectedVkn = store.vkn }
                }
            }
            if let v = evaluateRegex(pattern: ReceiptRegexLibrary.vknPattern, text: t) {
                if v != "11111111111" && !t.uppercased().contains("NIHAI") && !t.uppercased().contains("NİHAİ") {
                    detectedVkn = v
                }
            }
        }
        return (storeName, nil, detectedVkn)
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
        if isPureMetadataOrHeader(line.fullText) {
            return nil
        }
        for word in line.words.reversed() {
            let trimmed = word.text.trimmingCharacters(in: .whitespaces)
            if trimmed.range(of: Self.vatTagPattern, options: .regularExpression) != nil {
                continue
            }
            if trimmed.range(of: #"^\d{1,2}[\./\-]\d{1,2}[\./\-]\d{2,4}$"#, options: .regularExpression) != nil {
                continue
            }
            if trimmed.range(of: #"^\d{1,2}:\d{2}(?::\d{2})?$"#, options: .regularExpression) != nil {
                continue
            }
            if trimmed.contains("*") && trimmed.filter({ $0.isNumber }).count > 6 && !trimmed.contains(",") && !trimmed.contains(".") {
                continue
            }
            if let dec = CurrencyNormalizer.parseDecimal(from: trimmed) {
                if dec > 0.05 && dec < 50_000 && (trimmed.contains(",") || trimmed.contains(".") || trimmed.hasPrefix("*") || trimmed.hasPrefix("#") || trimmed.hasPrefix("$") || trimmed.hasPrefix("·") || trimmed.hasPrefix("•") || trimmed.hasSuffix("TL") || trimmed.hasSuffix("₺")) {
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

    private func isQuantitySubline(_ text: String) -> Bool {
        text.range(of: ReceiptRegexLibrary.quantityUnitPattern, options: .regularExpression) != nil
    }

    private func parseQuantitySubline(_ text: String) -> (Decimal, UnitType, Decimal)? {
        let cleaned = text.replacingOccurrences(of: "*", with: "")
        guard let regex = try? NSRegularExpression(pattern: ReceiptRegexLibrary.quantityUnitPattern) else { return nil }
        guard let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)) else { return nil }

        let nsCleaned = cleaned as NSString
        guard let qty = CurrencyNormalizer.parseQuantity(from: nsCleaned.substring(with: match.range(at: 1))),
              let price = CurrencyNormalizer.parseDecimal(from: nsCleaned.substring(with: match.range(at: 3))) else {
            return nil
        }

        let rawUnit = nsCleaned.substring(with: match.range(at: 2)).uppercased()
        let unit: UnitType
        switch rawUnit {
        case "KG", "KİLO", "KILO": unit = .kilogram
        case "AD", "ADET": unit = .piece
        case "GR", "G", "GRAM": unit = .gram
        case "LT", "L", "LİTRE", "LITRE": unit = .liter
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
        if isTaxSummaryMatch(text) { return false }
        let hasDiscountKeyword = evaluateRegex(pattern: ReceiptRegexLibrary.discountKeywordPattern, text: text) != nil
        let hasExplicitNegativeAmount = text.range(of: #"-\s*\d{1,4}(?:[\.,]\d{3})*[\.,]\d{2}"#, options: .regularExpression) != nil
        return hasDiscountKeyword || (hasExplicitNegativeAmount && !text.contains("%"))
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

    private func computeNormalizedRect(boxes: [OCRWordBox], imageSize: CGSize) -> NormalizedRect {
        guard !boxes.isEmpty else {
            return NormalizedRect(originX: 0, originY: 0, width: 0, height: 0)
        }
        let minX = boxes.map(\.boundingBox.minX).min() ?? 0
        let minY = boxes.map(\.boundingBox.minY).min() ?? 0
        let maxX = boxes.map(\.boundingBox.maxX).max() ?? 0
        let maxY = boxes.map(\.boundingBox.maxY).max() ?? 0
        let unionRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        return NormalizedRect(
            originX: unionRect.origin.x / max(imageSize.width, 1),
            originY: unionRect.origin.y / max(imageSize.height, 1),
            width: unionRect.width / max(imageSize.width, 1),
            height: unionRect.height / max(imageSize.height, 1)
        )
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
        }
        return .creditCard
    }
}

private struct PendingSubline: Sendable {
    let quantity: Decimal
    let unit: UnitType
    let unitPrice: Decimal
    let lineTotal: Decimal?
    let words: [OCRWordBox]
}
