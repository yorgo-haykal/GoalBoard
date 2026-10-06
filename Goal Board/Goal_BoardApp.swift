//
//  Goal_BoardApp.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 01/08/2025.
//

import SwiftUI
import SwiftData

@main
struct Goal_BoardApp: App {
    let container: ModelContainer
    let connectivity: PhoneConnectivity

    init() {
        do {
            container = try ModelContainer(for: Player.self, Team.self, Match.self)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        connectivity = PhoneConnectivity(container: container)
        connectivity.activate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
