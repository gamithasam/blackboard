//
//  Engine.swift
//  Blackboard AI
//
//  Created by Gamitha Samarasingha on 2025-06-11.
//

import Foundation
import PythonKit

struct EngineResult {
    let path: String
    let error: String
}

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
    var manimCode = response[manimRange].trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Remove code block syntax if present
    if manimCode.hasPrefix("```python") {
        manimCode = manimCode.replacingOccurrences(of: "```python", with: "", options: [.anchored])
        // Remove the closing ```
        if let range = manimCode.range(of: "```", options: [.backwards]) {
            manimCode = manimCode.replacingCharacters(in: range, with: "")
        }
        manimCode = manimCode.trimmingCharacters(in: .whitespacesAndNewlines)
    } else if manimCode.hasPrefix("```") {
        // Handle case where there's no language specified
        manimCode = manimCode.replacingOccurrences(of: "```", with: "", options: [.anchored])
        // Remove the closing ```
        if let range = manimCode.range(of: "```", options: [.backwards]) {
            manimCode = manimCode.replacingCharacters(in: range, with: "")
        }
        manimCode = manimCode.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    return (narration, manimCode)
}

func combineContent(narration: String, manimCode: String) -> String {
    let cleanedCode = manimCode
        .replacingOccurrences(of: "```python", with: "")
        .replacingOccurrences(of: "```",       with: "")

    return """
    -NARRATION-
    \(narration)

    -MANIM-
    \(cleanedCode)
    """
}

func extractTraceback(from errorMessage: String) -> String {
    let lines = errorMessage.components(separatedBy: .newlines)
    var tracebackLines: [String] = []
    var inTraceback = false
    
    for line in lines {
        if line.contains("Traceback (most recent call last)") {
            inTraceback = true
            tracebackLines.append(line)
        } else if inTraceback {
            tracebackLines.append(line)
            // Stop collecting if we hit an empty line after traceback content
            if line.trimmingCharacters(in: .whitespaces).isEmpty && !tracebackLines.isEmpty && tracebackLines.count > 3 {
                break
            }
        }
    }
    
    return tracebackLines.isEmpty ? errorMessage : tracebackLines.joined(separator: "\n")
}

func cleanCode(manimCode: String) -> String {
    let cleanedCode = manimCode
        .replacingOccurrences(of: "```python", with: "")
        .replacingOccurrences(of: "```",       with: "")
    
    return cleanedCode
}

@MainActor
func engine(response: String, name: String, apiMode: Bool) async -> EngineResult {
    let maxAttempts = 3
    var attempt = 0
    var narration: String
    var manimCode: String

    do {
        (narration, manimCode) = try extractContent(response: response)
    } catch {
        print("Error: \(error.localizedDescription)")
        return EngineResult(path: "", error: error.localizedDescription)
    }

    let sentences = narration
        .components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

    // All PythonKit operations are now guaranteed to run on main thread due to @MainActor
    let sys = Python.import("sys")
    let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
    sys.path.append("\(homeDir)/Developer/blackboard/Blackboard AI/Blackboard AI")

    let engine = Python.import("Engine")
    let selectedVoice = UserDefaults.standard.string(forKey: "selectedVoice") ?? "Ana Florence"
    let durations = engine.generate_audio_files(sentences, selectedVoice)
    let fixedName = name.split(separator: " ").map { $0.capitalized }.joined()
    let videoQuality = UserDefaults.standard.string(forKey: "videoQuality") ?? VideoQuality.hd720p30.rawValue

    var animationPath = ""
    var filteredError = ""
    var currentCode = manimCode

    if !apiMode {
        // If not in API mode, we can directly use the engine to generate the animation
        let result = engine.generate_animation(manimCode, durations, fixedName, videoQuality)
        animationPath = String(result["path"]) ?? ""
        let errorMessage = String(result["error"]) ?? ""

        if errorMessage.isEmpty {
            print("Animation generated successfully!")
            return EngineResult(path: animationPath, error: "")
        } else {
            filteredError = extractTraceback(from: errorMessage)
            print("Animation generated with errors: \(filteredError)")
            return EngineResult(path: "", error: filteredError)
        }
    } else {
        while attempt < maxAttempts {
            attempt += 1
            let result = engine.generate_animation(currentCode, durations, fixedName, videoQuality)
            animationPath = String(result["path"]) ?? ""
            let errorMessage = String(result["error"]) ?? ""

            if errorMessage.isEmpty {
                print("Animation generated successfully!")
                return EngineResult(path: animationPath, error: "")
            } else {
                filteredError = extractTraceback(from: errorMessage)
                print("Attempt \(attempt): Animation generated with errors: \(filteredError)")

                // Await OpenAI fix
                do {
                    let fixedCode = try await sendPromptToOpenAIAsync(
                        topic: nil,
                        originalCode: currentCode,
                        errorMessage: filteredError
                    )
                    currentCode = cleanCode(manimCode: fixedCode)
                } catch {
                    print("OpenAI error: \(error.localizedDescription)")
                    return EngineResult(path: "", error: filteredError)
                }
            }
        }
    }

    // If we reach here, all attempts failed
    return EngineResult(path: animationPath, error: filteredError)
}
