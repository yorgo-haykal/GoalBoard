//
//  MatchListView.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 03/08/2025.
//

import SwiftUI
import SwiftData

struct MatchListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var matches: [Match]
    
    @State private var isAddingMatch: Bool = false
    
    var body: some View {
        List {
            ForEach(matches) { match in
                HStack {
                    Text("\(match.team1.name) vs \(match.team2.name)")
                    Text(match.date, style: .date)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAddingMatch.toggle()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddingMatch, content: {
            AddMatchSheetView(isPresented: $isAddingMatch)
        })
        .navigationTitle("Matches")
    }
}

struct AddMatchSheetView: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    @Query private var teams: [Team]
    
    @State private var selectedTeam1: Team?
    @State private var selectedTeam2: Team?
    @State private var matchDate: Date = Date()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Add Match")
                .font(.title)
            
            Spacer()
            Form {
                HStack {
                    Picker("Team 1", selection: $selectedTeam1) {
                        Text("Select a team").tag(Optional<Team>(nil))
                        ForEach(teams) { team in
                            if team != selectedTeam2 {
                                Text(team.name).tag(Optional(team))
                            }
                        }
                    }.pickerStyle(.menu)
                }
                
                HStack {
                    Picker("Team 2", selection: $selectedTeam2) {
                        Text("Select a team").tag(Optional<Team>(nil))
                        ForEach(teams) { team in
                            if team != selectedTeam1 {
                                Text(team.name).tag(Optional(team))
                            }
                        }
                    }.pickerStyle(.menu)
                }
                
                DatePicker("Date", selection: $matchDate, displayedComponents: .date)
                
                HStack {
                    Spacer()
                    Button("Add") {
                        guard let team1 = selectedTeam1,
                              let team2 = selectedTeam2
                        else { return }
                        
                        let match = Match(date: matchDate, team1: team1, team2: team2)
                        modelContext.insert(match)
                        try? modelContext.save()
                        isPresented.toggle()
                    }.disabled(selectedTeam1 == nil || selectedTeam2 == nil)
                    Spacer()
                }
            }
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        MatchListView()
    }.modelContainer(for: [Match.self], inMemory: true)
}

#Preview ("Sheet"){
    @Previewable @State var isPresented: Bool = true
    AddMatchSheetView(isPresented: $isPresented)
}
