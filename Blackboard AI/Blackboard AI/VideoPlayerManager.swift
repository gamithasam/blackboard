//
//  VideoPlayerManager.swift
//  Blackboard AI
//
//  Created by Gamitha Samarasingha on 2025-06-20.
//


import Foundation
import SwiftUI

class VideoPlayerManager: ObservableObject {
    @Published var selectedVideoURL: URL?
    @Published var selectedVideoTopic: String = ""
    @Published var selectedCreationId: UUID?
    @Published var pendingSelectionVideoPath: String?
    @Published var pendingSelectionTopic: String?
    
    func selectVideo(url: URL, topic: String, creationId: UUID) {
        self.selectedVideoURL = url
        self.selectedVideoTopic = topic
        self.selectedCreationId = creationId
        // Clear pending selection since we have an explicit selection
        self.pendingSelectionVideoPath = nil
        self.pendingSelectionTopic = nil
    }
    
    func setPendingSelection(videoPath: String, topic: String) {
        self.pendingSelectionVideoPath = videoPath
        self.pendingSelectionTopic = topic
    }
    
    func checkAndSelectPendingVideo(creations: [CreationItem]) {
        guard let pendingPath = pendingSelectionVideoPath,
              let pendingTopic = pendingSelectionTopic else { return }
        
        // Find the creation that contains the pending video
        for creation in creations {
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: creation.path, includingPropertiesForKeys: nil, options: [])
                if let videoFile = contents.first(where: { url in
                    url.path == pendingPath
                }) {
                    // Found the matching creation, select it
                    selectVideo(url: videoFile, topic: creation.topic, creationId: creation.id)
                    return
                }
            } catch {
                continue
            }
        }
    }
}
