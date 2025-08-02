//
//  TeamDetailView.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 02/08/2025.
//

import SwiftUI

struct TeamDetailView: View {
    var team: Team
    
    var body: some View {
        VStack (alignment: .leading) {
            Text("Matches played: 0")
            
            Text("Record: \(team.record.wins)-\(team.record.draws)-\(team.record.losses)")
                .navigationTitle(team.name)
            Divider()
            Text("Match History:")
            Spacer()
        }
        .padding()
    }
}

#Preview {
    TeamDetailView(team: Team(name: "HN"))
}
