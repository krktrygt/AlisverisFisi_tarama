//
//  ContentView.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 21.09.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var container: AppContainer
    @Query(sort: \ShoppingTrip.date, order: .reverse) private var trips: [ShoppingTrip]

    var body: some View {
        NavigationStack {
            Group {
                if trips.isEmpty {
                    ContentUnavailableView(
                        "Henüz Fiş Eklenmedi",
                        systemImage: "doc.text.viewfinder",
                        description: Text("Fiş taramak için kamera butonunu kullanabilirsiniz.")
                    )
                } else {
                    List(trips) { trip in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(trip.store?.name ?? "Bilinmeyen Market")
                                    .font(.headline)
                                Spacer()
                                Text(trip.totalAmount.formattedAsCurrency())
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                            }
                            HStack {
                                Text(trip.date, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(trip.items.count) Kalem")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("CepSepeti")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppContainer(inMemory: true))
}
