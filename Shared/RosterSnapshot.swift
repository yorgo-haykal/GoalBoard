//
//  RosterSnapshot.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 05/10/2026.
//

import Foundation

// Sent from the iPhone to the Watch: everything the Watch needs to start and score a match.
// The Watch only ever keeps the latest snapshot.
struct RosterSnapshot: Codable, Equatable, Sendable {
    var teams: [TeamInfo]
    var players: [PlayerInfo]
    var scheduledMatches: [ScheduledMatchInfo]
    var generatedAt: Date = Date()

    struct TeamInfo: Codable, Equatable, Identifiable, Sendable {
        var id: UUID
        var name: String
        var playerIDs: [UUID]
    }

    struct PlayerInfo: Codable, Equatable, Identifiable, Sendable {
        var id: UUID
        var name: String
    }

    struct ScheduledMatchInfo: Codable, Equatable, Identifiable, Sendable {
        var id: UUID
        var date: Date
        var team1ID: UUID
        var team2ID: UUID
    }

    static let empty = RosterSnapshot(teams: [], players: [], scheduledMatches: [])

    func team(_ id: UUID) -> TeamInfo? {
        teams.first { $0.id == id }
    }

    func players(in team: TeamInfo) -> [PlayerInfo] {
        players.filter { team.playerIDs.contains($0.id) }
    }
}
