//
//  WatchGoalBoardApp.swift
//  WatchGoalBoard Watch App
//
//  Created by Yorgo Haykal on 05/10/2026.
//

import SwiftUI

@main
struct WatchGoalBoardApp: App {
    @State private var store: MatchStore
    private let connectivity: WatchConnectivityManager

    init() {
        let connectivity = WatchConnectivityManager()
        let store = MatchStore(send: connectivity.send)
        connectivity.onRosterReceived = store.updateRoster
        connectivity.activate()

        self.connectivity = connectivity
        _store = State(initialValue: store)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
