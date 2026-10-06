//
//  LiveMatchView.swift
//  WatchGoalBoard Watch App
//
//  Created by Yorgo Haykal on 06/10/2026.
//

import SwiftUI

struct LiveMatchView: View {
    @Environment(MatchStore.self) private var store
    let match: ActiveMatch

    @State private var pendingGoal: PendingGoal?
    @State private var isConfirmingEnd = false

    // Goal tapped but scorer not picked yet; the time is taken at the tap
    struct PendingGoal: Identifiable {
        let id = UUID()
        let side: MatchEvent.TeamSide
        let elapsedSeconds: Int
    }

    var body: some View {
        if match.isFinished {
            finishedView
        } else {
            liveView
        }
    }

    private var liveView: some View {
        VStack(spacing: 6) {
            Text(match.startedAt, style: .timer)
                .font(.title3.monospacedDigit())
                .foregroundStyle(.green)

            HStack(spacing: 6) {
                scoreButton(.team1)
                scoreButton(.team2)
            }
        }
        .padding(.horizontal, 4)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    store.undoLastGoal()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(match.goals.isEmpty)
                .accessibilityLabel("Undo last goal")

                Spacer()

                Button {
                    isConfirmingEnd = true
                } label: {
                    Image(systemName: "flag.checkered")
                }
                .accessibilityLabel("End match")
            }
        }
        .sheet(item: $pendingGoal) { goal in
            ScorerSheetView(pendingGoal: goal, teamName: match.name(goal.side))
        }
        .confirmationDialog("End the match?", isPresented: $isConfirmingEnd) {
            Button("End Match", role: .destructive) {
                store.endMatch()
            }
        }
    }

    private func scoreButton(_ side: MatchEvent.TeamSide) -> some View {
        Button {
            pendingGoal = PendingGoal(side: side, elapsedSeconds: match.elapsedSeconds())
        } label: {
            VStack(spacing: 2) {
                Text("\(match.score(side))")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                Text(match.name(side))
                    .font(.footnote)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.bordered)
        .accessibilityLabel("Goal for \(match.name(side)), score \(match.score(side))")
    }

    private var finishedView: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Full Time")
                    .font(.headline)
                    .foregroundStyle(.green)
                HStack {
                    finalScore(.team1)
                    Text("–")
                        .font(.title2)
                    finalScore(.team2)
                }
                Text(formatElapsed(match.elapsedSeconds()))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Done") {
                    store.closeFinishedMatch()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
    }

    private func finalScore(_ side: MatchEvent.TeamSide) -> some View {
        VStack {
            Text("\(match.score(side))")
                .font(.system(size: 36, weight: .bold, design: .rounded))
            Text(match.name(side))
                .font(.footnote)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

func formatElapsed(_ seconds: Int) -> String {
    String(format: "%d:%02d", seconds / 60, seconds % 60)
}
