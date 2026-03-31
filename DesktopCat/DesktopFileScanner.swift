//
//  DesktopFileScanner.swift
//  DesktopCat
//
//  Created by Tohru Djunaedi Sato on 21/03/26.
//

import AppKit
import Combine

struct DesktopFileInfo {
    let name: String
    let position: CGPoint
}

// Scans desktop file icon positions and can reposition them
class DesktopFileScanner: ObservableObject {
    static let shared = DesktopFileScanner()
    
    @Published var files: [DesktopFileInfo] = []
    
    private var timer: Timer?
    private let scanInterval: TimeInterval
    
    private init(scanInterval: TimeInterval = 5.0) {
        self.scanInterval = scanInterval
    }
    
    func startScanning() {
        guard timer == nil else { return }
        scan()
        timer = Timer.scheduledTimer(withTimeInterval: scanInterval, repeats: true) { [weak self] _ in
            self?.scan()
        }
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    func stopScanning() {
        timer?.invalidate()
        timer = nil
    }
    
    func nearestFile(to point: CGPoint) -> DesktopFileInfo? {
        return files.min(by: { distance($0.position, point) < distance($1.position, point) })
    }
    
    // Moves a file's desktop icon to a new position
    func moveIconPosition(named name: String, to newPosition: CGPoint) {
        let escapedName = name.replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "Finder"
            set desktop position of file "\(escapedName)" of desktop to {\(Int(newPosition.x)), \(Int(newPosition.y))}
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            if let error = error {
                print("[DesktopCat] Failed to move icon: \(error)")
            }
        }
    }
    
    // Gets the actual file icon (thumbnail) for a desktop file.
    func fileIcon(named name: String) -> NSImage {
        let desktopURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop").appendingPathComponent(name)
        return NSWorkspace.shared.icon(forFile: desktopURL.path)
    }
    
    // MARK: - Private
    
    private func scan() {
        //
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let found = Self.queryDesktopIcons()
            DispatchQueue.main.async {
                self?.files = found
            }
        }
    }
    
    // Uses AppleScript to get exact desktop icon positions from Finder.
    static func queryDesktopIcons() -> [DesktopFileInfo] {
        let script = """
        tell application "Finder"
            set output to ""
            set desktopItems to every item of desktop
            repeat with anItem in desktopItems
                set itemName to name of anItem
                set itemPos to desktop position of anItem
                set posX to item 1 of itemPos
                set posY to item 2 of itemPos
                set output to output & itemName & "|||" & posX & "|||" & posY & "\\n"
            end repeat
            return output
        end tell
        """
        
        guard let appleScript = NSAppleScript(source: script) else { return [] }
        
        var errorInfo: NSDictionary?
        let result = appleScript.executeAndReturnError(&errorInfo)
        
        if let error = errorInfo {
            print("[DesktopCat] AppleScript error: \(error)")
            return []
        }
        
        guard let output = result.stringValue else { return [] }
        
        var icons: [DesktopFileInfo] = []
        for line in output.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            
            let parts = trimmed.components(separatedBy: "|||")
            guard parts.count == 3,
                  let x = Double(parts[1].trimmingCharacters(in: .whitespaces)),
                  let y = Double(parts[2].trimmingCharacters(in: .whitespaces)) else { continue }
            
            icons.append(DesktopFileInfo(name: parts[0], position: CGPoint(x: x, y: y)))
        }
        
        return icons
    }
}

private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
    let dx = a.x - b.x
    let dy = a.y - b.y
    return sqrt(dx * dx + dy * dy)
}
