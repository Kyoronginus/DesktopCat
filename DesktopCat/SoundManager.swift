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
    @Published var isPlaying: Bool = false

    var player: AVAudioPlayer?
    
    func play(sound: String) {
        guard let asset = NSDataAsset(name: sound) else {
            print("SFX not found")
            return
        }
        player = try? AVAudioPlayer(data: asset.data)
        player?.play()
    }
}
