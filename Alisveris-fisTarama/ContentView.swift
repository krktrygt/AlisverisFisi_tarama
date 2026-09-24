//
//  ContentView.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 21.09.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            HomeDashboardView()
                .tabItem {
                    Label("Özet", systemImage: "house.fill")
                }

            NavigationStack {
                TripHistoryView()
            }
            .tabItem {
                Label("Geçmiş", systemImage: "clock.arrow.circlepath")
            }
        }
    }
}
