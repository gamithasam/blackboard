//
//  ContentView.swift
//  Blackboard AI
//
//  Created by Gamitha Samarasingha on 2025-06-08.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var videoPlayerManager = VideoPlayerManager()

    var body: some View {
        HomeView()
            .environmentObject(videoPlayerManager)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
