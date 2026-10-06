//
//  ContentView.swift
//  WatchGoalBoard Watch App
//
//  Created by Yorgo Haykal on 11/06/2026.
//

import SwiftUI

struct ContentView: View {
    @Environment(MatchStore.self) private var store

    var body: some View {
        if let match = store.activeMatch {
            // The stack is needed for the live match toolbar to show
            NavigationStack {
                LiveMatchView(match: match)
            }
        } else {
            HomeView()
        }
    }
}

struct HomeView: View {
    @Environment(MatchStore.self) private var store
    @State private var pendingStart: PendingStart?

    enum PendingStart: Identifiable {
        case quick
        case scheduled(RosterSnapshot.ScheduledMatchInfo)

        var id: String {
            switch self {
            case .quick: "quick"
            case .scheduled(let match): match.id.uuidString
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Button {
                    pendingStart = .quick
                } label: {
                    Label("Quick Match", systemImage: "soccerball")
                }
                .listItemTint(.green)

                Section("Scheduled") {
                    if store.scheduledMatches.isEmpty {
                        Text("Schedule matches on your iPhone")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(store.scheduledMatches) { match in
                        Button {
                            pendingStart = .scheduled(match)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(title(for: match))
                                    .font(.headline)
                                Text(match.date, style: .date)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Goal Board")
            .confirmationDialog(dialogTitle, isPresented: isConfirming, presenting: pendingStart) { start in
                Button("Start") {
                    switch start {
                    case .quick: store.startQuickMatch()
                    case .scheduled(let match): store.start(match)
                    }
                }
            }
        }
    }

    private var isConfirming: Binding<Bool> {
        Binding(get: { pendingStart != nil }, set: { if !$0 { pendingStart = nil } })
    }

    private var dialogTitle: String {
        switch pendingStart {
        case .scheduled(let match): "Start \(title(for: match))?"
        default: "Start a quick match?"
        }
    }

    private func title(for match: RosterSnapshot.ScheduledMatchInfo) -> String {
        let team1 = store.roster.team(match.team1ID)?.name ?? "Team 1"
        let team2 = store.roster.team(match.team2ID)?.name ?? "Team 2"
        return "\(team1) vs \(team2)"
    }
}

#Preview {
    ContentView()
        .environment(MatchStore(directory: .temporaryDirectory.appending(path: "preview"), send: { _ in }))
}
