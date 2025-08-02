//
//  PlayerListView.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 01/08/2025.
//

import SwiftUI
import SwiftData

struct PlayerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var players: [Player]
    
    @State var isAddingPlayer: Bool = false
    @State var newPlayerName: String = ""
    
    var body: some View {
        
            if isAddingPlayer {
                HStack {
                    TextField("Enter player name", text: $newPlayerName)
                    Button("Add Player") {
                        addPlayer(newPlayerName)
                        newPlayerName = ""
                        isAddingPlayer.toggle()
                    }
                }
                .padding()
            }
            List {
                ForEach(players) { player in
                    NavigationLink (value: player) {
                        HStack {
                            Text(player.name)
                            Spacer()
                            Text("Goals: \(player.goalCount)")
                        }
                    }
                }
                .onDelete { indexes in
                    for index in indexes {
                        deletePlayer(players[index])
                    }
                }
            }
            .navigationTitle("Players")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isAddingPlayer.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }

                }
            }
            .navigationDestination(for: Player.self) { player in
                PlayerDetailView(player: player)
            }
        
    }
    
    func addPlayer(_ name: String) {
        let player = Player(name: name)
        modelContext.insert(player)
    }
    
    func deletePlayer(_ player: Player) {
        modelContext.delete(player)
    }
}

#Preview {
    NavigationStack {
            PlayerListView()
    }
    .modelContainer(for: Player.self, inMemory: true)
}
