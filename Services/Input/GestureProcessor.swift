//
//  GestureProcessor.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import Foundation
import SwiftUI

@MainActor
class GestureProcessor: ObservableObject {
    enum GestureState {
        case idle
        case possibleTap
        case dragging
        case scrolling
        case zooming
        case dragAndDrop
    }

    @Published private(set) var state: GestureState = .idle

    private var lastUpdateTime: Date?
    private var pendingSingleTap: (() -> Void)?
    private var doubleTapTimer: Timer?

    private let throttleInterval = Constants.gestureThrottleInterval

    // MARK: - Tap Gestures

    func handleSingleTap(completion: @escaping () -> Void) {
        // Check if we're waiting for a possible double-tap
        if pendingSingleTap != nil {
            // This is a double-tap, cancel pending single tap
            doubleTapTimer?.invalidate()
            pendingSingleTap = nil

            // Execute double-tap (two left clicks)
            completion()
            completion()
        } else {
            // Wait to see if this becomes a double-tap
            pendingSingleTap = completion

            doubleTapTimer = Timer.scheduledTimer(withTimeInterval: Constants.doubleTapDelay, repeats: false) { [weak self] _ in
                guard let self else { return }

                // No second tap detected, execute single tap
                self.pendingSingleTap?()
                self.pendingSingleTap = nil
            }
        }
    }

    func handleTwoFingerTap(completion: @escaping () -> Void) {
        // Two-finger tap is always a right-click, no delay needed
        completion()
    }

    // MARK: - Drag Gestures

    func handleDragStart() {
        state = .dragging
        lastUpdateTime = Date()
        print("DEBUG GestureProcessor: handleDragStart - state now: \(state)")
    }

    func handleDragChange(translation: CGSize, completion: @escaping (Int8, Int8) -> Void) {
        print("DEBUG GestureProcessor: handleDragChange called - state: \(state), translation: \(translation)")

        guard state == .dragging else {
            print("DEBUG GestureProcessor: REJECTED - state is not dragging")
            return
        }

        // Throttle updates
        if let lastUpdate = lastUpdateTime,
           Date().timeIntervalSince(lastUpdate) < throttleInterval {
            print("DEBUG GestureProcessor: THROTTLED")
            return
        }

        // Apply acceleration curve and invert axes
        let acceleratedX = applyAcceleration(-translation.width)
        let acceleratedY = applyAcceleration(-translation.height)

        let dx = ProtocolEncoder.deltaToInt8(acceleratedX)
        let dy = ProtocolEncoder.deltaToInt8(acceleratedY)

        print("DEBUG GestureProcessor: Calling completion with dx: \(dx), dy: \(dy) (accelerated from \(translation))")
        completion(dx, dy)
        lastUpdateTime = Date()
    }

    /// Applies velocity-based acceleration to mouse movement
    /// Small movements: ~1.5x, Medium: ~2-3x, Large: ~4x
    private func applyAcceleration(_ value: CGFloat) -> CGFloat {
        let absValue = abs(value)
        let sign = value < 0 ? -1.0 : 1.0

        // Acceleration curve: starts at 1.5x, increases with speed
        // Uses a power curve for smooth acceleration
        let baseMultiplier: CGFloat = 1.5
        let speedFactor: CGFloat = 0.05
        let acceleratedValue = absValue * (baseMultiplier + pow(absValue * speedFactor, 1.2))

        return sign * acceleratedValue
    }

    func handleDragEnd() {
        state = .idle
        lastUpdateTime = nil
        print("DEBUG GestureProcessor: handleDragEnd - state now: \(state)")
    }

    // MARK: - Scroll Gestures

    func handleScrollStart() {
        state = .scrolling
        lastUpdateTime = Date()
    }

    func handleScrollChange(translation: CGSize, completion: @escaping (Int8?, Int8?) -> Void) {
        guard state == .scrolling else { return }

        // Throttle updates
        if let lastUpdate = lastUpdateTime,
           Date().timeIntervalSince(lastUpdate) < throttleInterval {
            return
        }

        // Determine primary scroll direction
        let absX = abs(translation.width)
        let absY = abs(translation.height)

        var verticalDelta: Int8?
        var horizontalDelta: Int8?

        if absY > absX {
            // Vertical scroll is dominant
            verticalDelta = ProtocolEncoder.deltaToInt8(-translation.height)
        } else {
            // Horizontal scroll is dominant
            horizontalDelta = ProtocolEncoder.deltaToInt8(translation.width)
        }

        completion(verticalDelta, horizontalDelta)
        lastUpdateTime = Date()
    }

    func handleScrollEnd() {
        state = .idle
        lastUpdateTime = nil
    }

    // MARK: - Long Press + Drag (Drag & Drop)

    func handleLongPressStart(completion: @escaping () -> Void) {
        state = .dragAndDrop
        completion() // Send mouse down
    }

    func handleLongPressDrag(translation: CGSize, completion: @escaping (Int8, Int8) -> Void) {
        guard state == .dragAndDrop else { return }

        // Throttle updates
        if let lastUpdate = lastUpdateTime,
           Date().timeIntervalSince(lastUpdate) < throttleInterval {
            return
        }

        // Apply acceleration curve and invert axes
        let acceleratedX = applyAcceleration(-translation.width)
        let acceleratedY = applyAcceleration(-translation.height)

        let dx = ProtocolEncoder.deltaToInt8(acceleratedX)
        let dy = ProtocolEncoder.deltaToInt8(acceleratedY)

        completion(dx, dy)
        lastUpdateTime = Date()
    }

    func handleLongPressEnd(completion: @escaping () -> Void) {
        completion() // Send mouse up
        state = .idle
        lastUpdateTime = nil
    }

    // MARK: - Zoom Gestures

    func handleZoomStart() {
        state = .zooming
    }

    func handleZoomChange(scale: CGFloat, completion: @escaping (UInt8) -> Void) {
        guard state == .zooming else { return }

        let zoomValue = ProtocolEncoder.scaleToUInt8(scale)
        completion(zoomValue)
    }

    func handleZoomEnd() {
        state = .idle
    }
}
