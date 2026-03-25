//
//  DesktopPanel.swift
//  DesktopCat
//
//  Created by Tohru Djunaedi Sato on 16/03/26.
//

import AppKit
import SwiftUI

class DesktopPanel : NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        
        // set the application to desktop-level + 1
        // klo disamain desktop-level somehow malah ke belakang..?
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
    }
    
//    //buat sleeping cat nanti
//    override var canBecomeKey: Bool {
//        return true
//    }
}
