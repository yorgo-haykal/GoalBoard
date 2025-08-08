//
//  PlayerDetailView.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 02/08/2025.
//

import SwiftUI
import SwiftData

struct PlayerDetailView: View {
    var player: Player
    
    var body: some View {
        VStack (alignment: .leading){
            Text("Goals: \(player.goalCount)")
            Divider()
            Text("Teams: ")
            List{
                ForEach(player.teams){ team in
                    NavigationLink(value: team) {
                        Text(team.name)
                    }
                }
            }
            Divider()
            Text("Match History:")
            Spacer()
        }
        .padding()
        .navigationTitle(player.name)
    }
}

#Preview {
    PlayerDetailView(player: Player(name: "Yorgo"))
}
