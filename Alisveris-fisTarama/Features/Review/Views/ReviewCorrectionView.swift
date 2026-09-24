//
//  ReviewCorrectionView.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import SwiftUI

public struct ReviewCorrectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ReviewCorrectionViewModel
    public var onSaved: (() -> Void)?

    public init(viewModel: ReviewCorrectionViewModel, onSaved: (() -> Void)? = nil) {
        _viewModel = State(initialValue: viewModel)
        self.onSaved = onSaved
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Üst Panel: %42 Büyütülebilir Fiş Görseli
                ZoomableReceiptImageView(
                    image: viewModel.receiptImage,
                    activeBoundingBox: viewModel.activeBoundingBox
                )
                .frame(maxHeight: 280)

                // Canlı Sağlama Çubuğu
                LiveBalancingBarView(
                    storeName: viewModel.receiptDTO.storeName,
                    receiptDate: viewModel.receiptDTO.date,
                    grandTotal: viewModel.receiptDTO.totalAmount,
                    itemsSum: viewModel.calculatedItemsSum,
                    discountTotal: viewModel.receiptDTO.discountTotal
                )

                // Alt Panel: Ürün Kalemleri Listesi
                List {
                    Section(header: Text("Fiş Kalemleri (\(viewModel.receiptDTO.items.count))")) {
                        ForEach(Array(viewModel.receiptDTO.items.enumerated()), id: \.offset) { index, item in
                            ItemRowView(
                                item: item,
                                isSelected: viewModel.activeItemIndex == index,
                                onTap: { viewModel.selectItem(at: index) },
                                onNameChange: { newName in viewModel.updateItemName(at: index, newName: newName) },
                                onPriceChange: { newPrice in viewModel.updateItemPrice(at: index, newPrice: newPrice) }
                            )
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteItem(at: index)
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                        }

                        Button {
                            viewModel.addNewItem()
                        } label: {
                            Label("Yeni Satır Ekle", systemImage: "plus.circle.fill")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Fişi Doğrula")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") {
                        Task {
                            await viewModel.discard()
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            let success = await viewModel.saveReceipt()
                            if success {
                                onSaved?()
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isPersisting {
                            ProgressView()
                        } else {
                            Text("Kaydet")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(viewModel.isPersisting)
                }
            }
            .alert("Hata", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

private struct ItemRowView: View {
    let item: ParsedItemDTO
    let isSelected: Bool
    let onTap: () -> Void
    let onNameChange: (String) -> Void
    let onPriceChange: (Decimal) -> Void

    @State private var editedName: String = ""
    @State private var editedPrice: String = ""
    @State private var isEditing: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onTap) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .orange : .secondary)
            }
            .buttonStyle(.plain)

            if isEditing {
                TextField("Ürün Adı", text: $editedName)
                    .textFieldStyle(.roundedBorder)

                TextField("Fiyat", text: $editedPrice)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .frame(width: 80)

                Button {
                    if let price = CurrencyNormalizer.parseDecimal(from: editedPrice) {
                        onPriceChange(price)
                    }
                    onNameChange(editedName)
                    isEditing = false
                } label: {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.normalizedName)
                        .font(.body)
                        .fontWeight(isSelected ? .semibold : .regular)

                    Text("\(CurrencyNormalizer.format(item.quantity)) \(item.unit.localizedTitle)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(CurrencyNormalizer.format(item.totalPrice))
                    .font(.body)
                    .fontWeight(.semibold)

                Button {
                    editedName = item.normalizedName
                    editedPrice = "\(item.totalPrice)"
                    isEditing = true
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}
