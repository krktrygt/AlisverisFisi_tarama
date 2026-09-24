//
//  TripDetailView.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import SwiftUI
import SwiftData

public struct TripDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable public var trip: ShoppingTrip
    @State private var receiptImage: UIImage?
    @State private var isLoadingImage = true
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false

    public init(trip: ShoppingTrip) {
        self.trip = trip
    }

    public var body: some View {
        List {
            // Fiş Görseli Paneli
            Section {
                if let image = receiptImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if isLoadingImage {
                    HStack {
                        Spacer()
                        ProgressView("Görsel yükleniyor...")
                        Spacer()
                    }
                    .padding()
                } else {
                    HStack {
                        Spacer()
                        Text("Fiş görseli mevcut değil")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }

            // Özet Bilgiler
            Section(header: Text("Fiş Detayları")) {
                LabeledContent("Market", value: trip.store?.name ?? "Bilinmiyor")
                LabeledContent("Tarih", value: trip.date.formatted(date: .long, time: .shortened))
                if let receiptNo = trip.receiptNumber {
                    LabeledContent("Fiş No", value: receiptNo)
                }
                LabeledContent("Ödeme Şekli", value: trip.paymentMethod.rawValue.capitalized)
                LabeledContent("Toplam Tutar", value: trip.totalAmount.formattedAsCurrency())
                    .fontWeight(.bold)
            }

            // Alışveriş Kalemleri
            Section(header: Text("Ürünler (\(trip.items.count))")) {
                ForEach(trip.items) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.rawName)
                                .font(.body)
                            Text("\(CurrencyNormalizer.format(item.quantity)) \(item.unit.localizedTitle)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(item.totalPrice.formattedAsCurrency())
                            .font(.body)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .navigationTitle(trip.store?.name ?? "Fiş Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Düzenle", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Alışverişi Sil", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            TripEditView(trip: trip)
        }
        .confirmationDialog(
            "Bu alışverişi silmek istediğinize emin misiniz?",
            isPresented: $showDeleteAlert,
            titleVisibility: .visible
        ) {
            Button("Alışverişi Sil", role: .destructive) {
                deleteThisTrip()
            }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Bu işlem geri alınamaz.")
        }
        .task {
            if let relativePath = trip.imageRelativePath {
                receiptImage = ReceiptImageDiskManager.shared.loadReceiptImage(relativePath: relativePath)
            }
            isLoadingImage = false
        }
    }

    private func deleteThisTrip() {
        let tripUUID = trip.id
        // PriceRecord'ları temizle
        let priceRecordsPredicate = #Predicate<PriceRecord> { record in
            record.tripId == tripUUID
        }
        if let records = try? modelContext.fetch(FetchDescriptor<PriceRecord>(predicate: priceRecordsPredicate)) {
            for record in records {
                modelContext.delete(record)
            }
        }

        // Görseli diskten temizle
        if let relPath = trip.imageRelativePath {
            try? ReceiptImageDiskManager.shared.deleteImage(relativePath: relPath)
        }

        modelContext.delete(trip)
        try? modelContext.save()
        dismiss()
    }
}
