//
//  AnalyticsAndInsightEngineTests.swift
//  Alisveris-fisTaramaTests
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Testing
import Foundation
@testable import Alisveris_fisTarama

struct AnalyticsAndInsightEngineTests {

    @Test func testLaspeyresInflationIndexCalculation() {
        // 5 temel ürünlü sepet
        let baseBasket: [(name: String, basePrice: Decimal, baseQuantity: Decimal)] = [
            ("sut", Decimal(30), Decimal(2)),     // 60 TL
            ("ekmek", Decimal(10), Decimal(5)),   // 50 TL
            ("yumurta", Decimal(60), Decimal(1)), // 60 TL
            ("peynir", Decimal(150), Decimal(1)), // 150 TL
            ("zeytin", Decimal(100), Decimal(1))  // 100 TL
        ] // Toplam baz maliyet = 420 TL

        // Cari fiyatlar: Süt 36 TL (%20 artış), Ekmek 12 TL (%20 artış), Yumurta 72 TL (%20 artış), Peynir 180 TL (%20 artış), Zeytin 120 TL (%20 artış)
        let currentPrices: [String: Decimal] = [
            "sut": Decimal(36),
            "ekmek": Decimal(12),
            "yumurta": Decimal(72),
            "peynir": Decimal(180),
            "zeytin": Decimal(120)
        ]

        let result = PersonalInflationEngine.calculateLaspeyresIndex(
            baseBasket: baseBasket,
            currentPrices: currentPrices
        )

        #expect(result.isReliable == true)
        #expect(result.matchedItemCount == 5)
        #expect(result.basketCoverageRatio == Decimal(1))
        #expect(result.indexValue == Decimal(120))
        #expect(result.inflationRate == Decimal(20))
    }

    @Test func testLaspeyresUnreliableWhenCoverageLow() {
        let baseBasket: [(name: String, basePrice: Decimal, baseQuantity: Decimal)] = [
            ("sut", Decimal(30), Decimal(2)),
            ("ekmek", Decimal(10), Decimal(5))
        ]

        let currentPrices: [String: Decimal] = [
            "sut": Decimal(35)
        ]

        let result = PersonalInflationEngine.calculateLaspeyresIndex(
            baseBasket: baseBasket,
            currentPrices: currentPrices
        )

        #expect(result.isReliable == false)
        #expect(result.indexValue == nil)
    }

    @Test func testStoreHHICalculations() {
        // İki market arasında %50 - %50 eşit dağılım -> HHI = 5000 (Orta Sadakat)
        let balancedStores: [String: Decimal] = [
            "BİM": Decimal(500),
            "MİGROS": Decimal(500)
        ]
        let (balancedHHI, balancedDesc) = PersonalInflationEngine.calculateStoreHHI(expensesByStore: balancedStores)
        #expect(balancedHHI == Decimal(5000))
        #expect(balancedDesc.contains("Orta"))

        // Tek bir markete bağımlılık -> HHI = 10000 (Yüksek Sadakat)
        let monopolyStore: [String: Decimal] = [
            "MİGROS": Decimal(1000)
        ]
        let (monoHHI, monoDesc) = PersonalInflationEngine.calculateStoreHHI(expensesByStore: monopolyStore)
        #expect(monoHHI == Decimal(10000))
        #expect(monoDesc.contains("Yüksek Sadakat"))

        // 4 markete eşit dağılım -> HHI = 2500 (Yüksek Çeşitlilik)
        let diversifiedStores: [String: Decimal] = [
            "BİM": Decimal(250),
            "MİGROS": Decimal(250),
            "ŞOK": Decimal(250),
            "A101": Decimal(250)
        ]
        let (divHHI, divDesc) = PersonalInflationEngine.calculateStoreHHI(expensesByStore: diversifiedStores)
        #expect(divHHI == Decimal(2500))
        #expect(divDesc.contains("Yüksek Çeşitlilik"))
    }

    @Test func testDeterministicInsightEnginePriceSurgeRule() async {
        let now = Date()
        let oldDate = Calendar.current.date(byAdding: .day, value: -20, to: now)!

        let records = [
            PriceRecordDTO(
                id: UUID(),
                productNameNormalized: "süt",
                storeId: UUID(),
                storeName: "MİGROS",
                date: oldDate,
                unitPriceNormalized: Decimal(30),
                rawUnitPrice: Decimal(30),
                unit: .liter,
                tripId: UUID(),
                itemId: UUID()
            ),
            PriceRecordDTO(
                id: UUID(),
                productNameNormalized: "süt",
                storeId: UUID(),
                storeName: "MİGROS",
                date: now,
                unitPriceNormalized: Decimal(45), // %50 artış (>= %15 barajı)
                rawUnitPrice: Decimal(45),
                unit: .liter,
                tripId: UUID(),
                itemId: UUID()
            )
        ]

        let context = InsightContext(
            recentPriceRecords: records,
            targetDate: now
        )

        let engine = DeterministicInsightEngine()
        let insights = await engine.generateInsights(context: context)

        #expect(!insights.isEmpty)
        #expect(insights.first?.category == .priceSurge)
        #expect(insights.first?.title.contains("Fiyat Artışı") == true)
    }
}
