//
//  Blackboard_AIApp.swift
//  Blackboard AI
//
//  Created by Gamitha Samarasingha on 2025-06-08.
//

import SwiftUI

@main
struct Blackboard_AIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        Settings {
            SettingsView()
        }
    }
}
