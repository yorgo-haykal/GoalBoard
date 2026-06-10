//
//  MatchDetailView.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 27/08/2025.
//

import SwiftUI
import SwiftData

struct MatchDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var scoringTeam: Team?
    @Bindable var match: Match

    private var team1Name: String { match.team1?.name ?? "Team 1" }
    private var team2Name: String { match.team2?.name ?? "Team 2" }

    var sortedGoals: [Goal] {
        match.goals.sorted { $0.elapsedSeconds > $1.elapsedSeconds }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Score display
            HStack {
                VStack {
                    Text(team1Name)
                        .font(.headline)
                    Text("\(match.team1Score)")
                        .font(.system(size: 48, weight: .bold))
                }
                .frame(maxWidth: .infinity)

                VStack {
                    Text("vs")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    TimelineView(.periodic(from: .now, by: 1)){_ in 
                        Text(formatElapsed(match.elapsedSeconds))
                        
                    }
                }

                VStack {
                    Text(team2Name)
                        .font(.headline)
                    Text("\(match.team2Score)")
                        .font(.system(size: 48, weight: .bold))
                }
                .frame(maxWidth: .infinity)
            }
            .padding()

            // Match status controls
            switch match.status {
            case .Scheduled:
                Button("Start Match") {
                    try? match.startMatch()
                }
                .buttonStyle(.borderedProminent)

            case .InProgress:
                // Goal buttons
                HStack(spacing: 20) {
                    Button {
                        scoringTeam = match.team1
                    } label: {
                        Label("Goal \(team1Name)", systemImage: "soccerball")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        scoringTeam = match.team2
                    } label: {
                        Label("Goal \(team2Name)", systemImage: "soccerball")
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button("End Match") {
                    try? match.endMatch()
                    try? modelContext.save()
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.red)

            case .Finished:
                Text("Match Finished")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Goal timeline
            if match.goals.isEmpty {
                ContentUnavailableView("No Goals Yet", systemImage: "soccerball")
            } else {
                List {
                    ForEach(sortedGoals) { goal in
                        HStack {
                            if goal.team == match.team1 {
                                goalRow(goal)
                                Spacer()
                            } else {
                                Spacer()
                                goalRow(goal)
                            }
                        }
                    }
                    .onDelete { indexes in
                        for index in indexes {
                            let goal = sortedGoals[index]
                            try? match.removeGoal(goal)
                            modelContext.delete(goal)
                        }
                    }
                    .deleteDisabled(match.status != .InProgress)
                }
                .listStyle(.plain)
            }

            Spacer()
        }
        .sheet(item: $scoringTeam) { team in
            LogGoalSheetView(match: match, scoringTeam: team)
        }
        .navigationTitle("\(team1Name) vs \(team2Name)")
    }

    @ViewBuilder
    private func goalRow(_ goal: Goal) -> some View {
        VStack(alignment: goal.team == match.team1 ? .leading : .trailing) {
            HStack(spacing: 4) {
                if goal.goalType == .Penalty {
                    Text("(P)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(goal.player?.name ?? "Unknown")
                    .font(.subheadline)
            }
            Text(formatElapsed(goal.elapsedSeconds))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct LogGoalSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var match: Match
    var scoringTeam: Team

    @Query private var allPlayers: [Player]

    @State private var selectedScorer: Player?
    @State private var selectedGoalType: Goal.GoalType = .Regular

    var availablePlayers: [Player] {
        if scoringTeam.isTemporary {
            return allPlayers
        } else {
            return scoringTeam.players
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Scoring Team") {
                    Text(scoringTeam.name)
                        .font(.headline)
                }

                Section("Goal Type") {
                    Picker("Type", selection: $selectedGoalType) {
                        Text("Regular").tag(Goal.GoalType.Regular)
                        Text("Penalty").tag(Goal.GoalType.Penalty)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Scorer (optional)") {
                    Picker("Scorer", selection: $selectedScorer) {
                        Text("Skip").tag(Optional<Player>(nil))
                        ForEach(availablePlayers) { player in
                            Text(player.name).tag(Optional(player))
                        }
                    }
                }
            }
            .navigationTitle("Log Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        let goal = Goal(
                            match: match,
                            team: scoringTeam,
                            player: selectedScorer,
                            elapsedSeconds: match.elapsedSeconds,
                            goalType: selectedGoalType
                        )
                        try? match.logGoal(goal)
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private func formatElapsed(_ seconds: Int) -> String {
    String(format: "%d:%02d", seconds / 60, seconds % 60)
}

#Preview {
    let team1 = Team(name: "Team 1")
    let team2 = Team(name: "Team 2")
    NavigationStack {
        MatchDetailView(match: Match(team1: team1, team2: team2))
    }
}

#Preview("Sheet") {
    let p1 = Player(name: "P1")
    let team1 = Team(name: "Team 1")
    team1.addPlayer(p1)
    let team2 = Team(name: "Team 2")
    return LogGoalSheetView(match: Match(team1: team1, team2: team2), scoringTeam: team1)
}
