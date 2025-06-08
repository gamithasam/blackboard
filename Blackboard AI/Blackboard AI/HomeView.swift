//
//  HomeView.swift
//  Blackboard AI
//
//  Created by Gamitha Samarasingha on 2025-06-08.
//

import SwiftUI
import AVKit

struct HomeView: View {
    @State private var isProcessing: Bool = false
    @State private var videoURL: URL?
    @State private var inputText: String = ""
    
    var body: some View {
        NavigationSplitView {
            // Sidebar view
            SidebarView()
        } detail: {
            VStack {
                ZStack {
                    if let url = videoURL {
                        VideoPlayer(player: AVPlayer(url: url))
                            .aspectRatio(16/9, contentMode: .fit)
                            .cornerRadius(12)
                            .padding()
                    } else if isProcessing {
                        ProgressView("Generating...")
                            .progressViewStyle(CircularProgressViewStyle())
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
                    TextField("Type your topic...", text: $inputText, axis: .vertical)
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
                            // Handle send action
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
            .background(Color.black)
        }
    }
}

#Preview {
    HomeView()
}
