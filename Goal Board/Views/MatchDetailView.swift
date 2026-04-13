//
//  MatchDetailView.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 27/08/2025.
//

import SwiftUI

struct MatchDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showAddGoalSheet: Bool = false
    @Bindable var match: Match
    
    private var team1Name: String { match.team1?.name ?? "Team 1" }
    private var team2Name: String { match.team2?.name ?? "Team 2" }
    
    var body: some View {
        VStack {
            Text("\(team1Name) \(match.team1Score) vs \(match.team2Score) \(team2Name)")
            //TODO: List of goals (on the left of the screen for team1, right for team2
            
            Spacer()
            Button("Log Goal"){
                showAddGoalSheet.toggle()
            }.buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $showAddGoalSheet, content: {
            LogGoalSheetView(match: match)
        })
        .navigationTitle("\(team1Name) vs \(team2Name)")
    }
}

struct LogGoalSheetView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var match: Match
    
    @State private var selectedTeam: Team?
    @State private var selectedScorer: Player?
    
    private var team1Name: String { match.team1?.name ?? "Team 1" }
    private var team2Name: String { match.team2?.name ?? "Team 2" }
    
    var body: some View {
        VStack {
            Text("Goal!")
                .font(.title)
            Picker(selection: $selectedTeam, label: Text("Team")) {
                Text(team1Name).tag(match.team1)
                Text(team2Name).tag(match.team2)
            }.pickerStyle(.palette)
            Spacer()
            if let selectedTeam = selectedTeam {
                Text(selectedTeam.name)
                Picker(selection: $selectedScorer, label: Text("Scorer")) {
                    ForEach(selectedTeam.players) { player in
                        Text(player.name).tag(player)
                    }
                }
            }
            
            Spacer()
        }
    }
}

#Preview {
    let team1 = Team(name: "Team 1")
    let team2 = Team(name: "Team 2")
    NavigationStack {
        MatchDetailView(match: Match(team1: team1, team2: team2))
    }
}

#Preview("Sheet"){
    let p1 = Player(name: "P1")
    let team1 = Team(name: "Team 1")
    team1.addPlayer(p1)
    let team2 = Team(name: "Team 2")
    return LogGoalSheetView(match: Match(team1: team1, team2: team2))
}
