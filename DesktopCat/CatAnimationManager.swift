//
//  CatAnimationManager.swift
//  DesktopCat
//
//  Created by Tohru Djunaedi Sato on 21/03/26.
//

import SwiftUI

enum CatAnimation: String {
    case idle
    case walking
    case sleeping
    case sleepingExtended
    case poking
    case wakingUp
    case scruffed
    
    var frames: [String] {
        switch self {
        case .idle:
            return ["default_left_1", "default_left_2", "default_left_3"]
        case .walking:
            return ["walking_left_1", "walking_left_2", "walking_left_2", "walking_left_3"]
        case .sleeping:
            return ["sleep_left_1",
                    "sleep_left_2",
                    "sleep_left_3",
                    "sleep_left_4",
                    "sleep_left_5"]
        case .sleepingExtended:
            return ["sleep_left_4",
                    "sleep_left_5"]
        case .wakingUp:
            return ["sleep_left_5",
                    "sleep_left_4",
                    "sleep_left_3",
                    "sleep_left_2",
                    "sleep_left_1"]
        case .poking:
            return ["poking_left_1", "poking_left_3"]
        case .scruffed:
            return ["scruffed_left_1", "scruffed_left_2", "scruffed_left_3"]
        }

    }
    
    var frameInterval: TimeInterval {
        switch self {
        case .idle: return 0.2
        case .walking: return 0.15
        case .sleeping: return 0.3
        case .sleepingExtended: return 0.6
        case .wakingUp: return 0.2
        case .poking: return 0.2
        case .scruffed: return 0.1
        }
    }
}

class CatAnimationManager {
    var currentFrame: String = "default_left_1"
    var facingRight: Bool = false
    
    var currentAnimation: CatAnimation = .idle
    var frameIndex: Int = 0
    var lastFrameTime: Date = .now
    
    // Switch to a different animation set
    func setAnimation(_ animation: CatAnimation) {
        guard animation != currentAnimation else { return }
        currentAnimation = animation
        frameIndex = 0
        currentFrame = currentAnimation.frames[0]
        lastFrameTime = .now
    }
    
    func setFacing(right: Bool) {
        facingRight = right
    }
    
    // update frame
    func update(at date: Date) {
        let nextFrameIndex = frameIndex + 1
        
        let elapsed = date.timeIntervalSince(lastFrameTime)
        if elapsed >= currentAnimation.frameInterval {
            let frames = currentAnimation.frames
            
            if nextFrameIndex >= frames.count {
                // kalo sleep, lanjut ke sleeping extended
                if currentAnimation == .sleeping {
                    self.setAnimation(.sleepingExtended)
                } else if currentAnimation == .sleepingExtended{
                    // kalo sleep extended lanjut bangun
                    self.setAnimation(.wakingUp)
                }
                else {
                    frameIndex = 0
                    currentFrame = frames[frameIndex]
                }
            } else {
                frameIndex = nextFrameIndex
                currentFrame = frames[frameIndex]
            }
            
//            frameIndex = (frameIndex + 1) % frames.count
//            currentFrame = frames[frameIndex]
            lastFrameTime = date
        }
    }
}
