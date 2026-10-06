//
//  MatchEventApplierTests.swift
//  GoalBoardTests
//
//  Created by Yorgo Haykal on 06/10/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Goal_Board

@MainActor
struct MatchEventApplierTests {
    let container: ModelContainer
    let context: ModelContext
    let applier: MatchEventApplier

    init() throws {
        container = try ModelContainer(
            for: Player.self, Team.self, Match.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        context = container.mainContext
        applier = MatchEventApplier(context: context)
    }

    private func matches() throws -> [Match] {
        try context.fetch(FetchDescriptor<Match>())
    }

    private func goals() throws -> [Goal] {
        try context.fetch(FetchDescriptor<Goal>())
    }

    // Starts a quick match through the applier and returns it
    private func startQuickMatch(at date: Date = Date()) throws -> Match {
        let event = MatchEvent(matchID: UUID(), occurredAt: date, kind: .quickMatchStarted(team1ID: UUID(), team2ID: UUID()))
        try applier.apply(event)
        return try #require(try matches().first { $0.id == event.matchID })
    }

    private func goalEvent(_ match: Match, goalID: UUID = UUID(), side: MatchEvent.TeamSide = .team1, playerID: UUID? = nil,
                           elapsedSeconds: Int = 60, goalType: MatchEvent.GoalKind = .Regular) -> MatchEvent {
        MatchEvent(matchID: match.id, kind: .goal(goalID: goalID, side: side, playerID: playerID, elapsedSeconds: elapsedSeconds, goalType: goalType))
    }

    // MARK: - Quick match

    @Test func quickMatchUsesWatchIDsAndStartTime() throws {
        let matchID = UUID(), team1ID = UUID(), team2ID = UUID()
        let startedAt = Date(timeIntervalSince1970: 1_000_000)
        let event = MatchEvent(matchID: matchID, occurredAt: startedAt, kind: .quickMatchStarted(team1ID: team1ID, team2ID: team2ID))

        #expect(try applier.apply(event))

        let match = try #require(try matches().first)
        #expect(match.id == matchID)
        #expect(match.team1?.id == team1ID)
        #expect(match.team2?.id == team2ID)
        #expect(match.team1?.isTemporary == true)
        #expect(match.team2?.isTemporary == true)
        #expect(match.status == .InProgress)
        #expect(match.startedAt == startedAt)
    }

    @Test func duplicateQuickMatchIsIgnored() throws {
        let event = MatchEvent(matchID: UUID(), kind: .quickMatchStarted(team1ID: UUID(), team2ID: UUID()))

        #expect(try applier.apply(event))
        #expect(try applier.apply(event) == false)
        #expect(try matches().count == 1)
    }

    // MARK: - Goals

    @Test func goalIsLoggedForTheRightSideWithWatchData() throws {
        let match = try startQuickMatch()
        let player = Player(name: "Yorgo")
        context.insert(player)
        let goalID = UUID()

        #expect(try applier.apply(goalEvent(match, goalID: goalID, side: .team2, playerID: player.id, elapsedSeconds: 312, goalType: .Penalty)))

        #expect(match.team1Score == 0)
        #expect(match.team2Score == 1)
        let goal = try #require(match.goals.first)
        #expect(goal.id == goalID)
        #expect(goal.team == match.team2)
        #expect(goal.player == player)
        #expect(goal.elapsedSeconds == 312)
        #expect(goal.goalType == .Penalty)
        #expect(goal.match == match)
    }

    @Test func goalWithUnknownPlayerIsKeptWithoutScorer() throws {
        let match = try startQuickMatch()

        #expect(try applier.apply(goalEvent(match, playerID: UUID())))

        #expect(match.team1Score == 1)
        #expect(match.goals.first?.player == nil)
    }

    @Test func duplicateGoalIsIgnored() throws {
        let match = try startQuickMatch()
        let event = goalEvent(match)

        #expect(try applier.apply(event))
        #expect(try applier.apply(event) == false)
        #expect(match.team1Score == 1)
        #expect(try goals().count == 1)
    }

    @Test func goalForUnknownMatchIsIgnored() throws {
        let event = MatchEvent(matchID: UUID(), kind: .goal(goalID: UUID(), side: .team1, playerID: nil, elapsedSeconds: 10, goalType: .Regular))

        #expect(try applier.apply(event) == false)
        #expect(try goals().isEmpty)
    }

    @Test func goalRemovedDeletesTheGoal() throws {
        let match = try startQuickMatch()
        let goalID = UUID()
        try applier.apply(goalEvent(match, goalID: goalID))
        let removal = MatchEvent(matchID: match.id, kind: .goalRemoved(goalID: goalID))

        #expect(try applier.apply(removal))
        #expect(try applier.apply(removal) == false)
        #expect(match.team1Score == 0)
        #expect(try goals().isEmpty)
    }

    // MARK: - Scheduled match

    @Test func scheduledMatchStartsOnceAtWatchTime() throws {
        let match = Match(team1: Team(name: "Reds"), team2: Team(name: "Blues"))
        context.insert(match)
        let startedAt = Date(timeIntervalSince1970: 2_000_000)

        #expect(try applier.apply(MatchEvent(matchID: match.id, occurredAt: startedAt, kind: .started)))
        #expect(try applier.apply(MatchEvent(matchID: match.id, occurredAt: startedAt.addingTimeInterval(60), kind: .started)) == false)

        #expect(match.status == .InProgress)
        #expect(match.startedAt == startedAt)
    }

    // MARK: - End

    @Test func endedUsesWatchTimeAndBlocksLaterGoals() throws {
        let match = try startQuickMatch(at: Date(timeIntervalSince1970: 3_000_000))
        let endedAt = Date(timeIntervalSince1970: 3_003_000)

        #expect(try applier.apply(MatchEvent(matchID: match.id, occurredAt: endedAt, kind: .ended)))
        #expect(try applier.apply(MatchEvent(matchID: match.id, kind: .ended)) == false)
        #expect(try applier.apply(goalEvent(match)) == false)

        #expect(match.status == .Finished)
        #expect(match.endedAt == endedAt)
        #expect(match.elapsedSeconds == 3000)
        #expect(try goals().isEmpty)
    }
}

@MainActor
struct RosterSnapshotTests {
    @Test func snapshotSkipsTemporaryTeamsAndNonScheduledMatches() throws {
        let container = try ModelContainer(
            for: Player.self, Team.self, Match.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext

        let player = Player(name: "Yorgo")
        let reds = Team(name: "Reds")
        let blues = Team(name: "Blues")
        context.insert(player)
        context.insert(reds)
        context.insert(blues)
        reds.addPlayer(player)

        let scheduled = Match(team1: reds, team2: blues)
        let finished = Match(team1: blues, team2: reds)
        context.insert(scheduled)
        context.insert(finished)
        try finished.startMatch()
        try finished.endMatch()
        context.insert(Match()) // quick match with two temporary teams

        let roster = try RosterSnapshot(context: context)

        #expect(roster.teams.map(\.name) == ["Blues", "Reds"])
        #expect(roster.team(reds.id)?.playerIDs == [player.id])
        #expect(roster.players.map(\.id) == [player.id])
        #expect(roster.scheduledMatches.map(\.id) == [scheduled.id])
        #expect(roster.scheduledMatches.first?.team1ID == reds.id)
        #expect(try RosterSnapshot(context: context).hasSameContent(as: roster))
    }
}
