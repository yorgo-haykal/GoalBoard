//
//  Player.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 01/08/2025.
//

import Foundation
import SwiftData

@Model
class Player: Identifiable {
    var id: String
    var name: String
    var goalCount: Int = 0
    
    init(name: String) {
        self.id = UUID().uuidString
        self.name = name
    }
}
