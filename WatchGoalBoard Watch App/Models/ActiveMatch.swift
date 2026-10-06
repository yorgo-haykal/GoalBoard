//
//  ActiveMatch.swift
//  WatchGoalBoard Watch App
//
//  Created by Yorgo Haykal on 06/10/2026.
//

import Foundation

// The match being played on the Watch. Kept as plain Codable data (no SwiftData)
// and saved to disk so a relaunch doesn't lose it.
struct ActiveMatch: Codable, Equatable {
    var id: UUID
    var team1: Side
    var team2: Side
    var startedAt: Date
    var endedAt: Date?
    var goals: [Goal] = []

    struct Side: Codable, Equatable {
        var name: String
        // nil for the temporary teams of a quick match
        var teamID: UUID?
    }

    struct Goal: Codable, Equatable, Identifiable {
        var id: UUID
        var side: MatchEvent.TeamSide
        var playerID: UUID?
        var playerName: String?
        var elapsedSeconds: Int
        var goalType: MatchEvent.GoalKind
    }

    var isFinished: Bool { endedAt != nil }

    func score(_ side: MatchEvent.TeamSide) -> Int {
        goals.filter { $0.side == side }.count
    }

    func name(_ side: MatchEvent.TeamSide) -> String {
        side == .team1 ? team1.name : team2.name
    }

    func elapsedSeconds(at date: Date = Date()) -> Int {
        max(0, Int((endedAt ?? date).timeIntervalSince(startedAt)))
    }
}
