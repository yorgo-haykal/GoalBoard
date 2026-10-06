//
//  ScorerSheetView.swift
//  WatchGoalBoard Watch App
//
//  Created by Yorgo Haykal on 06/10/2026.
//

import SwiftUI
import WatchKit

// Shown after tapping a team's score. Picking a player or "No scorer" logs the goal,
// closing the sheet cancels it (handy for accidental taps).
struct ScorerSheetView: View {
    @Environment(MatchStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let pendingGoal: LiveMatchView.PendingGoal
    let teamName: String

    @State private var isPenalty = false

    var body: some View {
        List {
            Toggle("Penalty", isOn: $isPenalty)

            Button("No scorer") {
                log(nil)
            }
            .foregroundStyle(.green)

            let players = store.players(for: pendingGoal.side)
            if !players.isEmpty {
                Section("Scorer") {
                    ForEach(players) { player in
                        Button(player.name) {
                            log(player)
                        }
                    }
                }
            }
        }
        .navigationTitle("Goal \(teamName)")
    }

    private func log(_ player: RosterSnapshot.PlayerInfo?) {
        store.logGoal(
            side: pendingGoal.side,
            elapsedSeconds: pendingGoal.elapsedSeconds,
            player: player,
            goalType: isPenalty ? .Penalty : .Regular
        )
        WKInterfaceDevice.current().play(.success)
        dismiss()
    }
}
