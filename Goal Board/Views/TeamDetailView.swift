//
//  TeamDetailView.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 02/08/2025.
//

import SwiftUI
import SwiftData

struct TeamDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var players: [Player]

    @State private var isEditing: Bool = false
    @State private var newTeamName: String = ""

    @Bindable var team: Team

    // Players in the database who aren't already on this team
    private var addablePlayers: [Player] {
        players.filter { p in !team.players.contains { $0.id == p.id } }
    }

    private func add(_ player: Player) {
        team.addPlayer(player)
        player.teams.append(team)
        try? modelContext.save()
    }

    var body: some View {
        List {
            if isEditing {
                Section("Name") {
                    TextField("Name", text: $newTeamName)
                }
            }

            Section("Record") {
                HStack {
                    Label("Matches played", systemImage: "soccerball")
                    Spacer()
                    Text("\(team.matches.count)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Label("W–D–L", systemImage: "trophy")
                    Spacer()
                    Text("\(team.wins)–\(team.draws)–\(team.losses)")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Players") {
                if !addablePlayers.isEmpty {
                    Menu {
                        ForEach(addablePlayers) { player in
                            Button(player.name) { add(player) }
                        }
                    } label: {
                        Label("Add player", systemImage: "person.badge.plus")
                    }
                }

                if team.players.isEmpty {
                    Text("No players yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(team.players) { player in
                        NavigationLink(value: player) {
                            Text(player.name)
                        }
                    }
                    .onDelete { indexes in
                        for index in indexes {
                            team.removePlayer(team.players[index])
                            try? modelContext.save()
                        }
                    }
                }
            }

            Section("Match History") {
                if team.matches.isEmpty {
                    Text("No matches played")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(team.matches) { match in
                        NavigationLink(value: match) {
                            HStack {
                                Text(match.team1?.name ?? "Team 1")
                                Spacer()
                                Text("\(match.team1Score) - \(match.team2Score)")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(match.team2?.name ?? "Team 2")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(team.name)
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        newTeamName = ""
                        isEditing = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        team.name = newTeamName
                        try? modelContext.save()
                        isEditing = false
                    }
                    .disabled(newTeamName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        newTeamName = team.name
                        isEditing = true
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TeamDetailView(team: Team(name: "HN"))
    }.modelContainer(for: [Team.self, Player.self])
}
