//
//  PythonManager.swift
//  Blackboard AI
//
//  Bundle management for embedded Python
//

import Foundation
import PythonKit

class PythonManager {
    static let shared = PythonManager()
    private var isInitialized = false
    
    private init() {}
    
    func initializePython() {
        guard !isInitialized else { return }
        
        // Get the app bundle path
        let bundlePath = Bundle.main.bundlePath
        
        // Path to embedded Python virtual environment
        let pythonEnvPath = "\(bundlePath)/Contents/Resources/python-env"
        let pythonExecutable = "\(pythonEnvPath)/bin/python3"
        let pythonLibPath = "\(pythonEnvPath)/lib/python3.10"
        let pythonSitePackages = "\(pythonLibPath)/site-packages"
        
        // Check if embedded Python exists
        if FileManager.default.fileExists(atPath: pythonExecutable) {
            // Set Python path to use embedded version
            PythonLibrary.useLibrary(at: pythonExecutable)
            
            // Configure Python path
            let sys = Python.import("sys")
            sys.path.insert(0, pythonSitePackages)
            sys.path.insert(0, pythonLibPath)
            sys.path.insert(0, "\(bundlePath)/Contents/Resources")
            
            // Add the bundled python-env/bin to PATH for manim and other tools
            let os = Python.import("os")
            let currentPath = String(os.environ.get("PATH", ""))
            let newPath = "\(pythonEnvPath)/bin:\(currentPath)"
            os.environ["PATH"] = Python.PythonObject(newPath)
            
            print("Using embedded Python at: \(pythonExecutable)")
        } else {
            // Fallback to system Python (for development)
            print("Embedded Python not found, using system Python")
            let sys = Python.import("sys")
            let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
            sys.path.append("\(homeDir)/Developer/blackboard/Blackboard AI/Blackboard AI")
        }
        
        isInitialized = true
    }
}
