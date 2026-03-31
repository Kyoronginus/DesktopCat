//
//  SoundManager.swift
//  DesktopCat
//
//  Created by Tohru Djunaedi Sato on 27/03/26.
//
import AVFoundation
import Combine
import AppKit

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    @Published var isPlaying: Bool = false
    @Published var volume: Float = 0.5 {
        didSet {
            player?.volume = volume
        }
    }

    var player: AVAudioPlayer?
    
    func play(sound: String) {
        guard let asset = NSDataAsset(name: sound) else {
            print("SFX not found")
            return
        }
        player = try? AVAudioPlayer(data: asset.data)
        player?.volume = volume
        player?.play()
    }
}
