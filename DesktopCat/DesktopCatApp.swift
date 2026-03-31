//
//  DesktopCatApp.swift
//  DesktopCat
//
//  Created by Tohru Djunaedi Sato on 16/03/26.
//

import SwiftUI
import AppKit
import Combine

@main
struct DesktopCatApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var soundManager = SoundManager.shared
    
    var body: some Scene {
        MenuBarExtra("", systemImage: "cat"){
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "speaker.fill")
                        .foregroundColor(.secondary)
                    Slider(value: $soundManager.volume, in: 0...1)
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                Button(action: {
                    appDelegate.addCat()
                    soundManager.play(sound: "cat_sound_1")
                }) {
                    Text("More Cats")
                        // .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    NSWorkspace.shared.hideOtherApplications()
                }) {
                    Text("Show Cat")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("Bye bye")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .frame(width: 220)
        }
        .menuBarExtraStyle(.window)
    }
}

struct CatsContainerView: View {
    @ObservedObject var appDelegate: AppDelegate
    
    var body: some View {
        ZStack {
            Color.clear
            ForEach(appDelegate.controllers) { controller in
                CatView(controller: controller)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var panel: DesktopPanel?
    @Published var controllers: [CatBehaviorController] = []
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let screenBounds = NSScreen.main?.frame ?? .zero //how big is the monitor rn?
        let newPanel = DesktopPanel(contentRect: screenBounds)
        
        DesktopFileScanner.shared.startScanning()
        
        // Spawn the first cat
        addCat()
        
        let hostingView = NSHostingView(rootView: CatsContainerView(appDelegate: self))
        hostingView.frame = screenBounds
        newPanel.contentView = hostingView
        newPanel.makeKeyAndOrderFront(nil)
        self.panel = newPanel
    }
    
    func addCat() {
        let newController = CatBehaviorController()
        let screenBounds = NSScreen.main?.frame ?? .zero
        
        newController.onHoverStateChange = { [weak self] _ in
            self?.updateHoverState()
        }
        
        controllers.append(newController)
        newController.setup(screenBounds: screenBounds)
        newController.start()
    }
    
    private func updateHoverState() {
        let isAnyHovering = controllers.contains(where: { $0.isHovering })
        panel?.ignoresMouseEvents = !isAnyHovering
    }
}
