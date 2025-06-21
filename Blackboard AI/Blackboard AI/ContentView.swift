//
//  ContentView.swift
//  Blackboard AI
//
//  Created by Gamitha Samarasingha on 2025-06-08.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var videoPlayerManager = VideoPlayerManager()
    
    init() {
        setenvpy()
    }

    var body: some View {
        HomeView()
            .environmentObject(videoPlayerManager)
    }
    
    private func setenvpy() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let venvPath = "\(homeDir)/Developer/blackboard/venv"
        let basePythonLib = "/opt/homebrew/Cellar/python@3.10/3.10.18/Frameworks/Python.framework/Versions/3.10/lib/libpython3.10.dylib"

        setenv("PYTHON_LIBRARY", basePythonLib, 1)
        setenv("PYTHONPATH", "\(venvPath)/lib/python3.10/site-packages", 1)
        setenv("PYTHONIOENCODING", "utf-8", 1)

        // Add virtualenv's bin to PATH so subprocesses can find "manim"
        let venvBin = "\(venvPath)/bin"
        if let oldPath = getenv("PATH") {
            let newPath = "\(venvBin):/opt/homebrew/bin:" + String(cString: oldPath)
            setenv("PATH", newPath, 1)
        } else {
            setenv("PATH", "\(venvBin):/opt/homebrew/bin", 1)
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
