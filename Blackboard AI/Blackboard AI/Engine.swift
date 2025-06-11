//
//  Engine.swift
//  Blackboard AI
//
//  Created by Gamitha Samarasingha on 2025-06-11.
//

import Foundation
import PythonKit

func extractContent(response: String) throws -> (narration: String, manimCode: String) {
    // Extract narration
    let narrationPattern = #"-NARRATION-\n(.*?)\n\n-MANIM-"#
    let narrationRegex = try NSRegularExpression(pattern: narrationPattern, options: [.dotMatchesLineSeparators])
    guard let narrationMatch = narrationRegex.firstMatch(in: response, options: [], range: NSRange(response.startIndex..., in: response)),
          let narrationRange = Range(narrationMatch.range(at: 1), in: response) else {
        throw NSError(domain: "ExtractContentError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not find narration section in ChatGPT response"])
    }
    let narration = response[narrationRange].trimmingCharacters(in: .whitespacesAndNewlines)

    // Extract Manim code
    let manimPattern = #"-MANIM-\n(.*)"#
    let manimRegex = try NSRegularExpression(pattern: manimPattern, options: [.dotMatchesLineSeparators])
    guard let manimMatch = manimRegex.firstMatch(in: response, options: [], range: NSRange(response.startIndex..., in: response)),
          let manimRange = Range(manimMatch.range(at: 1), in: response) else {
        throw NSError(domain: "ExtractContentError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not find Manim code section in ChatGPT response"])
    }
    let manimCode = response[manimRange].trimmingCharacters(in: .whitespacesAndNewlines)

    return (narration, manimCode)
}

func engine(response: String) {
    do {
        let (narration, manimCode) = try extractContent(response: response)
        
        let sentences = narration
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        let sys = Python.import("sys")
        sys.path.append(".") // Adds the current directory to Python's module search path

        let engine = Python.import("Engine")
        
        let durations = engine.generate_audio_files(sentences)
        
        let animation = engine.generate_animation(manimCode, durations)
        print("Animation generated successfully!")
    } catch {
        print("Error: \(error.localizedDescription)")
    }
}
