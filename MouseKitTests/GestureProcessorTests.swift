//
//  GestureProcessorTests.swift
//  MouseKitTests
//
//  Created by Charles Little on 06/02/2026.
//

import Foundation
import Testing

@testable import MouseKit

@MainActor
struct GestureProcessorTests {

  // MARK: - State Management Tests

  @Test func testInitialState() {
    let processor = GestureProcessor()
    #expect(processor.state == .idle)
  }

  @Test func testDragStartChangesState() {
    let processor = GestureProcessor()
    processor.handleDragStart()
    #expect(processor.state == .dragging)
  }

  @Test func testDragEndResetsState() {
    let processor = GestureProcessor()
    processor.handleDragStart()
    processor.handleDragEnd()
    #expect(processor.state == .idle)
  }

  @Test func testScrollStartChangesState() {
    let processor = GestureProcessor()
    processor.handleScrollStart()
    #expect(processor.state == .scrolling)
  }

  @Test func testScrollEndResetsState() {
    let processor = GestureProcessor()
    processor.handleScrollStart()
    processor.handleScrollEnd()
    #expect(processor.state == .idle)
  }

  @Test func testZoomStartChangesState() {
    let processor = GestureProcessor()
    processor.handleZoomStart()
    #expect(processor.state == .zooming)
  }

  @Test func testZoomEndResetsState() {
    let processor = GestureProcessor()
    processor.handleZoomStart()
    processor.handleZoomEnd()
    #expect(processor.state == .idle)
  }

  @Test func testLongPressStartChangesState() async {
    let processor = GestureProcessor()
    processor.handleLongPressStart {}
    #expect(processor.state == .dragAndDrop)
  }

  @Test func testLongPressEndResetsState() async {
    let processor = GestureProcessor()
    processor.handleLongPressStart {}
    processor.handleLongPressEnd {}
    #expect(processor.state == .idle)
  }

  // MARK: - Tap Gesture Tests

  @Test func testSingleTapCallsCompletion() async throws {
    let processor = GestureProcessor()
    var tapCount = 0

    processor.handleSingleTap {
      tapCount += 1
    }

    // Wait for double-tap delay to pass
    try await Task.sleep(for: .milliseconds(200))

    #expect(tapCount == 1)
  }

  @Test func testDoubleTapCallsCompletionTwice() async throws {
    let processor = GestureProcessor()
    var tapCount = 0

    // First tap
    processor.handleSingleTap {
      tapCount += 1
    }

    // Second tap within double-tap window
    try await Task.sleep(for: .milliseconds(50))
    processor.handleSingleTap {
      tapCount += 1
    }

    // Give it time to execute
    try await Task.sleep(for: .milliseconds(100))

    #expect(tapCount == 2)
  }

  @Test func testTwoFingerTapImmediatelyCallsCompletion() {
    let processor = GestureProcessor()
    var tapCount = 0

    processor.handleTwoFingerTap {
      tapCount += 1
    }

    #expect(tapCount == 1)
  }

  // MARK: - Drag Gesture Tests

  @Test func testDragChangeOnlyWorksInDraggingState() {
    let processor = GestureProcessor()
    var callCount = 0

    // Try to change drag without starting drag
    processor.handleDragChange(translation: CGSize(width: 10, height: 10)) { _, _ in
      callCount += 1
    }

    #expect(callCount == 0)
  }

  @Test func testDragChangeWorksAfterDragStart() async throws {
    let processor = GestureProcessor()
    var callCount = 0

    processor.handleDragStart()

    // Wait for throttle interval to pass
    try await Task.sleep(for: .milliseconds(20))

    processor.handleDragChange(translation: CGSize(width: 10, height: 10)) { _, _ in
      callCount += 1
    }

    #expect(callCount == 1)
  }

  @Test func testDragChangeInvertsAxes() async throws {
    let processor = GestureProcessor()
    var receivedDx: Int8?
    var receivedDy: Int8?

    processor.handleDragStart()

    // Wait for throttle interval to pass
    try await Task.sleep(for: .milliseconds(20))

    processor.handleDragChange(translation: CGSize(width: 10, height: 5)) { dx, dy in
      receivedDx = dx
      receivedDy = dy
    }

    // Values should be inverted and accelerated
    #expect(receivedDx != nil)
    #expect(receivedDy != nil)
    // After acceleration and inversion, signs should be negative
    #expect(receivedDx! < 0)
    #expect(receivedDy! < 0)
  }

  // MARK: - Scroll Gesture Tests

  @Test func testScrollChangeOnlyWorksInScrollingState() {
    let processor = GestureProcessor()
    var callCount = 0

    processor.handleScrollChange(translation: CGSize(width: 0, height: 10)) { _, _ in
      callCount += 1
    }

    #expect(callCount == 0)
  }

  @Test func testScrollChangeVerticalDominance() async throws {
    let processor = GestureProcessor()
    var verticalDelta: Int8?
    var horizontalDelta: Int8?

    processor.handleScrollStart()

    // Wait for throttle interval to pass
    try await Task.sleep(for: .milliseconds(20))

    processor.handleScrollChange(translation: CGSize(width: 5, height: 20)) { vDelta, hDelta in
      verticalDelta = vDelta
      horizontalDelta = hDelta
    }

    #expect(verticalDelta != nil)
    #expect(horizontalDelta == nil)
  }

  @Test func testScrollChangeHorizontalDominance() async throws {
    let processor = GestureProcessor()
    var verticalDelta: Int8?
    var horizontalDelta: Int8?

    processor.handleScrollStart()

    // Wait for throttle interval to pass
    try await Task.sleep(for: .milliseconds(20))

    processor.handleScrollChange(translation: CGSize(width: 20, height: 5)) { vDelta, hDelta in
      verticalDelta = vDelta
      horizontalDelta = hDelta
    }

    #expect(verticalDelta == nil)
    #expect(horizontalDelta != nil)
  }

  // MARK: - Long Press + Drag Tests

  @Test func testLongPressDragOnlyWorksInDragAndDropState() {
    let processor = GestureProcessor()
    var callCount = 0

    processor.handleLongPressDrag(translation: CGSize(width: 10, height: 10)) { _, _ in
      callCount += 1
    }

    #expect(callCount == 0)
  }

  @Test func testLongPressDragWorksAfterLongPressStart() async throws {
    let processor = GestureProcessor()
    var startCallCount = 0
    var dragCallCount = 0

    processor.handleLongPressStart {
      startCallCount += 1
    }

    // Wait briefly to ensure state is set
    try await Task.sleep(for: .milliseconds(20))

    processor.handleLongPressDrag(translation: CGSize(width: 10, height: 10)) { _, _ in
      dragCallCount += 1
    }

    #expect(startCallCount == 1)
    #expect(dragCallCount == 1)
  }

  @Test func testLongPressEndCallsCompletion() {
    let processor = GestureProcessor()
    var endCallCount = 0

    processor.handleLongPressStart {}
    processor.handleLongPressEnd {
      endCallCount += 1
    }

    #expect(endCallCount == 1)
  }

  // MARK: - Zoom Gesture Tests

  @Test func testZoomChangeOnlyWorksInZoomingState() {
    let processor = GestureProcessor()
    var callCount = 0

    processor.handleZoomChange(scale: 1.5) { _ in
      callCount += 1
    }

    #expect(callCount == 0)
  }

  @Test func testZoomChangeWorksAfterZoomStart() {
    let processor = GestureProcessor()
    var callCount = 0

    processor.handleZoomStart()
    processor.handleZoomChange(scale: 1.5) { _ in
      callCount += 1
    }

    #expect(callCount == 1)
  }

  @Test func testZoomChangeConvertsScaleCorrectly() {
    let processor = GestureProcessor()
    var receivedScale: UInt8?

    processor.handleZoomStart()
    processor.handleZoomChange(scale: 1.5) { scale in
      receivedScale = scale
    }

    #expect(receivedScale == 150)
  }
}
