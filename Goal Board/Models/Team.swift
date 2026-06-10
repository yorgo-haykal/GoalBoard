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
    
    @Relationship(inverse: \Match.team1) var matchesAsTeam1: [Match] = []
    @Relationship(inverse: \Match.team2) var matchesAsTeam2: [Match] = []
    var matches: [Match] { matchesAsTeam1 + matchesAsTeam2 }
    
    var wins: Int {
        matchesAsTeam1.filter { $0.status == .Finished && $0.result == .Team1 }.count
        + matchesAsTeam2.filter { $0.status == .Finished && $0.result == .Team2 }.count
    }
    var draws: Int {
        matches.filter { $0.status == .Finished && $0.result == .Draw }.count
    }
    var losses: Int {
        matchesAsTeam1.filter { $0.status == .Finished && $0.result == .Team2 }.count
        + matchesAsTeam2.filter { $0.status == .Finished && $0.result == .Team1 }.count
    }

    var isTemporary: Bool = false

    init(name: String, isTemporary: Bool = false) {
        self.name = name
        self.isTemporary = isTemporary
    }
    
    static func == (lhs: Team, rhs: Team) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    func addPlayer(_ player: Player) {
        guard !players.contains(where: { $0.id == player.id }) else { return }
        players.append(player)
    }
    
    func removePlayer(_ player: Player) {
        players.removeAll { $0 == player }
    }
}
