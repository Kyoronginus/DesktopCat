//
//  CatView.swift
//  DesktopCat
//
//  Created by Tohru Djunaedi Sato on 16/03/26.
//

import SwiftUI

struct CatView: View {
    @ObservedObject var controller: CatBehaviorController
    @State private var dragStartPos: CGPoint = .zero
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let date = context.date
            let _ = DispatchQueue.main.async { controller.update(at: date) }
                VStack() {
                    // Show the file icon above the cat while clicked an hdoldd
                    if let icon = controller.carriedFileIcon {
                        Image(nsImage: icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .shadow(color: .black.opacity(0.7), radius: 4, y: 2)
                            .transition(.scale)
                            .offset(x: 0, y: 60)
                    }
                    
                    Image(controller.currentFrame)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .scaleEffect(x: controller.facingRight ? -1 : 1, y: 1)
                }
                .animation(.easeInOut(duration: 0.2), value: controller.carriedFileIcon != nil)
                .position(controller.catPosition)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !controller.isDragging {
                                controller.isDragging = true
                                dragStartPos = controller.catPosition
                            }
                            controller.catPosition = CGPoint(
                                x: dragStartPos.x + value.translation.width,
                                y: dragStartPos.y + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            controller.isDragging = false
                        }
                )
        }
        .onAppear {
            let screenBounds = NSScreen.main?.frame ?? .zero
            controller.setup(screenBounds: screenBounds)
            controller.start()
        }
        .onDisappear {
            controller.stop()
        }
        .edgesIgnoringSafeArea(.all)
    }
}
