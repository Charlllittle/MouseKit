//
//  GestureProcessor.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import Foundation
import SwiftUI

/// Processes and interprets touch gestures for mouse and keyboard input
/// Handles gesture recognition, acceleration curves, and gesture state management
@MainActor
class GestureProcessor: ObservableObject {
  /// Represents the current gesture state
  enum GestureState {
    case idle
    case possibleTap
    case dragging
    case scrolling
    case zooming
    case dragAndDrop
  }

  /// The current gesture state
  @Published private(set) var state: GestureState = .idle

  /// Last time a gesture was updated, used for throttling
  private var lastUpdateTime: Date?
  /// Pending single tap action, held until double-tap timeout expires
  private var pendingSingleTap: (() -> Void)?
  /// Timer for double-tap detection
  private var doubleTapTimer: Timer?

  /// Minimum interval between gesture updates for performance optimization
  private let throttleInterval = Constants.gestureThrottleInterval

  // MARK: - Tap Gestures

  /**
   Handles a single tap gesture with double-tap detection.
   If a second tap occurs within the timeout, triggers a double-tap instead.
  
   - Parameter completion: Closure to execute for each tap (called once for single tap, twice for double-tap)
   */
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

      doubleTapTimer = Timer.scheduledTimer(
        withTimeInterval: Constants.doubleTapDelay, repeats: false
      ) { [weak self] _ in
        guard let self else { return }
        // Timer runs on main thread, so we can safely access main-actor properties
        MainActor.assumeIsolated {
          // No second tap detected, execute single tap
          self.pendingSingleTap?()
          self.pendingSingleTap = nil
        }
      }
    }
  }

  /**
   Handles a two-finger tap gesture (right-click equivalent).
   Executes immediately without double-tap detection.
  
   - Parameter completion: Closure to execute for the right-click action
   */
  func handleTwoFingerTap(completion: @escaping () -> Void) {
    // Two-finger tap is always a right-click, no delay needed
    completion()
  }

  // MARK: - Drag Gestures

  /// Begins a drag gesture (mouse cursor movement)
  func handleDragStart() {
    state = .dragging
    lastUpdateTime = Date()
    print("DEBUG GestureProcessor: handleDragStart - state now: \(state)")
  }

  /**
   Processes drag movement with acceleration and throttling.
  
   - Parameters:
     - translation: The movement delta since last update
     - completion: Closure receiving the processed dx and dy movement values
   */
  func handleDragChange(translation: CGSize, completion: @escaping (Int8, Int8) -> Void) {
    print(
      "DEBUG GestureProcessor: handleDragChange called - state: \(state), translation: \(translation)"
    )

    guard state == .dragging else {
      print("DEBUG GestureProcessor: REJECTED - state is not dragging")
      return
    }

    // Throttle updates
    if let lastUpdate = lastUpdateTime,
      Date().timeIntervalSince(lastUpdate) < throttleInterval
    {
      print("DEBUG GestureProcessor: THROTTLED")
      return
    }

    // Apply acceleration curve and invert axes
    let acceleratedX = applyAcceleration(-translation.width)
    let acceleratedY = applyAcceleration(-translation.height)

    let dx = ProtocolEncoder.deltaToInt8(acceleratedX)
    let dy = ProtocolEncoder.deltaToInt8(acceleratedY)

    print(
      "DEBUG GestureProcessor: Calling completion with dx: \(dx), dy: \(dy) (accelerated from \(translation))"
    )
    completion(dx, dy)
    lastUpdateTime = Date()
  }

  /**
   Applies velocity-based acceleration to mouse movement using a power curve.
   Small movements: ~1.5x, Medium: ~2-3x, Large: ~4x
  
   - Parameter value: The raw movement value
   - Returns: The accelerated movement value
   */
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

  /// Ends a drag gesture and resets state
  func handleDragEnd() {
    state = .idle
    lastUpdateTime = nil
    print("DEBUG GestureProcessor: handleDragEnd - state now: \(state)")
  }

  // MARK: - Scroll Gestures

  /// Begins a scroll gesture (two-finger pan)
  func handleScrollStart() {
    state = .scrolling
    lastUpdateTime = Date()
  }

  /**
   Processes scroll movement, determining the dominant scroll direction.
  
   - Parameters:
     - translation: The movement delta since last update
     - completion: Closure receiving optional vertical and horizontal scroll deltas
   */
  func handleScrollChange(translation: CGSize, completion: @escaping (Int8?, Int8?) -> Void) {
    guard state == .scrolling else { return }

    // Throttle updates
    if let lastUpdate = lastUpdateTime,
      Date().timeIntervalSince(lastUpdate) < throttleInterval
    {
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

  /// Ends a scroll gesture and resets state
  func handleScrollEnd() {
    state = .idle
    lastUpdateTime = nil
  }

  // MARK: - Long Press + Drag (Drag & Drop)

  /**
   Begins a long press gesture (drag and drop).
   Sends an immediate mouse down event.
  
   - Parameter completion: Closure to execute for the mouse down action
   */
  func handleLongPressStart(completion: @escaping () -> Void) {
    state = .dragAndDrop
    completion()  // Send mouse down
  }

  /**
   Processes long press drag movement with acceleration.
  
   - Parameters:
     - translation: The movement delta since last update
     - completion: Closure receiving the processed dx and dy movement values
   */
  func handleLongPressDrag(translation: CGSize, completion: @escaping (Int8, Int8) -> Void) {
    guard state == .dragAndDrop else { return }

    // Throttle updates
    if let lastUpdate = lastUpdateTime,
      Date().timeIntervalSince(lastUpdate) < throttleInterval
    {
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

  /**
   Ends a long press gesture and sends mouse up event.
  
   - Parameter completion: Closure to execute for the mouse up action
   */
  func handleLongPressEnd(completion: @escaping () -> Void) {
    completion()  // Send mouse up
    state = .idle
    lastUpdateTime = nil
  }

  // MARK: - Zoom Gestures

  /// Begins a zoom gesture (pinch)
  func handleZoomStart() {
    state = .zooming
  }

  /**
   Processes zoom gesture changes.
  
   - Parameters:
     - scale: The pinch gesture scale value
     - completion: Closure receiving the encoded zoom value (0-255)
   */
  func handleZoomChange(scale: CGFloat, completion: @escaping (UInt8) -> Void) {
    guard state == .zooming else { return }

    let zoomValue = ProtocolEncoder.scaleToUInt8(scale)
    completion(zoomValue)
  }

  /// Ends a zoom gesture and resets state
  func handleZoomEnd() {
    state = .idle
  }
}
