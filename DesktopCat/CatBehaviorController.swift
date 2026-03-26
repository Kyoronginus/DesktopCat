//
//  CatBehaviorController.swift
//  DesktopCat
//
//  Created by Tohru Djunaedi Sato on 21/03/26.
//

import SwiftUI
import Combine

enum CatState {
    case idle
    case walkingToFile
    case nearFile
    case carryingFile
    case droppingFile
    case sleep
    case poking
    case thrown
    
}

class CatBehaviorController: ObservableObject {
    @Published var catPosition: CGPoint = .zero
    @Published var catState: CatState = .idle
    @Published var currentFrame: String = "default_left_1"
    @Published var facingRight: Bool = false
    @Published var carriedFileName: String? = nil
    @Published var carriedFileIcon: NSImage? = nil
    @Published var isDragging: Bool = false
    @Published var velocity: CGPoint = .zero
    @Published var zHeight: CGFloat = 0
    
    let animationManager = CatAnimationManager()
    let fileScanner = DesktopFileScanner(scanInterval: 5.0)
    
    private var zVelocity: Double = 0
    
    private let interactionDistance: CGFloat = 50.0
    
    private let moveSpeed: CGFloat = 200.0
    private let interactionDelay: TimeInterval = 2.0
    private let PickupChance: Double = 0.3
    private let PokingChance: Double = 0.7
    private let nearestChance: Double = 0.4
    
    private var targetFile: DesktopFileInfo?
    private var carryDestination: CGPoint = .zero
    private var screenBounds: CGRect = .zero
    
    private var stateEnteredAt: Date = .now
    private var lastUpdateDate: Date = .now
    private var deltaTime: CGFloat = 0
    private var wasHovering: Bool = false
    
    var onHoverStateChange: ((Bool) -> Void)?
    
    func setup(screenBounds: CGRect) {
        self.screenBounds = screenBounds
        catPosition = CGPoint(
            x: screenBounds.midX,
            y: screenBounds.maxY - 80
        )
    }
    
    func start() {
        fileScanner.startScanning()
        lastUpdateDate = .now
        stateEnteredAt = .now
    }
    
    func stop() {
        fileScanner.stopScanning()
    }
    
    func update(at date: Date) {
        deltaTime = CGFloat(date.timeIntervalSince(lastUpdateDate))
        // Clamp to avoid huge jumps on first frame or lag spikes
        deltaTime = min(deltaTime, 0.1)
        lastUpdateDate = date
        
        // Update animation frame
        animationManager.update(at: date)
        currentFrame = animationManager.currentFrame
        facingRight = animationManager.facingRight
        
        // Hover detection
        let appKitMouse = NSEvent.mouseLocation
        let swiftUIMouse = CGPoint(x: appKitMouse.x, y: screenBounds.height - appKitMouse.y)
        let isHovering = pointDistance(swiftUIMouse, catPosition) < 80.0 // kekecilan?
        
        if isHovering != wasHovering {
            wasHovering = isHovering
            onHoverStateChange?(isHovering)
            
            
        }
        
        // Pause action while being dragged
        if isDragging {
            stateEnteredAt = date
            return
        }
        
        // Update behavior
        switch catState {
        case .idle:
            findAndWalkToFile()
            
        case .sleep:
            let elapsed = date.timeIntervalSince(stateEnteredAt)
            // Sleep duration randomly changes
            let sleepDurationVariable: Double = Double.random(in: 2.0...10.0)
            if elapsed >= interactionDelay * sleepDurationVariable {
                catState = .idle
                stateEnteredAt = date
            }
            
        case .walkingToFile:
            walkTowardsTarget()
            
        case .nearFile:
            // Wait for interactionDelay, then decide
            let elapsed = date.timeIntervalSince(stateEnteredAt)
            if elapsed >= interactionDelay {
                decideInteraction()
            }
            
        case .carryingFile:
            walkTowardsDropPoint()
            
        case .droppingFile:
            let elapsed = date.timeIntervalSince(stateEnteredAt)
            if elapsed >= 1.5 {
                catState = .idle
                stateEnteredAt = date
            }
            
        case .poking:
            let elapsed = date.timeIntervalSince(stateEnteredAt)
            let pokingDurationVariable: Double = Double.random(in: 2.0...5.0)
            if elapsed >= interactionDelay * pokingDurationVariable {
                catState = .idle
                stateEnteredAt = date
            }
            
        case .thrown:
            // physic sim
            simulatePhysics()
            
        }
    }

    
    private func findAndWalkToFile() {
        // use rng to decide the next destination
        // antara nearest / random
        if Double.random(in: 0..<1) < self.nearestChance {
            guard let nearest = fileScanner.nearestFile(to: catPosition) else { return }
            targetFile = nearest
        } else {
            guard let randomFile = fileScanner.files.randomElement() else { return }
            targetFile = randomFile
        }

        catState = .walkingToFile
        animationManager.setAnimation(.walking)
        stateEnteredAt = lastUpdateDate
    }
    
    private func sleepOnFile() {
        catState = .sleep
        animationManager.setAnimation(.sleeping)
        stateEnteredAt = lastUpdateDate
    }
    
    private func pokingFile(){
        catState = .poking
        animationManager.setAnimation(.poking)
        stateEnteredAt = lastUpdateDate
    }
    
    private func walkTowardsTarget() {
        guard let target = targetFile else {
            catState = .idle
            return
        }
        
        let dist = pointDistance(catPosition, target.position)
        
        if dist <= interactionDistance {
            catState = .nearFile
            animationManager.setAnimation(.idle)
            stateEnteredAt = lastUpdateDate
        } else {
            moveTowards(target.position)
        }
    }
    
    private func decideInteraction() {
        guard let file = targetFile else {
            catState = .idle
            stateEnteredAt = lastUpdateDate
            return
        }
        
        let interactionDecider: Double = Double.random(in: 0...1)
        
        if interactionDecider < self.PickupChance {
            // Hide the file from desktop by moving it to temp
            let desktopURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(file.name)
            try? FileManager.default.moveItem(at: desktopURL.appendingPathComponent(file.name), to: tempURL)
            
            // Pick up the file
            carriedFileName = file.name
            carriedFileIcon = fileScanner.fileIcon(named: file.name)
            carryDestination = randomDropPoint()
            catState = .carryingFile
            animationManager.setAnimation(.walking)
            stateEnteredAt = lastUpdateDate
        } else if interactionDecider < self.PokingChance{
            // poke file nya
            pokingFile()
        } else {
            // sleep
            sleepOnFile()
            targetFile = nil
        }
    }
    
    private func walkTowardsDropPoint() {
        let dist = pointDistance(catPosition, carryDestination)
        
        if dist <= interactionDistance {
            dropFile()
        } else {
            moveTowards(carryDestination)
        }
    }
    
    private func dropFile() {
        if let fileName = carriedFileName {
            // Restore file from temp back to desktop
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            let desktopURL = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Desktop")
                .appendingPathComponent(fileName)
            try? FileManager.default.moveItem(at: tempURL, to: desktopURL)
            
            // Reposition the icon at the drop location
            fileScanner.moveIconPosition(named: fileName, to: catPosition)
        }
        
        carriedFileName = nil
        carriedFileIcon = nil
        catState = .droppingFile
        targetFile = nil
        animationManager.setAnimation(.idle)
        stateEnteredAt = lastUpdateDate
        
        fileScanner.stopScanning()
        fileScanner.startScanning()
    }
    
    private func moveTowards(_ target: CGPoint) {
        let dx = target.x - catPosition.x
        let dy = target.y - catPosition.y
        let angle = atan2(dy, dx)
        
        animationManager.setFacing(right: dx > 0)
        
        let step = moveSpeed * deltaTime
        catPosition = CGPoint(
            x: catPosition.x + cos(angle) * step,
            y: catPosition.y + sin(angle) * step
        )
    }
    
    private func randomDropPoint() -> CGPoint {
        let margin: CGFloat = 150
        let x = CGFloat.random(in: margin...(screenBounds.width - margin))
        let y = CGFloat.random(in: margin...(screenBounds.height - margin))
        return CGPoint(x: x, y: y)
    }
    
    func handleDrop(velocity: CGVector?) {
        self.isDragging = false
        
        guard carriedFileName == nil else {
            dropFile()
            return
        }
        
        if let v = velocity, sqrt(v.dx*v.dx + v.dy*v.dy) > 200 {
            self.catState = .thrown
            self.velocity = CGPoint(x: v.dx, y: v.dy)
            self.zVelocity = 500
        } else {
            self.catState = .idle
        }
    }
    
    private func simulatePhysics() {
        let gravity: Double = 900.0
        let groundFriction: Double = 0.5
//        let airResistance: Double = 0.99
        
        
        
        self.zVelocity -= CGFloat(gravity * deltaTime)
        self.zHeight += self.zVelocity * CGFloat(deltaTime)
        
        self.catPosition.x += self.velocity.x * CGFloat(deltaTime)
        self.catPosition.y += self.velocity.y * CGFloat(deltaTime)
        

        if self.catPosition.x < screenBounds.minX || self.catPosition.x > screenBounds.maxX{
            if self.catPosition.x < screenBounds.minX{
                catPosition.x = screenBounds.minX
            } else {
                catPosition.x = screenBounds.maxX
            }
            self.velocity.x *= -0.5
        }
        
        if self.catPosition.y < screenBounds.minY || self.catPosition.y > screenBounds.maxY{
            if self.catPosition.y < screenBounds.minY{
                catPosition.y = screenBounds.minY
            } else {
                catPosition.y = screenBounds.maxY
            }
            self.velocity.y *= -0.5
        }
        
        
        if self.zHeight < 0 {
            self.zHeight = 0
            self.velocity.x *= CGFloat(groundFriction)
            self.velocity.y *= CGFloat(groundFriction)
        } else {
            
            
//            self.velocity.x *= CGFloat(airResistance)
//            self.velocity.y *= CGFloat(airResistance)
        }
        
        if abs(self.velocity.x) < 0.01 && abs(self.velocity.y) < 0.01  {
            self.zVelocity = 0
            catState = .idle
        }
    }
}

func pointDistance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
    let dx = a.x - b.x
    let dy = a.y - b.y
    return sqrt(dx * dx + dy * dy)
}


