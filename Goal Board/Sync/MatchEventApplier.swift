//
//  MatchEventApplier.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 06/10/2026.
//

import Foundation
import SwiftData

// Applies events coming from the Watch to the iPhone's SwiftData store.
// Events can arrive more than once, so every case checks whether it was already applied
// and does nothing in that case. Events that no longer make sense (unknown match,
// match already finished) are skipped too.
struct MatchEventApplier {
    let context: ModelContext

    // Returns true when the event changed the store
    @discardableResult
    func apply(_ event: MatchEvent) throws -> Bool {
        switch event.kind {
        case let .quickMatchStarted(team1ID, team2ID):
            guard try match(event.matchID) == nil else { return false }
            context.insert(Match(id: event.matchID, team1ID: team1ID, team2ID: team2ID, startedAt: event.occurredAt))
            return true

        case .started:
            guard let match = try match(event.matchID), match.status == .Scheduled else { return false }
            try match.startMatch(at: event.occurredAt)
            return true

        case let .goal(goalID, side, playerID, elapsedSeconds, goalType):
            guard try goal(goalID) == nil,
                  let match = try match(event.matchID),
                  match.status == .InProgress else { return false }
            let goal = Goal(
                match: nil,
                team: side == .team1 ? match.team1 : match.team2,
                player: try playerID.flatMap { try player($0) },
                elapsedSeconds: elapsedSeconds,
                goalType: Goal.GoalType(rawValue: goalType.rawValue) ?? .Regular
            )
            goal.id = goalID
            try match.logGoal(goal)
            return true

        case let .goalRemoved(goalID):
            guard let goal = try goal(goalID),
                  let match = goal.match,
                  match.status == .InProgress else { return false }
            try match.removeGoal(goal)
            context.delete(goal)
            return true

        case .ended:
            guard let match = try match(event.matchID), match.status == .InProgress else { return false }
            try match.endMatch(at: event.occurredAt)
            return true
        }
    }

    private func match(_ id: UUID) throws -> Match? {
        try context.fetch(FetchDescriptor<Match>(predicate: #Predicate { $0.id == id })).first
    }

    private func goal(_ id: UUID) throws -> Goal? {
        try context.fetch(FetchDescriptor<Goal>(predicate: #Predicate { $0.id == id })).first
    }

    private func player(_ id: UUID) throws -> Player? {
        try context.fetch(FetchDescriptor<Player>(predicate: #Predicate { $0.id == id })).first
    }
}
