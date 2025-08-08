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
    
    @State private var showAddPlayerSheet: Bool = false
    @State private var playerToAdd: Player?
    
    @Bindable var team: Team
    
    var body: some View {
        VStack (alignment: .leading) {
            if showAddPlayerSheet {
                HStack {
                    Picker("Select player", selection: $playerToAdd) {
                        Text("Select a player").tag(Optional<Player>(nil))
                        ForEach(players) { player in
                            Text(player.name).tag(Optional(player))
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Button("Add") {
                        if let player = playerToAdd{
                            team.addPlayer(player)
                            player.teams.append(team)
                            playerToAdd = nil
                            showAddPlayerSheet.toggle()
                            try? modelContext.save()
                        }
                    }
                    .disabled(playerToAdd == nil)
                }
            }
                
            Text("Players:")
            List {
                ForEach(team.players) { player in
                    NavigationLink(player.name) {
                        PlayerDetailView(player: player)
                    }
                }
            }
            
            Text("Matches played: 0")
            
            Text("Record: \(team.wins)-\(team.draws)-\(team.losses)")
                .navigationTitle(team.name)
            Divider()
            Text("Match History:")
            Spacer()
        }
        .toolbar(content: {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add Player") {
                    showAddPlayerSheet.toggle()
                }
            }
        })
        .padding()
    }
}

#Preview {
    NavigationStack {
        TeamDetailView(team: Team(name: "HN"))
    }.modelContainer(for: [Team.self, Player.self])
}
