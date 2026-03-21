//
//  DesktopCatApp.swift
//  DesktopCat
//
//  Created by Tohru Djunaedi Sato on 16/03/26.
//

import SwiftUI
import AppKit

@main
struct DesktopCatApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: DesktopPanel?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let screenBounds = NSScreen.main?.frame ?? .zero //how big is the monitor rn?
        let newPanel = DesktopPanel(contentRect: screenBounds)
        let hostingView = NSHostingView(rootView: CatView())
        hostingView.frame = screenBounds
        newPanel.contentView = hostingView
        newPanel.makeKeyAndOrderFront(nil)
        self.panel = newPanel
    }
}
