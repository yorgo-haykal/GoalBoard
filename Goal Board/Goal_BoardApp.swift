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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Player.self)
    }
}
