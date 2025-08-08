//
//  TeamListView.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 01/08/2025.
//

import SwiftUI
import SwiftData

struct TeamListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var teams: [Team]
    @State private var teamCount: Int = 0
    
    var sortedTeams: [Team] {
        teams.sorted() { $0.name < $1.name }
    }
    
    var body: some View {
            List{
                ForEach(sortedTeams) { team in
                    NavigationLink(value: team){
                        Text(team.name)
                    }
                        
                }
                .onDelete { indexes in
                    for index in indexes {
                        deleteTeam(teams[index])
                    }
                }
            }
            .navigationTitle("Teams")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addTeam()
                    } label: {
                        Image(systemName: "plus")
                    }

                }
            }
    }
    
    func addTeam() {
        teamCount += 1
        let team = Team(name: "Team \(teamCount)")
        modelContext.insert(team)
    }
    
    func deleteTeam(_ team: Team) {
        teamCount -= 1
        modelContext.delete(team)
    }
}

#Preview {
    NavigationStack {
        TeamListView()
            .navigationDestination(for: Team.self, destination: { team in
                TeamDetailView(team: team)
            })
    }
    .modelContainer(for: Team.self, inMemory: true)
}
