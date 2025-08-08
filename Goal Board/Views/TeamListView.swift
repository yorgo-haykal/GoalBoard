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
    
    var body: some View {
            List{
                ForEach(teams) { team in
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
    }
    .modelContainer(for: Team.self, inMemory: true)
}
