//
//  InsightRules.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Foundation

public protocol InsightRule: Sendable {
    var identifier: String { get }
    func evaluate(context: InsightContext) async -> [InsightCandidate]
}

/// 1. Fiyat Sıçraması Kuralı (PriceSurgeRule - Öncelik: 0.85)
/// unitPriceNormalized,new >= unitPriceNormalized,median(60 gün) * 1.15
public struct PriceSurgeRule: InsightRule {
    public let identifier = "PriceSurgeRule"
    public init() {}

    public func evaluate(context: InsightContext) async -> [InsightCandidate] {
        var candidates: [InsightCandidate] = []
        let grouped = Dictionary(grouping: context.recentPriceRecords, by: { $0.productNameNormalized })

        for (productName, records) in grouped {
            guard records.count >= 2 else { continue }
            let sortedRecords = records.sorted { $0.date > $1.date }
            guard let latest = sortedRecords.first else { continue }

            let historical = sortedRecords.dropFirst()
            let prices = historical.map { $0.unitPriceNormalized }.sorted()
            let medianPrice: Decimal
            if prices.count % 2 == 0 {
                let mid = prices.count / 2
                medianPrice = (prices[mid - 1] + prices[mid]) / Decimal(2)
            } else {
                medianPrice = prices[prices.count / 2]
            }

            guard medianPrice > 0 else { continue }
            let threshold = medianPrice * Decimal(string: "1.15")!

            if latest.unitPriceNormalized >= threshold {
                let increaseRatio = ((latest.unitPriceNormalized - medianPrice) / medianPrice) * Decimal(100)
                let pctInt = NSDecimalNumber(decimal: increaseRatio).intValue

                let candidate = InsightCandidate(
                    category: .priceSurge,
                    priority: 0.85,
                    title: "Fiyat Artışı Uyarısı",
                    message: "⚠️ \(productName.capitalized) birim fiyatı son 2 ayın medyanına göre %\(pctInt) arttı (\(CurrencyNormalizer.format(medianPrice)) ➔ \(CurrencyNormalizer.format(latest.unitPriceNormalized))).",
                    relatedProductId: latest.itemId,
                    targetEntityId: productName,
                    createdAt: context.targetDate
                )
                candidates.append(candidate)
            }
        }
        return candidates
    }
}

/// 2. Bütçe Hızı ve Projeksiyon Uyarısı (BudgetVelocityWarningRule - Öncelik: 0.95)
/// E_projected >= (1/3 sum E_t-m) * 1.20
public struct BudgetVelocityWarningRule: InsightRule {
    public let identifier = "BudgetVelocityWarningRule"
    public init() {}

    public func evaluate(context: InsightContext) async -> [InsightCandidate] {
        guard context.threeMonthAverageExpense > 0 else { return [] }
        let threshold = context.threeMonthAverageExpense * Decimal(string: "1.20")!

        if context.projectedMonthExpense >= threshold {
            let diffRatio = ((context.projectedMonthExpense - context.threeMonthAverageExpense) / context.threeMonthAverageExpense) * Decimal(100)
            let diffPct = NSDecimalNumber(decimal: diffRatio).intValue

            let candidate = InsightCandidate(
                category: .budgetWarning,
                priority: 0.95,
                title: "Bütçe Hızı Aşımı",
                message: "📈 Harcama Uyarısı: Bu ayki harcama temponuz son 3 ay ortalamasının %\(diffPct) üzerinde. Ay sonu tahmini market gideriniz: \(CurrencyNormalizer.format(context.projectedMonthExpense)).",
                relatedProductId: nil,
                targetEntityId: "global_budget",
                createdAt: context.targetDate
            )
            return [candidate]
        }
        return []
    }
}

/// 3. Mağazalar Arası Fiyat Arbitrajı (StorePriceArbitrageRule - Öncelik: 0.75)
/// unitPriceNormalized,A >= unitPriceNormalized,B * 1.15
public struct StorePriceArbitrageRule: InsightRule {
    public let identifier = "StorePriceArbitrageRule"
    public init() {}

    public func evaluate(context: InsightContext) async -> [InsightCandidate] {
        var candidates: [InsightCandidate] = []
        let grouped = Dictionary(grouping: context.recentPriceRecords, by: { $0.productNameNormalized })

        for (productName, records) in grouped {
            guard records.count >= 2 else { continue }
            let sorted = records.sorted { $0.date > $1.date }
            guard let latest = sorted.first else { continue }

            for prior in sorted.dropFirst() {
                let s1 = latest.storeName
                let s2 = prior.storeName
                guard s1 != s2 else { continue }

                let days = Calendar.current.dateComponents([.day], from: prior.date, to: latest.date).day ?? 0
                guard days <= 14 && prior.unitPriceNormalized > 0 else { continue }

                if latest.unitPriceNormalized >= prior.unitPriceNormalized * Decimal(string: "1.15")! {
                    let diffPct = NSDecimalNumber(decimal: ((latest.unitPriceNormalized - prior.unitPriceNormalized) / prior.unitPriceNormalized) * Decimal(100)).intValue
                    let candidate = InsightCandidate(
                        category: .storeArbitrage,
                        priority: 0.75,
                        title: "Tasarruf Fırsatı",
                        message: "💡 \(productName.capitalized), \(s1)'da \(CurrencyNormalizer.format(latest.unitPriceNormalized)) tuttu. \(days) gün önce \(s2)'den \(CurrencyNormalizer.format(prior.unitPriceNormalized)) fiyata almıştınız (%\(diffPct) daha uygun).",
                        relatedProductId: latest.itemId,
                        targetEntityId: "\(productName)_\(s1)_\(s2)",
                        createdAt: context.targetDate
                    )
                    candidates.append(candidate)
                    break
                }
            }
        }
        return candidates
    }
}
