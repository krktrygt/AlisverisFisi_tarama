//
//  TripEditView.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import SwiftUI
import SwiftData

public struct TripEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable public var trip: ShoppingTrip

    @State private var storeName: String
    @State private var tripDate: Date
    @State private var receiptNumber: String
    @State private var selectedPaymentMethod: PaymentMethod
    @State private var totalAmountText: String

    public init(trip: ShoppingTrip) {
        self.trip = trip
        _storeName = State(initialValue: trip.store?.name ?? "")
        _tripDate = State(initialValue: trip.date)
        _receiptNumber = State(initialValue: trip.receiptNumber ?? "")
        _selectedPaymentMethod = State(initialValue: trip.paymentMethod)
        _totalAmountText = State(initialValue: "\(trip.totalAmount)")
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Fiş Bilgileri")) {
                    TextField("Market Adı", text: $storeName)

                    DatePicker("Tarih", selection: $tripDate, displayedComponents: [.date, .hourAndMinute])

                    TextField("Fiş / Belge No", text: $receiptNumber)

                    Picker("Ödeme Yöntemi", selection: $selectedPaymentMethod) {
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            Text(method.rawValue.capitalized).tag(method)
                        }
                    }

                    HStack {
                        Text("Toplam Tutar")
                        Spacer()
                        TextField("0.00", text: $totalAmountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section(header: Text("Alışveriş Kalemleri (\(trip.items.count))")) {
                    ForEach(trip.items) { item in
                        ItemRowEditView(item: item) {
                            recalculateTotals()
                        }
                    }
                    .onDelete(perform: deleteItem)
                }
            }
            .navigationTitle("Alışverişi Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
        }
    }

    private func deleteItem(at offsets: IndexSet) {
        for index in offsets {
            let item = trip.items[index]
            modelContext.delete(item)
        }
        trip.items.remove(atOffsets: offsets)
        recalculateTotals()
    }

    private func recalculateTotals() {
        let sum = trip.items.reduce(Decimal(0)) { $0 + $1.totalPrice }
        trip.subtotal = sum
        if totalAmountText.trimmingCharacters(in: .whitespaces).isEmpty || totalAmountText == "0" {
            trip.totalAmount = sum
            totalAmountText = "\(sum)"
        }
    }

    private func saveChanges() {
        let trimmedStore = storeName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedStore.isEmpty {
            if let existingStore = trip.store {
                existingStore.name = trimmedStore
                existingStore.normalizedName = trimmedStore.lowercased()
            } else {
                let newStore = Store(name: trimmedStore, normalizedName: trimmedStore.lowercased())
                modelContext.insert(newStore)
                trip.store = newStore
            }
        }

        trip.date = tripDate
        trip.receiptNumber = receiptNumber.trimmingCharacters(in: .whitespaces).isEmpty ? nil : receiptNumber.trimmingCharacters(in: .whitespaces)
        trip.paymentMethod = selectedPaymentMethod

        if let customTotal = CurrencyNormalizer.parseDecimal(from: totalAmountText) {
            trip.totalAmount = customTotal
        } else {
            trip.totalAmount = trip.items.reduce(Decimal(0)) { $0 + $1.totalPrice }
        }

        trip.updatedAt = Date()
        try? modelContext.save()
    }
}

private struct ItemRowEditView: View {
    @Bindable var item: ShoppingItem
    var onPriceChange: () -> Void

    @State private var priceText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Ürün Adı", text: $item.rawName)
                .font(.body)

            HStack {
                Text("\(CurrencyNormalizer.format(item.quantity)) \(item.unit.localizedTitle)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Menu {
                    ForEach(StandardCategory.allCases, id: \.self) { cat in
                        Button {
                            item.categoryRawCode = cat.rawCode
                            item.categoryName = cat.displayName
                            item.categoryEmoji = cat.emoji
                        } label: {
                            Label("\(cat.emoji) \(cat.displayName)", systemImage: cat.iconName)
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Text(item.categoryEmoji ?? item.category?.emoji ?? "🛍️")
                        Text(item.categoryName ?? item.category?.name ?? "Kategori")
                            .font(.caption2)
                            .lineLimit(1)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 8))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Spacer()
                TextField("Tutar", text: $priceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 90)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: priceText) { _, newValue in
                        if let dec = CurrencyNormalizer.parseDecimal(from: newValue) {
                            item.totalPrice = dec
                            if item.quantity > 0 {
                                item.unitPrice = dec / item.quantity
                            }
                            onPriceChange()
                        }
                    }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            priceText = "\(item.totalPrice)"
        }
    }
}
