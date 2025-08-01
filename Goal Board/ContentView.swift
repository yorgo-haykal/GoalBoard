//
//  ContentView.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 01/08/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Players", systemImage: "figure.indoor.soccer", value: 1) {
                NavigationStack {
                    PlayerListView()
                }
            }
            
            Tab("Teams", systemImage:"person.3.fill", value: 2){
                Text("Teams")
            }
        }
    }
}

#Preview {
    ContentView()
}
