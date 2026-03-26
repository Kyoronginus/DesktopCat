//
//  DesktopCatApp.swift
//  DesktopCat
//
//  Created by Tohru Djunaedi Sato on 16/03/26.
//

import SwiftUI
import AppKit
import Playgrounds

@main
struct DesktopCatApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("", systemImage: "cat"){
            Button("Show Cat"){
                NSWorkspace.shared.hideOtherApplications()
            }
            Button("Bye bye"){
                NSApplication.shared.terminate(self)
            }
        }
    }
}
class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: DesktopPanel?
    let catController = CatBehaviorController()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let screenBounds = NSScreen.main?.frame ?? .zero //how big is the monitor rn?
        let newPanel = DesktopPanel(contentRect: screenBounds)
        
        // Toggle window interactability based on mouse distance to cat
        newPanel.ignoresMouseEvents = true
        catController.onHoverStateChange = { [weak newPanel] isHovering in
            newPanel?.ignoresMouseEvents = !isHovering
        }
        
        // lempar instance catControler ke catView
        // dibikin jadi injection gini karena masalah transparent window yg ngehalang click. 
        let hostingView = NSHostingView(rootView: CatView(controller: catController))
        hostingView.frame = screenBounds
        newPanel.contentView = hostingView
        newPanel.makeKeyAndOrderFront(nil)
        self.panel = newPanel
    }
}
