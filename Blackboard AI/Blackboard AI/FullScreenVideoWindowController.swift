//
//  FullScreenVideoWindowController.swift
//  Blackboard AI
//
//  Created by Gamitha Samarasingha on 2025-06-20.
//

import Cocoa
import SwiftUI
import AVKit

class FullScreenVideoWindowController: NSWindowController {
    private var onClose: (() -> Void)?
    private var player: AVPlayer

    init(player: AVPlayer, onClose: @escaping () -> Void) {
        self.player = player
        self.onClose = onClose
        super.init(window: nil)

        let contentView = ZStack {
            // Full black background that covers everything
            Rectangle()
                .fill(Color.black)
                .ignoresSafeArea(.all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Video player that takes up the full screen
            VideoPlayer(player: player)
                .ignoresSafeArea(.all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Minimal close button overlay
            VStack {
                HStack {
                    Spacer()
                    Button(action: { [weak self] in
                        self?.handleClose()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding()
                }
                Spacer()
            }
        }
        let hostingController = NSHostingController(rootView: AnyView(contentView))
        let window = NSWindow(contentViewController: hostingController)
        
        // Configure window for true full-screen experience
        window.styleMask = [.borderless, .fullSizeContentView]
        window.level = .screenSaver  // Higher level to cover dock and menu bar
        window.backgroundColor = .black
        window.hasShadow = false
        window.isOpaque = true
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.canHide = false
        
        // Make it truly full screen by covering all screens
        let screenFrame = NSScreen.main?.frame ?? CGRect.zero
        window.setFrame(screenFrame, display: true, animate: false)
        
        self.window = window
        self.window?.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func handleClose() {
        self.close()
        self.onClose?()
    }

    func showFullScreen() {
        guard let window = self.window else { return }
        window.makeKeyAndOrderFront(nil)
        // Window is already sized to full screen, no need to toggle
    }
}

extension FullScreenVideoWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        onClose?()
    }
}
