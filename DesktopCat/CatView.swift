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
    @State private var lastDragSample: (point: CGPoint, time: TimeInterval)?
    @State private var prevDragSample: (point: CGPoint, time: TimeInterval)?
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let date = context.date
            let _ = DispatchQueue.main.async { controller.update(at: date) }
                ZStack() {
                    // Show the file icon above the cat while clicked an hdoldd
                    if let icon = controller.carriedFileIcon {
                        Image(nsImage: icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .shadow(color: .black.opacity(0.7), radius: 4, y: 2)
                            .transition(.scale)
                            .offset(x: 0, y: -20)
                    }

                    Image(controller.currentFrame)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .scaleEffect(
                            x: (controller.facingRight ? -1 : 1) * (1.0 + controller.zHeight / 100),
                            y: 1.0 + controller.zHeight / 100
                        )
                    
                    if controller.catState == .thrown {
                        Image("angry_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .offset(x: -25, y: -35)
                            .scaleEffect(
                                x: (controller.facingRight ? -1 : 1) * (1.0 + controller.zHeight / 100),
                                y: 1.0 + controller.zHeight / 100
                            )
                    }

                }
                .animation(.easeInOut(duration: 0.2), value: controller.carriedFileIcon != nil)
                .position(controller.catPosition)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if !controller.isDragging {
                                controller.isDragging = true
                                dragStartPos = controller.catPosition
                                
                                lastDragSample = nil
                                prevDragSample = nil
                            }
                            controller.catPosition = CGPoint(
                                x: dragStartPos.x + value.translation.width,
                                y: dragStartPos.y + value.translation.height
                            )
                            
                            // Record samples for velocity
                            let currentPoint = value.location
                            let currentTime = value.time.timeIntervalSinceReferenceDate
                            if let last = lastDragSample {
                                prevDragSample = last
                            }
                            lastDragSample = (currentPoint, currentTime)
                        }
                        .onEnded { _ in
//                            controller.isDragging = false
                            let velocity = computeVelocity(from: prevDragSample, to: lastDragSample)
                            controller.handleDrop(velocity: velocity)
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
    
    private func computeVelocity(from previous: (point: CGPoint, time: TimeInterval)?, to latest: (point: CGPoint, time: TimeInterval)?) -> CGVector? {
        guard let prev = previous, let last = latest else { return nil }
        let dt = max(1e-3, last.time - prev.time)
        let dx = last.point.x - prev.point.x
        let dy = last.point.y - prev.point.y
        let vx = dx / dt
        let vy = dy / dt
        return CGVector(dx: vx, dy: vy)
    }
}
