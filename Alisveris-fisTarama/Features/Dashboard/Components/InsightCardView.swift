//
//  InsightCardView.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import SwiftUI

public struct InsightCardView: View {
    public let insight: InsightCandidate

    private var iconName: String {
        switch insight.category {
        case .priceSurge: return "exclamationmark.triangle.fill"
        case .frequencyAnomaly: return "clock.arrow.circlepath"
        case .budgetWarning: return "chart.line.uptrend.xyaxis"
        case .storeArbitrage: return "lightbulb.fill"
        case .categoryDrift: return "arrow.left.arrow.right"
        }
    }

    private var iconColor: Color {
        switch insight.category {
        case .priceSurge, .budgetWarning: return .orange
        case .storeArbitrage: return .green
        case .frequencyAnomaly, .categoryDrift: return .blue
        }
    }

    public init(insight: InsightCandidate) {
        self.insight = insight
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(insight.message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}
