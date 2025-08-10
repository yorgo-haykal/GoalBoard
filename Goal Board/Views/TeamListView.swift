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
                        deleteTeam(sortedTeams[index])
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
        let team = Team(name: "New Team")
        modelContext.insert(team)
    }
    
    func deleteTeam(_ team: Team) {
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
