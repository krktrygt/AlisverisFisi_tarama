//
//  InsightModels.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Foundation

public enum InsightCategory: String, Codable, Sendable {
    case priceSurge = "PRICE_SURGE"
    case frequencyAnomaly = "FREQUENCY_ANOMALY"
    case budgetWarning = "BUDGET_WARNING"
    case storeArbitrage = "STORE_ARBITRAGE"
    case categoryDrift = "CATEGORY_DRIFT"
}

public struct InsightCandidate: Identifiable, Sendable {
    public let id: UUID
    public let category: InsightCategory
    public let priority: Double // 0.0 .. 1.0 (Yüksekten düşüğe öncelik)
    public let title: String
    public let message: String
    public let relatedProductId: UUID?
    public let targetEntityId: String? // Kategori UUID veya Mağaza Adı
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        category: InsightCategory,
        priority: Double,
        title: String,
        message: String,
        relatedProductId: UUID? = nil,
        targetEntityId: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.priority = priority
        self.title = title
        self.message = message
        self.relatedProductId = relatedProductId
        self.targetEntityId = targetEntityId
        self.createdAt = createdAt
    }
}

public struct InsightContext: Sendable {
    public let recentPriceRecords: [PriceRecordDTO]
    public let monthlyCategoryExpenses: [UUID: Decimal]
    public let historicalCategoryMedians: [UUID: Decimal]
    public let currentMonthMTDExpense: Decimal
    public let projectedMonthExpense: Decimal
    public let targetDate: Date
    public let threeMonthAverageExpense: Decimal
    public let userMonthlyBudget: Decimal?

    public init(
        recentPriceRecords: [PriceRecordDTO],
        monthlyCategoryExpenses: [UUID: Decimal] = [:],
        historicalCategoryMedians: [UUID: Decimal] = [:],
        currentMonthMTDExpense: Decimal = Decimal(0),
        projectedMonthExpense: Decimal = Decimal(0),
        targetDate: Date = Date(),
        threeMonthAverageExpense: Decimal = Decimal(0),
        userMonthlyBudget: Decimal? = nil
    ) {
        self.recentPriceRecords = recentPriceRecords
        self.monthlyCategoryExpenses = monthlyCategoryExpenses
        self.historicalCategoryMedians = historicalCategoryMedians
        self.currentMonthMTDExpense = currentMonthMTDExpense
        self.projectedMonthExpense = projectedMonthExpense
        self.targetDate = targetDate
        self.threeMonthAverageExpense = threeMonthAverageExpense
        self.userMonthlyBudget = userMonthlyBudget
    }
}
