//
//  MatchListView.swift
//  Goal Board
//
//  Created by Yorgo Haykal on 03/08/2025.
//

import SwiftUI
import SwiftData

struct MatchListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var matches: [Match]
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            .navigationTitle("Matches")
    }
}

#Preview {
    MatchListView()
}
