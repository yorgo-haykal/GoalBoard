//
//  RosterSnapshot+Models.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 06/10/2026.
//

import Foundation
import SwiftData

extension RosterSnapshot {
    // Builds the snapshot the Watch needs from the iPhone's SwiftData store
    init(context: ModelContext) throws {
        let teams = try context.fetch(FetchDescriptor<Team>(
            predicate: #Predicate { $0.isTemporary == false },
            sortBy: [SortDescriptor(\.name)]
        ))
        let players = try context.fetch(FetchDescriptor<Player>(sortBy: [SortDescriptor(\.name)]))
        let matches = try context.fetch(FetchDescriptor<Match>(sortBy: [SortDescriptor(\.date)]))

        self.init(
            teams: teams.map { TeamInfo(id: $0.id, name: $0.name, playerIDs: $0.players.map(\.id)) },
            players: players.map { PlayerInfo(id: $0.id, name: $0.name) },
            scheduledMatches: matches.compactMap { match in
                guard match.status == .Scheduled, let team1 = match.team1, let team2 = match.team2 else { return nil }
                return ScheduledMatchInfo(id: match.id, date: match.date, team1ID: team1.id, team2ID: team2.id)
            }
        )
    }

    // Same teams, players and matches, ignoring when the snapshot was made
    func hasSameContent(as other: RosterSnapshot) -> Bool {
        teams == other.teams && players == other.players && scheduledMatches == other.scheduledMatches
    }
}
