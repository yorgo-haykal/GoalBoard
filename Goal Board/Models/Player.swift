//
//  Player.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 01/08/2025.
//

import Foundation
import SwiftData

@Model
class Player: Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    
    @Relationship
    var teams: [Team] = []
    
    @Relationship(inverse: \Goal.player)
    var goals: [Goal] = []
    var goalCount: Int { goals.count }
    
    init(name: String) {
        self.name = name
    }
    
    static func == (lhs: Player, rhs: Player) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
