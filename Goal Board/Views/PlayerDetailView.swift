//
//  PlayerDetailView.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 02/08/2025.
//

import SwiftUI
import SwiftData

struct PlayerDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var player: Player
    
    @State private var isEditing = false
    @State private var newPlayerName: String = ""
    
    var body: some View {
        VStack (alignment: .leading){
            if isEditing {
                HStack {
                    TextField("New Name", text: $newPlayerName)
                        .textFieldStyle(.roundedBorder)
                    Button("Confirm") {
                        player.name = newPlayerName
                        try? modelContext.save()
                        isEditing.toggle()
                    }
                }
                Divider()
            }
            
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
        .toolbar(content: {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Cancel" : "Edit") {
                    if isEditing{
                        newPlayerName = ""
                    }
                    isEditing.toggle()
                }
            }
        })
        .navigationTitle(player.name)
    }
}

#Preview {
    NavigationStack {
        PlayerDetailView(player: Player(name: "Yorgo"))
    }
}
