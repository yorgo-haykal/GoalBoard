//
//  MatchEvent.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 05/10/2026.
//

import Foundation

// Sent from the Watch to the iPhone: one thing that happened during a live match.
// Events are queued and may arrive late or more than once, so the iPhone uses `id`
// to apply each one only once, and `occurredAt` (Watch clock) rather than arrival time.
struct MatchEvent: Codable, Equatable, Identifiable, Sendable {
    var id: UUID = UUID()
    var matchID: UUID
    var occurredAt: Date = Date()
    var kind: Kind

    enum Kind: Codable, Equatable, Sendable {
        // Quick match created on the Watch; team IDs are chosen by the Watch for the temporary teams
        case quickMatchStarted(team1ID: UUID, team2ID: UUID)
        // A scheduled match from the iPhone was started on the Watch
        case started
        case goal(goalID: UUID, side: TeamSide, playerID: UUID?, elapsedSeconds: Int, goalType: GoalKind)
        case goalRemoved(goalID: UUID)
        case ended
    }

    enum TeamSide: String, Codable, Sendable {
        case team1
        case team2
    }

    // Raw values match Goal.GoalType so the iPhone can convert with init(rawValue:)
    enum GoalKind: String, Codable, Sendable {
        case Regular
        case Penalty
    }
}
