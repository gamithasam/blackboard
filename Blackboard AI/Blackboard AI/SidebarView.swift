//
//  SidebarView.swift
//  Blackboard AI
//
//  Created by Gamitha Samarasingha on 2025-06-08.
//

import SwiftUI
import Foundation

struct SidebarView: View {
    @State private var creations: [CreationItem] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                // HStack {
                //     Image(systemName: "clock.arrow.circlepath")
                //         .foregroundColor(.blue)
                //     Text("History")
                //         .font(.title2)
                //         .fontWeight(.semibold)
                // }
                // .padding(.horizontal)
                // .padding(.top)
                
                // Divider()
                //     .padding(.vertical, 8)
                
                if isLoading {
                    VStack {
                        ProgressView()
                        Text("Loading history...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if creations.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No creations yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Your video creations will appear here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(creations, id: \.self) { creation in
                            CreationRow(creation: creation)
                        }
                    }
                    .listStyle(SidebarListStyle())
                }
            }
        }
        .navigationTitle("History")
        .onAppear {
            loadCreations()
            // Observer for video creation notifications
            NotificationCenter.default.addObserver(
                forName: .videoCreationCompleted,
                object: nil,
                queue: .main
            ) { _ in
                loadCreations()
            }
        }
        .onDisappear {
            // Remove observer when view disappears
            NotificationCenter.default.removeObserver(self, name: .videoCreationCompleted, object: nil)
        }
        .refreshable {
            loadCreations()
        }
    }
    
    private func loadCreations() {
        isLoading = true
        
        Task {
            do {
                let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
                let videosPath = URL(fileURLWithPath: "\(homeDir)/Documents/Blackboard/media/videos")
                let creations = try await scanForCreations(at: videosPath)
                
                await MainActor.run {
                    self.creations = creations
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.creations = []
                    self.isLoading = false
                }
                print("Error loading creations: \(error)")
            }
        }
    }
    
    private func scanForCreations(at url: URL) async throws -> [CreationItem] {
        let fileManager = FileManager.default
        var creations: [CreationItem] = []
        
        guard fileManager.fileExists(atPath: url.path) else {
            return creations
        }
        
        let topicContents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.creationDateKey], options: [.skipsHiddenFiles])
        
        for topicURL in topicContents {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: topicURL.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else { continue }
            
            let topicName = topicURL.lastPathComponent
            
            do {
                let qualityContents = try fileManager.contentsOfDirectory(at: topicURL, includingPropertiesForKeys: [.creationDateKey], options: [.skipsHiddenFiles])
                
                for qualityURL in qualityContents {
                    var isQualityDirectory: ObjCBool = false
                    guard fileManager.fileExists(atPath: qualityURL.path, isDirectory: &isQualityDirectory),
                          isQualityDirectory.boolValue else { continue }
                    
                    let qualityName = qualityURL.lastPathComponent
                    
                    // Check if this quality folder contains video files
                    do {
                        let videoFiles = try fileManager.contentsOfDirectory(at: qualityURL, includingPropertiesForKeys: [.creationDateKey], options: [.skipsHiddenFiles])
                        
                        if !videoFiles.isEmpty {
                            // Get creation date
                            let resourceValues = try qualityURL.resourceValues(forKeys: [.creationDateKey])
                            let creationDate = resourceValues.creationDate ?? Date()
                            
                            let creation = CreationItem(
                                topic: topicName,
                                quality: qualityName,
                                path: qualityURL,
                                createdDate: creationDate
                            )
                            creations.append(creation)
                        }
                    } catch {
                        // Skip this quality folder if we can't read its contents
                        continue
                    }
                }
            } catch {
                // Skip this topic folder if we can't read its contents
                continue
            }
        }
        
        return creations.sorted { $0.createdDate > $1.createdDate }
    }
}

#Preview {
    SidebarView()
}
