//
//  CreationRow.swift
//  Blackboard AI
//
//  Created by Gamitha Samarasingha on 2025-06-20.
//

import SwiftUI

struct CreationRow: View {
    let creation: CreationItem
    @State private var isHovered = false
    @EnvironmentObject private var videoPlayerManager: VideoPlayerManager
    
    private var isSelected: Bool {
        videoPlayerManager.selectedCreationId == creation.id
    }
    
    var body: some View {
        Button(action: {
            playVideo()
        }) {
            VStack(alignment: .leading, spacing: 2) {
                Text(creation.topic)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "video")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Text(creation.quality)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.blue.opacity(0.3) : (isHovered ? Color.blue.opacity(0.1) : Color.clear))
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func playVideo() {
        print("CreationRow: playVideo() called for \(creation.topic)")
        // Find the first video file in the directory
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: creation.path, includingPropertiesForKeys: nil, options: [])
            print("CreationRow: Found \(contents.count) files in directory")
            if let videoFile = contents.first(where: { url in
                let ext = url.pathExtension.lowercased()
                return ["mp4", "mov", "avi", "mkv", "m4v"].contains(ext)
            }) {
                print("CreationRow: Found video file: \(videoFile.path)")
                videoPlayerManager.selectVideo(url: videoFile, topic: creation.topic, creationId: creation.id)
            } else {
                print("CreationRow: No video files found in directory")
            }
        } catch {
            print("Error finding video file: \(error)")
        }
    }
}

extension DateFormatter {
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}
