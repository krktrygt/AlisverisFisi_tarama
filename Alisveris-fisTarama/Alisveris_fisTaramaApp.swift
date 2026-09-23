//
//  Alisveris_fisTaramaApp.swift
//  Alisveris-fisTarama
//
//  Created by Korkut Eryiğit on 21.09.2026.
//

import SwiftUI
import SwiftData

@main
struct Alisveris_fisTaramaApp: App {
    @StateObject private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(container)
        }
        .modelContainer(container.modelContainer)
    }
}
