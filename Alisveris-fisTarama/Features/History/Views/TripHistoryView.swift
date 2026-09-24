//
//  TripHistoryView.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 24.09.2026.
//

import SwiftUI
import SwiftData

public struct TripHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShoppingTrip.date, order: .reverse) private var trips: [ShoppingTrip]
    @State private var searchText: String = ""
    @State private var tripToDelete: ShoppingTrip?
    @State private var showDeleteConfirmation = false

    private var filteredTrips: [ShoppingTrip] {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return trips
        }
        let query = trimmed.lowercased()
        return trips.filter { trip in
            let storeMatch = trip.store?.name.lowercased().contains(query) ?? false
            let itemMatch = trip.items.contains(where: { item in
                item.rawName.lowercased().contains(query) || item.normalizedName.lowercased().contains(query)
            })
            return storeMatch || itemMatch
        }
    }

    public init() {}

    public var body: some View {
        Group {
            if filteredTrips.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "Henüz Alışveriş Yok" : "Sonuç Bulunamadı",
                    systemImage: searchText.isEmpty ? "basket" : "magnifyingglass",
                    description: Text(searchText.isEmpty ? "Taradığınız fişler geçmişinizde burada listelenecektir." : "Farklı bir arama terimi deneyin.")
                )
            } else {
                List {
                    ForEach(filteredTrips) { trip in
                        NavigationLink(destination: TripDetailView(trip: trip)) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(trip.store?.name ?? "Bilinmeyen Market")
                                        .font(.headline)
                                    Spacer()
                                    Text(trip.totalAmount.formattedAsCurrency())
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                }

                                HStack {
                                    Text(trip.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(trip.items.count) Kalem")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                tripToDelete = trip
                                showDeleteConfirmation = true
                            } label: {
                                Label("Sil", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: confirmDeleteOffsets)
                }
                .listStyle(.insetGrouped)
            }
        }
        .searchable(text: $searchText, prompt: "Market veya ürün ara...")
        .navigationTitle("Geçmiş Fişler")
        .confirmationDialog(
            "Bu alışveriş kaydını silmek istediğinize emin misiniz?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Alışverişi Sil", role: .destructive) {
                if let trip = tripToDelete {
                    deleteTrip(trip)
                }
            }
            Button("Vazgeç", role: .cancel) {
                tripToDelete = nil
            }
        } message: {
            Text("Bu işlem geri alınamaz. Fişe ait tüm ürünler ve fiyat kayıtları da silinecektir.")
        }
    }

    private func confirmDeleteOffsets(at offsets: IndexSet) {
        if let index = offsets.first {
            tripToDelete = filteredTrips[index]
            showDeleteConfirmation = true
        }
    }

    private func deleteTrip(_ trip: ShoppingTrip) {
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

        // Trip sil (ShoppingItem'lar cascade silinir)
        modelContext.delete(trip)
        try? modelContext.save()
        tripToDelete = nil
    }
}
