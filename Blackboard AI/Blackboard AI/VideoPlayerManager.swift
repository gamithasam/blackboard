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
    
    func selectVideo(url: URL, topic: String) {
        self.selectedVideoURL = url
        self.selectedVideoTopic = topic
    }
}
