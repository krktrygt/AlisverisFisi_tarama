//
//  PersonalInflationEngine.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Foundation

public struct LaspeyresIndexResult: Sendable {
    public let indexValue: Decimal? // 100 bazlı indeks değeri (örn: 112.5 -> %12.5 enflasyon)
    public let inflationRate: Decimal? // Net artış oranı (%)
    public let matchedItemCount: Int
    public let basketCoverageRatio: Decimal
    public let isReliable: Bool
}

public enum PersonalInflationEngine: Sendable {
    /// Ağırlıklı Laspeyres Kişisel Market Enflasyon Endeksi (Bulgu 21)
    /// I_L^t = (sum_{i in M_t} P_{i,t} * Q_{i,0}) / (sum_{i in M_t} P_{i,0} * Q_{i,0}) * 100
    public static func calculateLaspeyresIndex(
        baseBasket: [(name: String, basePrice: Decimal, baseQuantity: Decimal)],
        currentPrices: [String: Decimal]
    ) -> LaspeyresIndexResult {
        guard !baseBasket.isEmpty else {
            return LaspeyresIndexResult(
                indexValue: nil,
                inflationRate: nil,
                matchedItemCount: 0,
                basketCoverageRatio: Decimal(0),
                isReliable: false
            )
        }

        let totalBaseCost = baseBasket.reduce(Decimal(0)) { $0 + ($1.basePrice * $1.baseQuantity) }
        guard totalBaseCost > 0 else {
            return LaspeyresIndexResult(
                indexValue: nil,
                inflationRate: nil,
                matchedItemCount: 0,
                basketCoverageRatio: Decimal(0),
                isReliable: false
            )
        }

        var matchedBaseCost = Decimal(0)
        var matchedCurrentCost = Decimal(0)
        var matchedCount = 0

        for item in baseBasket {
            if let currentPrice = currentPrices[item.name], currentPrice > 0 {
                let baseExpenditure = item.basePrice * item.baseQuantity
                let currentExpenditure = currentPrice * item.baseQuantity

                matchedBaseCost += baseExpenditure
                matchedCurrentCost += currentExpenditure
                matchedCount += 1
            }
        }

        let coverage = matchedBaseCost / totalBaseCost
        let isReliable = (matchedCount >= 5 && coverage >= Decimal(string: "0.60")!)

        guard isReliable, matchedBaseCost > 0 else {
            return LaspeyresIndexResult(
                indexValue: nil,
                inflationRate: nil,
                matchedItemCount: matchedCount,
                basketCoverageRatio: coverage,
                isReliable: false
            )
        }

        let indexValue = (matchedCurrentCost / matchedBaseCost) * Decimal(100)
        let inflationRate = indexValue - Decimal(100)

        return LaspeyresIndexResult(
            indexValue: indexValue,
            inflationRate: inflationRate,
            matchedItemCount: matchedCount,
            basketCoverageRatio: coverage,
            isReliable: true
        )
    }

    /// Herfindahl-Hirschman Endeksi (HHI) ve Mağaza Çeşitliliği (Bulgu 17)
    /// HHI = sum (S_s)^2
    public static func calculateStoreHHI(expensesByStore: [String: Decimal]) -> (hhi: Decimal, description: String) {
        let totalExpense = expensesByStore.values.reduce(Decimal(0), +)
        guard totalExpense > 0 else {
            return (Decimal(0), "Veri Yok")
        }

        var hhi = Decimal(0)
        for (_, expense) in expensesByStore {
            let marketShare = (expense / totalExpense) * Decimal(100)
            hhi += marketShare * marketShare
        }

        let desc: String
        if hhi < Decimal(3000) {
            desc = "Yüksek Çeşitlilik (Fırsatçı)"
        } else if hhi <= Decimal(5500) {
            desc = "Orta Sadakat (Dengeli)"
        } else {
            desc = "Yüksek Sadakat (Tek Marketçi)"
        }

        return (hhi, desc)
    }
}
