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

    @State private var showAddPlayer: Bool = false
    @State private var playerToAdd: Player?

    @State private var isEditing: Bool = false
    @State private var newTeamName: String = ""

    @Bindable var team: Team

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
                if showAddPlayer {
                    HStack {
                        Picker("Add player", selection: $playerToAdd) {
                            Text("Select a player").tag(Optional<Player>(nil))
                            ForEach(players) { player in
                                Text(player.name).tag(Optional(player))
                            }
                        }
                        Button("Add") {
                            if let player = playerToAdd {
                                team.addPlayer(player)
                                player.teams.append(team)
                                playerToAdd = nil
                                showAddPlayer = false
                                try? modelContext.save()
                            }
                        }
                        .disabled(playerToAdd == nil)
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
                    Button {
                        showAddPlayer.toggle()
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
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
