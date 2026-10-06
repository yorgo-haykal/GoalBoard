//
//  Match.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 02/08/2025.
//

import Foundation
import SwiftData

@Model
class Match: Identifiable, Hashable {
    var id: UUID = UUID()
    var date: Date
    
    @Relationship
    var team1: Team?
    @Relationship
    var team2: Team?
    
    var team1Score: Int {
        goals.filter { $0.team == team1 }.count
    }
    var team2Score: Int {
        goals.filter { $0.team == team2 }.count
    }
    
    @Relationship(deleteRule: .cascade, inverse: \Goal.match)
    var goals: [Goal] = []
    
    var result: MatchResult {
        if team1Score > team2Score {
            return MatchResult.Team1
        } else if team1Score < team2Score {
            return MatchResult.Team2
        } else {
            return MatchResult.Draw
        }
    }
    
    var status: MatchStatus
    
    var startedAt: Date?
    var endedAt: Date?
    
    var elapsedSeconds: Int {
            guard let startedAt = startedAt else { return 0 }
            let end = endedAt ?? Date()
            return max(0, Int(end.timeIntervalSince(startedAt)))
        }
    
    // To be used when starting a quick match
    init() {
        self.date = Date()
        self.team1 = Team(name: "Team 1", isTemporary: true)
        self.team2 = Team(name: "Team 2", isTemporary: true)
        self.status = .InProgress
        self.startedAt = Date()
    }
    
    // To be used when a quick match is started on the Watch, which chooses the IDs
    init(id: UUID, team1ID: UUID, team2ID: UUID, startedAt: Date) {
        let team1 = Team(name: "Team 1", isTemporary: true)
        team1.id = team1ID
        let team2 = Team(name: "Team 2", isTemporary: true)
        team2.id = team2ID
        self.id = id
        self.date = startedAt
        self.team1 = team1
        self.team2 = team2
        self.status = .InProgress
        self.startedAt = startedAt
    }

    // To be used when scheduling a match
    init(date: Date = Date(), team1: Team, team2: Team){
        self.date = date
        self.team1 = team1
        self.team2 = team2
        self.status = .Scheduled
    }
    
    static func == (lhs: Match, rhs: Match) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    func logGoal(_ goal: Goal) throws {
        guard status == .InProgress else {
            throw MatchError.matchNotInProgress
        }
        goal.match = self
        goals.append(goal)
    }
    
    func removeGoal(_ goal: Goal) throws {
        guard status == .InProgress else {
            throw MatchError.matchNotInProgress
        }
        goals.removeAll(where: { $0.id == goal.id })
    }
    
    func startMatch(at date: Date = Date()) throws {
        guard status == .Scheduled || status == .InProgress else {
            throw MatchError.matchFinished
        }
        self.startedAt = date
        status = MatchStatus.InProgress
    }

    func endMatch(at date: Date = Date()) throws {
        guard status == .InProgress else {
            throw MatchError.matchNotInProgress
        }
        self.endedAt = date
        status = MatchStatus.Finished
    }
    
    enum MatchResult: String, Codable, Sendable{
        case Team1
        case Team2
        case Draw
    }
    
    enum MatchStatus: String, Codable, Sendable{
        case Scheduled
        case InProgress
        case Finished
    }
    
    enum MatchError: Error{
        case matchNotInProgress
        case matchFinished
    }
}

@Model
class Goal: Identifiable {
    var id: UUID = UUID()
    
    @Relationship
    var match: Match?
    @Relationship
    var team: Team?
    @Relationship
    var player: Player?
    
    var elapsedSeconds: Int
    
    @Attribute
    var goalType: GoalType
    
    init(match: Match?, team: Team? = nil , player: Player? = nil, elapsedSeconds: Int, goalType: GoalType){
        self.match = match
        self.team = team
        self.player = player
        self.goalType = goalType
        self.elapsedSeconds = elapsedSeconds
    }
    
    enum GoalType : String, Codable, Sendable{
        case Regular
        case Penalty
    }
}
