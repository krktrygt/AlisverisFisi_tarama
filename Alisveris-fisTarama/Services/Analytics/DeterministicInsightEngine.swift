//
//  DeterministicInsightEngine.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import Foundation

public actor DeterministicInsightEngine {
    private let rules: [any InsightRule]
    private var emittedInsightTimestamps: [String: Date] = [:]

    public init(rules: [any InsightRule] = [
        PriceSurgeRule(),
        BudgetVelocityWarningRule(),
        StorePriceArbitrageRule()
    ]) {
        self.rules = rules
    }

    public func generateInsights(context: InsightContext, maxResults: Int = 3) async -> [InsightCandidate] {
        var allCandidates: [InsightCandidate] = []

        for rule in rules {
            let candidates = await rule.evaluate(context: context)
            allCandidates.append(contentsOf: candidates)
        }

        // Granüler 7 günlük cooldown / debounce filtresi (Bulgu 22)
        let filtered = allCandidates.filter { candidate in
            let key = "\(candidate.category.rawValue)_\(candidate.targetEntityId ?? candidate.relatedProductId?.uuidString ?? "global")"
            if let lastEmitted = emittedInsightTimestamps[key] {
                let daysSince = Calendar.current.dateComponents([.day], from: lastEmitted, to: context.targetDate).day ?? 0
                if daysSince < 7 { return false }
            }
            return true
        }

        let sorted = filtered.sorted { $0.priority > $1.priority }
        let topResults = Array(sorted.prefix(maxResults))

        for item in topResults {
            let key = "\(item.category.rawValue)_\(item.targetEntityId ?? item.relatedProductId?.uuidString ?? "global")"
            emittedInsightTimestamps[key] = context.targetDate
        }

        return topResults
    }
}
