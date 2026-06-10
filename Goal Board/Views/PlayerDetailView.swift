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
        List {
            if isEditing {
                Section("Name") {
                    TextField("Name", text: $newPlayerName)
                }
            }

            Section {
                HStack {
                    Label("Goals", systemImage: "soccerball")
                    Spacer()
                    Text("\(player.goalCount)")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Teams") {
                if player.teams.isEmpty {
                    Text("Not on any team")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(player.teams) { team in
                        NavigationLink(value: team) {
                            Text(team.name)
                        }
                    }
                }
            }
        }
        .navigationTitle(player.name)
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        newPlayerName = ""
                        isEditing = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        player.name = newPlayerName
                        try? modelContext.save()
                        isEditing = false
                    }
                    .disabled(newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") {
                        newPlayerName = player.name
                        isEditing = true
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PlayerDetailView(player: Player(name: "Yorgo"))
    }
}
