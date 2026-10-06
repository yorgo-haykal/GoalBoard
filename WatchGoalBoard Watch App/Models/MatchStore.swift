//
//  MatchStore.swift
//  WatchGoalBoard Watch App
//
//  Created by Yorgo Haykal on 06/10/2026.
//

import Foundation
import Observation

// Owns the Watch's state: the latest roster from the iPhone and the match being played.
// Every change to the match is turned into a MatchEvent and handed to `send`.
@Observable
final class MatchStore {
    private(set) var roster: RosterSnapshot
    private(set) var activeMatch: ActiveMatch?
    // Scheduled matches started on the Watch that the iPhone may not know about yet
    private var startedMatchIDs: Set<UUID>

    @ObservationIgnored private let send: (MatchEvent) -> Void
    @ObservationIgnored private let rosterURL: URL
    @ObservationIgnored private let activeMatchURL: URL
    @ObservationIgnored private let startedMatchIDsURL: URL

    init(directory: URL = .applicationSupportDirectory, send: @escaping (MatchEvent) -> Void) {
        self.send = send
        rosterURL = directory.appending(path: "roster.json")
        activeMatchURL = directory.appending(path: "activeMatch.json")
        startedMatchIDsURL = directory.appending(path: "startedMatchIDs.json")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        roster = Self.load(RosterSnapshot.self, from: rosterURL) ?? .empty
        activeMatch = Self.load(ActiveMatch.self, from: activeMatchURL)
        startedMatchIDs = Self.load(Set<UUID>.self, from: startedMatchIDsURL) ?? []
    }

    // MARK: - Roster

    // Scheduled matches that can still be started from the Watch
    var scheduledMatches: [RosterSnapshot.ScheduledMatchInfo] {
        roster.scheduledMatches.filter { !startedMatchIDs.contains($0.id) }
    }

    func updateRoster(_ roster: RosterSnapshot) {
        self.roster = roster
        Self.save(roster, to: rosterURL)
        // Once the iPhone no longer lists a match as scheduled, it knows it was started
        let stillScheduled = Set(roster.scheduledMatches.map(\.id))
        setStartedMatchIDs(startedMatchIDs.intersection(stillScheduled))
    }

    // Players that can be picked as scorer for a side: the team's players,
    // or everyone for the temporary teams of a quick match (same as the iPhone)
    func players(for side: MatchEvent.TeamSide) -> [RosterSnapshot.PlayerInfo] {
        guard let match = activeMatch else { return [] }
        let teamSide = side == .team1 ? match.team1 : match.team2
        guard let teamID = teamSide.teamID, let team = roster.team(teamID) else { return roster.players }
        return roster.players(in: team)
    }

    // MARK: - Match

    func startQuickMatch() {
        guard activeMatch == nil else { return }
        let match = ActiveMatch(
            id: UUID(),
            team1: .init(name: "Team 1"),
            team2: .init(name: "Team 2"),
            startedAt: Date()
        )
        setActiveMatch(match)
        // Quick match teams have no ID on the Watch side, the iPhone just needs two new ones
        send(MatchEvent(matchID: match.id, occurredAt: match.startedAt, kind: .quickMatchStarted(team1ID: UUID(), team2ID: UUID())))
    }

    func start(_ scheduled: RosterSnapshot.ScheduledMatchInfo) {
        guard activeMatch == nil else { return }
        let team1 = roster.team(scheduled.team1ID)
        let team2 = roster.team(scheduled.team2ID)
        let match = ActiveMatch(
            id: scheduled.id,
            team1: .init(name: team1?.name ?? "Team 1", teamID: scheduled.team1ID),
            team2: .init(name: team2?.name ?? "Team 2", teamID: scheduled.team2ID),
            startedAt: Date()
        )
        setActiveMatch(match)
        setStartedMatchIDs(startedMatchIDs.union([match.id]))
        send(MatchEvent(matchID: match.id, occurredAt: match.startedAt, kind: .started))
    }

    func logGoal(side: MatchEvent.TeamSide, elapsedSeconds: Int, player: RosterSnapshot.PlayerInfo?, goalType: MatchEvent.GoalKind) {
        guard var match = activeMatch, !match.isFinished else { return }
        let goal = ActiveMatch.Goal(
            id: UUID(),
            side: side,
            playerID: player?.id,
            playerName: player?.name,
            elapsedSeconds: elapsedSeconds,
            goalType: goalType
        )
        match.goals.append(goal)
        setActiveMatch(match)
        send(MatchEvent(matchID: match.id, kind: .goal(
            goalID: goal.id, side: side, playerID: goal.playerID, elapsedSeconds: elapsedSeconds, goalType: goalType
        )))
    }

    func undoLastGoal() {
        guard var match = activeMatch, !match.isFinished, let goal = match.goals.popLast() else { return }
        setActiveMatch(match)
        send(MatchEvent(matchID: match.id, kind: .goalRemoved(goalID: goal.id)))
    }

    func endMatch() {
        guard var match = activeMatch, !match.isFinished else { return }
        let endedAt = Date()
        match.endedAt = endedAt
        setActiveMatch(match)
        send(MatchEvent(matchID: match.id, occurredAt: endedAt, kind: .ended))
    }

    // Leaves the final score screen once the match is over
    func closeFinishedMatch() {
        guard activeMatch?.isFinished == true else { return }
        setActiveMatch(nil)
    }

    // MARK: - Persistence

    private func setActiveMatch(_ match: ActiveMatch?) {
        activeMatch = match
        if let match {
            Self.save(match, to: activeMatchURL)
        } else {
            try? FileManager.default.removeItem(at: activeMatchURL)
        }
    }

    private func setStartedMatchIDs(_ ids: Set<UUID>) {
        guard ids != startedMatchIDs else { return }
        startedMatchIDs = ids
        Self.save(ids, to: startedMatchIDsURL)
    }

    private static func load<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func save<T: Encodable>(_ value: T, to url: URL) {
        do {
            try JSONEncoder().encode(value).write(to: url, options: .atomic)
        } catch {
            print("Failed to save \(url.lastPathComponent): \(error)")
        }
    }
}
