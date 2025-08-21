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
    var team1: Team
    @Relationship
    var team2: Team
    
    var team1Score: Int = 0
    var team2Score: Int = 0
    
    @Relationship
    var goals: [Goal] = []
    
    init(date: Date = Date(), team1: Team, team2: Team){
        self.date = date
        self.team1 = team1
        self.team2 = team2
    }
    
    static func == (lhs: Match, rhs: Match) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    func logGoal(_ goal: Goal){
        goals.append(goal)
        goal.team == team1 ? logTeam1Goal() : logTeam2Goal()
    }
    
    func logTeam1Goal() {
        self.team1Score += 1
    }
    func logTeam2Goal() {
        self.team2Score += 1
    }
}

@Model
class Goal: Identifiable {
    var id: UUID = UUID()
    
    @Relationship
    var match: Match
    @Relationship
    var team: Team
    @Relationship
    var player: Player
    
    var timestamp: Date
    
    @Attribute
    var goalType: GoalType
    
    init(match: Match, team: Team , player: Player, timestamp: Date,goalType: GoalType){
        self.match = match
        self.team = team
        self.player = player
        self.timestamp = timestamp
        self.goalType = goalType
    }
    
    enum GoalType : String, Codable, Sendable{
        case Regular
        case Penalty
        case OwnGoal
        case FreeKick
    }
}
