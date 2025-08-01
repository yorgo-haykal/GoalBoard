//
//  Team.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 01/08/2025.
//

import Foundation
import SwiftData

@Model
class Team: Identifiable {
    var id: String
    var name: String
    
    @Relationship
    var players: [Player]
    var record: Record
    
    init(name: String) {
        self.id = UUID().uuidString
        self.name = name
        self.players = []
        self.record = Record()
    }
    
    func addPlayer(_ player: Player) {
        players.append(player)
    }
}

@Model
class Record {
    var wins: Int
    var draws: Int
    var losses: Int
    
    init() {
        self.wins = 0
        self.draws = 0
        self.losses = 0
    }
    
    func incrementWins() { wins += 1 }
    func incrementDraws() { draws += 1 }
    func incrementLosses() { losses += 1 }
}
