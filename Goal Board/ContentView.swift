//
//  ContentView.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 01/08/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Players", systemImage: "figure.indoor.soccer", value: 1) {
                NavigationStack {
                    PlayerListView()
                        .navigationDestination(for: Player.self) { player in
                            PlayerDetailView(player: player)
                        }
                        .navigationDestination(for: Team.self) { team in
                            TeamDetailView(team: team)
                        }
                }
            }
            
            Tab("Teams", systemImage:"person.3.fill", value: 2){
                NavigationStack {
                    TeamListView()
                        .navigationDestination(for: Team.self) { team in
                            TeamDetailView(team: team)
                        }
                        .navigationDestination(for: Player.self) { player in
                            PlayerDetailView(player: player)
                        }
                }
            }
            
            Tab("Matches", systemImage: "soccerball", value: 3){
                NavigationStack {
                    MatchListView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Player.self, Team.self, Match.self], inMemory: true)
}
