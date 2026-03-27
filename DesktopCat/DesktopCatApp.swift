//
//  DesktopCatApp.swift
//  DesktopCat
//
//  Created by Tohru Djunaedi Sato on 16/03/26.
//

import SwiftUI
import AppKit
import Playgrounds
import Combine

@main
struct DesktopCatApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("", systemImage: "cat"){
            Button("More Cats") {
                appDelegate.addCat()
                
            }
            Button("Show Cat") {
                NSWorkspace.shared.hideOtherApplications()
            }
            Button("Bye bye") {
                NSApplication.shared.terminate(self)
            }
        }
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
