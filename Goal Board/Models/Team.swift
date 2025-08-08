//
//  Team.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 01/08/2025.
//

import Foundation
import SwiftData

@Model
class Team: Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    
    @Relationship(inverse: \Player.teams)
    var players: [Player] = []
    
    var wins: Int = 0
    var draws: Int = 0
    var losses: Int = 0
    
    init(name: String) {
        self.name = name
    }
    
    static func == (lhs: Team, rhs: Team) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    func addPlayer(_ player: Player) {
        players.append(player)
    }
    
    func incrementWins() { wins += 1 }
    func incrementDraws() { draws += 1 }
    func incrementLosses() { losses += 1 }
}
