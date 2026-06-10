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
    
    @Relationship(deleteRule: .cascade)
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
        goals.append(goal)
    }
    
    func removeGoal(_ goal: Goal) throws {
        guard status == .InProgress else {
            throw MatchError.matchNotInProgress
        }
        goals.removeAll(where: { $0.id == goal.id })
    }
    
    func startMatch() throws {
        guard status == .Scheduled || status == .InProgress else {
            throw MatchError.matchFinished
        }
        self.startedAt = Date()
        status = MatchStatus.InProgress
    }
    
    func endMatch() throws {
        guard status == .InProgress else {
            throw MatchError.matchNotInProgress
        }
        self.endedAt = Date()
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
    var match: Match
    @Relationship
    var team: Team?
    @Relationship
    var player: Player?
    
    var elapsedSeconds: Int
    
    @Attribute
    var goalType: GoalType
    
    init(match: Match, team: Team? = nil , player: Player? = nil, elapsedSeconds: Int, goalType: GoalType){
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
