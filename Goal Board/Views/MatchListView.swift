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
    @Query(sort: \Match.date, order: .reverse) private var matches: [Match]
    
    @State private var isAddingMatch: Bool = false
    @State private var showingConfirmQuickMatch: Bool = false
    @State private var quickMatch: Match?

    var body: some View {
        List {
            ForEach(matches) { match in
                NavigationLink(value: match) {
                    HStack {
                        if (match.status != .Scheduled){
                            Text(match.team1?.name ?? "Team 1")
                                        .bold(match.result == .Team1)
                                    Text("\(match.team1Score) - \(match.team2Score)")
                                    Text(match.team2?.name ?? "Team 2")
                                        .bold(match.result == .Team2)
                        } else {
                            Text("\(match.team1?.name ?? "Team 1") vs \(match.team2?.name ?? "Team 2")")
                        }
                    
                        Spacer()
                        Text(match.status == .InProgress ? "Live" : "")
                            .font(.caption)
                            .foregroundStyle(.red)
                        Text(match.date, style: .date)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete { indexes in
                for index in indexes {
                    let match = matches[index]
                    // Clean up temporary teams from quick matches
                    if let t1 = match.team1, t1.isTemporary { modelContext.delete(t1) }
                    if let t2 = match.team2, t2.isTemporary { modelContext.delete(t2) }
                    modelContext.delete(match)
                }
            }
            
        }
        .navigationDestination(item: $quickMatch) { match in
            MatchDetailView(match: match)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Quick Match") {
                    showingConfirmQuickMatch = true
                }
                .alert("Start Quick Match?", isPresented: $showingConfirmQuickMatch) {
                    Button("Cancel", role: .cancel) {}
                    Button("Start") {
                        let match = Match()
                        modelContext.insert(match)
                        quickMatch = match
                    }
                }
            }
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
    @Query(filter: #Predicate<Team> { $0.isTemporary == false }) private var teams: [Team]
    
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
