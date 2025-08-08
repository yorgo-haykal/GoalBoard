//
//  Player.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 01/08/2025.
//

import Foundation
import SwiftData

@Model
class Player: Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var goalCount: Int = 0
    
    @Relationship
    var teams: [Team] = []
    
    init(name: String) {
        self.name = name
    }
}
