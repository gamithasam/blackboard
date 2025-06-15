//
//  HomeView.swift
//  Blackboard AI
//
//  Created by Gamitha Samarasingha on 2025-06-08.
//

import SwiftUI
import AVKit
import Combine
import AVFoundation

struct HomeView: View {
    @State private var isProcessing: Bool = false
    @State private var showPrompt: Bool = false
    @State private var videoURL: URL?
    @State private var inputText: String = ""
    @State private var audioLevel: Float = 0.0
    @State private var player: AVPlayer?
    @State private var cancellables = Set<AnyCancellable>()
    @State private var audioEngine: AVAudioEngine?
    @State private var showCopiedAlert = false
    @AppStorage("useAPIMode") private var useAPIMode: Bool = true
//    @AppStorage("apiKey") private var apiKey: String = ""
//    @AppStorage("selectedVoice") private var selectedVoice: String = "Alison Dietlinde"
    
    var body: some View {
        NavigationSplitView {
            // Sidebar view
            SidebarView()
        } detail: {
            VStack {
                ZStack {
                    if let playr = player {
                        VideoPlayer(player: playr)
                            .aspectRatio(16/9, contentMode: .fit)
                            .cornerRadius(12)
                            .padding()
                            .shadow(
                                color: .blue.opacity(0.3 + Double(audioLevel) * 0.7),
                                radius: 8 + CGFloat(audioLevel) * 20,
                                x: 0,
                                y: 0
                            )
                            .animation(.easeInOut(duration: 0.1), value: audioLevel)
                    } else if isProcessing {
                        ProgressView("Generating...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    } else if showPrompt {
                        VStack(spacing: 8) {
                            Text("Send the copied prompt to your favorite AI chatbot")
                                .font(.headline)
                            Text("Then paste the response you get below")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .multilineTextAlignment(.center)
                        .padding()
                    } else {
                        Text("What do you want to learn today?")
                            .font(.title)
                            .padding()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Spacer()
                
                HStack(alignment: .bottom, spacing: 12) {
                    TextField(showPrompt ? "Paste the response here..." : "Type your topic...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1...6)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(.ultraThinMaterial)
                            }
                        )
                        .shadow(
                            color: .black.opacity(0.05),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                    
                    // Enhanced magical send button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            setenvpy()
                            let vidPath:String = engine(response: inputText)
                            print("Video path: \(vidPath)")
                            // Handle send action
//                            if !useAPIMode {
//                                if showPrompt {
//                                    isProcessing = true
//                                    engine(response: inputText)
//                                    inputText = ""
//                                } else {
//                                    let prompt: String = """
//                                You are an expert in creating educational animations using Manim and narration scripting. Your task is to generate content for a tool that automatically creates narrated animations about \(inputText).
//
//                                ## Your Response Format
//                                Your response must follow this exact structure:
//
//                                ---NARRATION---
//                                [Write 7-8 clear, concise sentences explaining the concept, one per line]
//
//                                ---MANIM---
//                                [Your Manim code here]
//
//                                ## Narration Requirements
//                                - Write exactly 7-8 sentences, each on its own line
//                                - Each sentence should explain one step or aspect of [TOPIC]
//                                - Keep sentences clear, concise, and educational
//                                - Total narration should be 60-90 seconds when spoken
//                                - Ensure a logical progression of ideas
//
//                                ## Manim Code Requirements
//                                1. Use `class NarratedScene(Scene):` as your class name
//                                2. Include synchronized audio with animations using:
//                                   ```python
//                                   self.add_sound("media/audio/line_0.wav")
//                                   self.wait(#DURATION_0#)  # This placeholder will be replaced with the actual audio duration
//                                3. For each line of narration, add corresponding animation(s) with matching audio placeholders
//                                4. Use placeholder #DURATION_0#, #DURATION_1#, etc. for each audio line's wait time
//                                5. Follow these layout and positioning best practices:
//                                    - Group related objects using VGroup
//                                    - Arrange objects appropriately with .arrange(DIRECTION, buff=spacing) where DIRECTION could be UP, DOWN, LEFT, RIGHT
//                                    - Choose arrangement directions that make sense for your specific concept
//                                    - Use .shift() for positioning rather than absolute coordinates
//                                    - Place text with .next_to(object, DIRECTION, buff=value) to ensure proper spacing
//                                    - For any connections between objects, use get_center() for proper alignment
//                                    - Use appropriate stroke_width for lines to ensure readability
//                                6. Use clear visual distinctions:
//                                    - Use different colors for different types of objects
//                                    - Size elements appropriately (font_size, radius) based on their importance
//                                    - Position labels consistently relative to their objects
//                                7. Ensure all imports are properly included at the top
//                                8. Avoid hardcoded coordinates - position everything relative to other objects
//                                Remember that your code will be executed exactly as written, so it must be syntactically correct and follow Manim conventions.
//                                """
//                                    NSPasteboard.general.clearContents()
//                                    NSPasteboard.general.setString(prompt, forType: .string)
//                                    showCopiedAlert = true
//                                }
//                                inputText = ""
//                                showPrompt.toggle()
//                            }
//                            loadvid()
                        }
                        
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.white
                                )
                                .frame(width: 45, height: 45)
                            
                            // Send arrow with sparkle effect
                            HStack(spacing: 2) {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .white : .black)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? true : false)
                }
                .padding()
            }
            .alert("Prompt Copied to Clipboard", isPresented: $showCopiedAlert) {
                Button("OK", role: .cancel) {}
            }
            .background(Color.black)
        }
    }
    
    private func setenvpy() {
        let venvPath = "/Users/gamitha/Developer/blackboard/Blackboard AI/venv"
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
    
    private func loadvid() {
        if let url = Bundle.main.url(forResource: "test", withExtension: "mp4") {
            self.player = AVPlayer(url: url)
            setupAudioMonitoring()
        }
    }
    
    private func setupAudioMonitoring() {
        guard let player = player else { return }
        
        // Cancel existing monitoring
        cancellables.removeAll()
        audioEngine?.stop()
        audioEngine = nil
        
        // Simple smooth random movements while playing
        setupSmoothRandomAnimation(player: player)
    }
    
    private func setupSmoothRandomAnimation(player: AVPlayer) {
        Timer.publish(every: 0.02, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                let isPlaying = player.rate > 0 && player.timeControlStatus == .playing
                
                if isPlaying {
                    let currentTime = player.currentTime().seconds
                    
                    // Create smooth continuous wave patterns
                    let wave1 = sin(currentTime * 1.2) * 0.2
                    let wave2 = sin(currentTime * 0.8) * 0.15
                    let wave3 = cos(currentTime * 2.1) * 0.1
                    
                    // Combine waves for smooth variation between 0.3 and 0.7
                    let combinedWave = wave1 + wave2 + wave3
                    let smoothLevel = Float(0.5 + combinedWave)
                    
                    // No animation here - just direct assignment for ultra smooth
                    self.audioLevel = smoothLevel
                } else {
                    withAnimation(.easeOut(duration: 1.0)) {
                        self.audioLevel = 0.0
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func calculateAudioLevelFromBufferList(_ bufferList: AudioBufferList, frameCount: UInt32) -> Float {
        let buffer = bufferList.mBuffers
        guard let data = buffer.mData else { return 0.0 }
        
        let samples = data.assumingMemoryBound(to: Float.self)
        var sum: Float = 0.0
        
        for i in 0..<Int(frameCount) {
            let sample = samples[i]
            sum += sample * sample
        }
        
        let rms = sqrt(sum / Float(frameCount))
        let db = 20 * log10(max(rms, 1e-6))
        
        return max(0.0, min(1.0, (db + 60) / 60))
    }
    
    private func generateSpeechLikePattern(time: Double) -> Float {
        // Simulate speech-like audio levels with pauses and variations
        let wordCycle = time.truncatingRemainder(dividingBy: 3.0) // 3-second cycles
        let pauseChance = sin(time * 0.3) > 0.7 // Random pauses
        
        if pauseChance {
            return Float.random(in: 0.0...0.1) // Quiet during pauses
        }
        
        let intensity = sin(wordCycle * 4) * sin(wordCycle * 8) * sin(wordCycle * 16)
        return Float(max(0.2, min(0.8, abs(intensity) + 0.3)))
    }
    
    private func generateMusicLikePattern(time: Double) -> Float {
        // Simulate music-like patterns with rhythm and dynamics
        let beat = sin(time * 2.5) // Main beat
        let harmony = sin(time * 1.8) * 0.5 // Harmonic content
        let dynamics = sin(time * 0.1) * 0.3 + 0.7 // Slow dynamics changes
        
        let combined = (beat + harmony) * dynamics
        return Float(max(0.1, min(0.9, abs(combined))))
    }
    
    private func calculateRMSLevel(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0.0 }
        
        let frameLength = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        
        var rms: Float = 0.0
        
        for channel in 0..<channelCount {
            let samples = channelData[channel]
            var channelRMS: Float = 0.0
            
            for i in 0..<frameLength {
                let sample = samples[i]
                channelRMS += sample * sample
            }
            
            channelRMS = sqrt(channelRMS / Float(frameLength))
            rms += channelRMS
        }
        
        rms /= Float(channelCount)
        
        // Convert to dB and normalize
        let db = 20 * log10(max(rms, 1e-7))
        let normalizedLevel = max(0.0, min(1.0, (db + 50) / 50))
        
        return normalizedLevel
    }
}

#Preview {
    HomeView()
}
