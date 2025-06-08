//
//  HomeView.swift
//  Blackboard AI
//
//  Created by Gamitha Samarasingha on 2025-06-08.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationSplitView {
            // Sidebar view
            SidebarView()
        } detail: {
            Text("Hello Home")
        }
    }
}

#Preview {
    HomeView()
}
