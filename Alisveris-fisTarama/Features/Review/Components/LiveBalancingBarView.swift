//
//  LiveBalancingBarView.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import SwiftUI

public struct LiveBalancingBarView: View {
    public let storeName: String
    public let receiptDate: Date
    public let grandTotal: Decimal
    public let itemsSum: Decimal
    public let discountTotal: Decimal

    private var delta: Decimal {
        abs(itemsSum - discountTotal - grandTotal)
    }

    private var isBalanced: Bool {
        delta <= Decimal(string: "0.02")!
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: receiptDate)
    }

    public init(
        storeName: String,
        receiptDate: Date,
        grandTotal: Decimal,
        itemsSum: Decimal,
        discountTotal: Decimal = Decimal(0)
    ) {
        self.storeName = storeName
        self.receiptDate = receiptDate
        self.grandTotal = grandTotal
        self.itemsSum = itemsSum
        self.discountTotal = discountTotal
    }

    public var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(storeName) • \(formattedDate)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text("Fiş: \(CurrencyNormalizer.format(grandTotal)) | Kalemler: \(CurrencyNormalizer.format(itemsSum - discountTotal))")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Spacer()

            if isBalanced {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Dengeli")
                        .font(.footnote)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.12))
                .clipShape(Capsule())
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Fark: \(CurrencyNormalizer.format(delta))")
                        .font(.footnote)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(delta <= Decimal(string: "1.00")! ? .orange : .red)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background((delta <= Decimal(string: "1.00")! ? Color.orange : Color.red).opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}
