//
//  TouchpadView.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import SwiftUI
import UIKit

struct TouchpadView: View {
    @ObservedObject var viewModel: InputViewModel
    @StateObject private var gestureProcessor = GestureProcessor()

    var body: some View {
        GeometryReader { geometry in
            AllGesturesView(
                onSingleTap: handleSingleTap,
                onTwoFingerTap: handleTwoFingerTap,
                onDragStart: {
                    gestureProcessor.handleDragStart()
                    print("DEBUG: Drag started")
                },
                onDragChange: { translation in
                    // Translation is already the delta (reset after each update)
                    gestureProcessor.handleDragChange(translation: translation) { dx, dy in
                        viewModel.sendCommand(.mouseMove(dx: dx, dy: dy))
                        print("DEBUG: Mouse move - dx: \(dx), dy: \(dy)")
                    }
                },
                onDragEnd: {
                    gestureProcessor.handleDragEnd()
                    print("DEBUG: Drag ended")
                },
                onTwoFingerPanStart: handleTwoFingerPanStart,
                onTwoFingerPanChange: handleTwoFingerPanChange,
                onTwoFingerPanEnd: handleTwoFingerPanEnd,
                onLongPressStart: {
                    gestureProcessor.handleLongPressStart {
                        viewModel.sendCommand(.mouseDown)
                    }
                },
                onLongPressDrag: { delta in
                    // Delta is the change since last update
                    gestureProcessor.handleLongPressDrag(translation: delta) { dx, dy in
                        viewModel.sendCommand(.mouseMove(dx: dx, dy: dy))
                    }
                },
                onLongPressEnd: {
                    gestureProcessor.handleLongPressEnd {
                        viewModel.sendCommand(.mouseUp)
                    }
                },
                onDoubleTapAndHoldStart: {
                    gestureProcessor.handleDoubleTapAndHoldStart {
                        viewModel.sendCommand(.mouseDown)
                    }
                },
                onDoubleTapAndHoldDrag: { delta in
                    gestureProcessor.handleDoubleTapAndHoldDrag(translation: delta) { dx, dy in
                        viewModel.sendCommand(.mouseMove(dx: dx, dy: dy))
                    }
                },
                onDoubleTapAndHoldEnd: {
                    gestureProcessor.handleDoubleTapAndHoldEnd {
                        viewModel.sendCommand(.mouseUp)
                    }
                },
                onPinchStart: handlePinchStart,
                onPinchChange: handlePinchChange,
                onPinchEnd: handlePinchEnd
            )
        }
        .background(Color(uiColor: .systemBackground))
    }

    // MARK: - Single Tap

    private func handleSingleTap() {
        gestureProcessor.handleSingleTap {
            viewModel.sendCommand(.leftClick)
        }
    }

    // MARK: - Two-Finger Tap

    private func handleTwoFingerTap() {
        gestureProcessor.handleTwoFingerTap {
            viewModel.sendCommand(.rightClick)
        }
    }


    // MARK: - Two-Finger Pan (Scroll)

    private func handleTwoFingerPanStart() {
        gestureProcessor.handleScrollStart()
    }

    private func handleTwoFingerPanChange(_ translation: CGSize) {
        // Translation is already the delta (reset after each update)
        gestureProcessor.handleScrollChange(translation: translation) { verticalDelta, horizontalDelta in
            if let vDelta = verticalDelta {
                viewModel.sendCommand(.scroll(delta: vDelta))
            }
            if let hDelta = horizontalDelta {
                viewModel.sendCommand(.scrollHorizontal(delta: hDelta))
            }
        }
    }

    private func handleTwoFingerPanEnd() {
        gestureProcessor.handleScrollEnd()
    }


    // MARK: - Pinch (Zoom)

    private func handlePinchStart() {
        gestureProcessor.handleZoomStart()
    }

    private func handlePinchChange(_ scale: CGFloat) {
        gestureProcessor.handleZoomChange(scale: scale) { zoomValue in
            viewModel.sendCommand(.zoom(scale: zoomValue))
        }
    }

    private func handlePinchEnd() {
        gestureProcessor.handleZoomEnd()
    }
}

// MARK: - All Gestures UIViewRepresentable

struct AllGesturesView: UIViewRepresentable {
    var onSingleTap: () -> Void
    var onTwoFingerTap: () -> Void
    var onDragStart: () -> Void
    var onDragChange: (CGSize) -> Void
    var onDragEnd: () -> Void
    var onTwoFingerPanStart: () -> Void
    var onTwoFingerPanChange: (CGSize) -> Void
    var onTwoFingerPanEnd: () -> Void
    var onLongPressStart: () -> Void
    var onLongPressDrag: (CGSize) -> Void
    var onLongPressEnd: () -> Void
    var onDoubleTapAndHoldStart: () -> Void
    var onDoubleTapAndHoldDrag: (CGSize) -> Void
    var onDoubleTapAndHoldEnd: () -> Void
    var onPinchStart: () -> Void
    var onPinchChange: (CGFloat) -> Void
    var onPinchEnd: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground

        // Single tap
        let singleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSingleTap))
        singleTap.numberOfTouchesRequired = 1
        singleTap.numberOfTapsRequired = 1
        singleTap.delegate = context.coordinator
        singleTap.cancelsTouchesInView = false
        singleTap.delaysTouchesBegan = false
        singleTap.delaysTouchesEnded = false
        view.addGestureRecognizer(singleTap)

        // Double tap (for double tap and hold)
        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap))
        doubleTap.numberOfTouchesRequired = 1
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = context.coordinator
        view.addGestureRecognizer(doubleTap)

        // Two-finger tap
        let twoFingerTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTwoFingerTap))
        twoFingerTap.numberOfTouchesRequired = 2
        view.addGestureRecognizer(twoFingerTap)

        // Single-finger pan (for mouse movement)
        let singlePan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSinglePan))
        singlePan.minimumNumberOfTouches = 1
        singlePan.maximumNumberOfTouches = 1
        singlePan.delegate = context.coordinator
        singlePan.delaysTouchesBegan = false
        singlePan.delaysTouchesEnded = false
        singlePan.cancelsTouchesInView = true
        view.addGestureRecognizer(singlePan)

        // Two-finger pan (for scrolling)
        let twoFingerPan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTwoFingerPan))
        twoFingerPan.minimumNumberOfTouches = 2
        twoFingerPan.maximumNumberOfTouches = 2
        view.addGestureRecognizer(twoFingerPan)

        // Long press (for drag & drop)
        let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress))
        longPress.minimumPressDuration = 0.5
        longPress.delegate = context.coordinator
        view.addGestureRecognizer(longPress)

        // Pinch (for zoom)
        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch))
        view.addGestureRecognizer(pinch)

        // Configure gesture relationships
        singleTap.require(toFail: twoFingerTap)
        singleTap.require(toFail: doubleTap)
        // REMOVED: singlePan.require(toFail: twoFingerPan) - This was causing the delay!
        // We'll check touch count in the gesture handler instead

        // Store gesture references in coordinator for potential cancellation
        context.coordinator.singlePan = singlePan
        context.coordinator.longPress = longPress
        context.coordinator.singleTap = singleTap
        context.coordinator.doubleTap = doubleTap
        context.coordinator.twoFingerPan = twoFingerPan

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onSingleTap: onSingleTap,
            onTwoFingerTap: onTwoFingerTap,
            onDragStart: onDragStart,
            onDragChange: onDragChange,
            onDragEnd: onDragEnd,
            onTwoFingerPanStart: onTwoFingerPanStart,
            onTwoFingerPanChange: onTwoFingerPanChange,
            onTwoFingerPanEnd: onTwoFingerPanEnd,
            onLongPressStart: onLongPressStart,
            onLongPressDrag: onLongPressDrag,
            onLongPressEnd: onLongPressEnd,
            onDoubleTapAndHoldStart: onDoubleTapAndHoldStart,
            onDoubleTapAndHoldDrag: onDoubleTapAndHoldDrag,
            onDoubleTapAndHoldEnd: onDoubleTapAndHoldEnd,
            onPinchStart: onPinchStart,
            onPinchChange: onPinchChange,
            onPinchEnd: onPinchEnd
        )
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onSingleTap: () -> Void
        var onTwoFingerTap: () -> Void
        var onDragStart: () -> Void
        var onDragChange: (CGSize) -> Void
        var onDragEnd: () -> Void
        var onTwoFingerPanStart: () -> Void
        var onTwoFingerPanChange: (CGSize) -> Void
        var onTwoFingerPanEnd: () -> Void
        var onLongPressStart: () -> Void
        var onLongPressDrag: (CGSize) -> Void
        var onLongPressEnd: () -> Void
        var onDoubleTapAndHoldStart: () -> Void
        var onDoubleTapAndHoldDrag: (CGSize) -> Void
        var onDoubleTapAndHoldEnd: () -> Void
        var onPinchStart: () -> Void
        var onPinchChange: (CGFloat) -> Void
        var onPinchEnd: () -> Void

        var isLongPressing = false
        var isPanning = false
        var isDoubleTapAndHold = false
        var doubleTapTimer: Timer?
        var longPressStartLocation: CGPoint = .zero
        var longPressLastLocation: CGPoint = .zero
        var doubleTapStartLocation: CGPoint = .zero
        var doubleTapLastLocation: CGPoint = .zero

        // Store gesture references
        weak var singlePan: UIPanGestureRecognizer?
        weak var longPress: UILongPressGestureRecognizer?
        weak var singleTap: UITapGestureRecognizer?
        weak var doubleTap: UITapGestureRecognizer?
        weak var twoFingerPan: UIPanGestureRecognizer?

        init(
            onSingleTap: @escaping () -> Void,
            onTwoFingerTap: @escaping () -> Void,
            onDragStart: @escaping () -> Void,
            onDragChange: @escaping (CGSize) -> Void,
            onDragEnd: @escaping () -> Void,
            onTwoFingerPanStart: @escaping () -> Void,
            onTwoFingerPanChange: @escaping (CGSize) -> Void,
            onTwoFingerPanEnd: @escaping () -> Void,
            onLongPressStart: @escaping () -> Void,
            onLongPressDrag: @escaping (CGSize) -> Void,
            onLongPressEnd: @escaping () -> Void,
            onDoubleTapAndHoldStart: @escaping () -> Void,
            onDoubleTapAndHoldDrag: @escaping (CGSize) -> Void,
            onDoubleTapAndHoldEnd: @escaping () -> Void,
            onPinchStart: @escaping () -> Void,
            onPinchChange: @escaping (CGFloat) -> Void,
            onPinchEnd: @escaping () -> Void
        ) {
            self.onSingleTap = onSingleTap
            self.onTwoFingerTap = onTwoFingerTap
            self.onDragStart = onDragStart
            self.onDragChange = onDragChange
            self.onDragEnd = onDragEnd
            self.onTwoFingerPanStart = onTwoFingerPanStart
            self.onTwoFingerPanChange = onTwoFingerPanChange
            self.onTwoFingerPanEnd = onTwoFingerPanEnd
            self.onLongPressStart = onLongPressStart
            self.onLongPressDrag = onLongPressDrag
            self.onLongPressEnd = onLongPressEnd
            self.onDoubleTapAndHoldStart = onDoubleTapAndHoldStart
            self.onDoubleTapAndHoldDrag = onDoubleTapAndHoldDrag
            self.onDoubleTapAndHoldEnd = onDoubleTapAndHoldEnd
            self.onPinchStart = onPinchStart
            self.onPinchChange = onPinchChange
            self.onPinchEnd = onPinchEnd
        }

        @objc func handleSingleTap(_ gesture: UITapGestureRecognizer) {
            if gesture.state == .ended {
                onSingleTap()
            }
        }

        @objc func handleTwoFingerTap(_ gesture: UITapGestureRecognizer) {
            if gesture.state == .ended {
                onTwoFingerTap()
            }
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            if gesture.state == .ended {
                // Start double tap and hold - wait for finger to move
                isDoubleTapAndHold = true
                doubleTapStartLocation = gesture.location(in: gesture.view)
                doubleTapLastLocation = doubleTapStartLocation

                // Cancel the timer if it fires without movement
                doubleTapTimer?.invalidate()
                doubleTapTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { [weak self] _ in
                    // If no pan has started after double tap, treat it as two separate clicks
                    if self?.isDoubleTapAndHold == true {
                        self?.isDoubleTapAndHold = false
                        // Execute two clicks
                        self?.onSingleTap()
                        self?.onSingleTap()
                    }
                }
            }
        }

        @objc func handleSinglePan(_ gesture: UIPanGestureRecognizer) {
            // Check number of touches - if 2, ignore (let two-finger pan handle it)
            let touchCount = gesture.numberOfTouches
            print("DEBUG handleSinglePan: state: \(gesture.state.rawValue), touches: \(touchCount)")

            if touchCount >= 2 {
                print("DEBUG handleSinglePan: Ignoring - 2+ touches detected")
                return
            }

            // Don't handle pan if we're in a long press
            if isLongPressing {
                print("DEBUG handleSinglePan: Ignoring - long press active")
                return
            }

            // Handle double tap and hold
            if isDoubleTapAndHold {
                switch gesture.state {
                case .began, .changed:
                    if gesture.state == .began {
                        doubleTapTimer?.invalidate()
                        onDoubleTapAndHoldStart()
                    }
                    let currentLocation = gesture.location(in: gesture.view)
                    let delta = CGSize(
                        width: currentLocation.x - doubleTapLastLocation.x,
                        height: currentLocation.y - doubleTapLastLocation.y
                    )
                    onDoubleTapAndHoldDrag(delta)
                    doubleTapLastLocation = currentLocation

                case .ended, .cancelled:
                    isDoubleTapAndHold = false
                    onDoubleTapAndHoldEnd()

                default:
                    break
                }
                return
            }

            switch gesture.state {
            case .began:
                isPanning = true
                // Cancel the tap gesture since we're panning
                singleTap?.isEnabled = false
                singleTap?.isEnabled = true
                onDragStart()
                print("DEBUG handleSinglePan: BEGAN - touches: \(touchCount)")

            case .changed:
                let translation = gesture.translation(in: gesture.view)
                print("DEBUG handleSinglePan: CHANGED - translation: \(translation), touches: \(touchCount)")
                onDragChange(CGSize(width: translation.x, height: translation.y))
                // Reset translation so next update gives us the delta
                gesture.setTranslation(.zero, in: gesture.view)

            case .ended, .cancelled:
                isPanning = false
                onDragEnd()
                print("DEBUG handleSinglePan: ENDED/CANCELLED - state: \(gesture.state.rawValue), touches: \(touchCount)")

            case .failed:
                isPanning = false
                print("DEBUG handleSinglePan: FAILED - touches: \(touchCount)")

            default:
                print("DEBUG handleSinglePan: state: \(gesture.state.rawValue), touches: \(touchCount)")
                break
            }
        }

        @objc func handleTwoFingerPan(_ gesture: UIPanGestureRecognizer) {
            switch gesture.state {
            case .began:
                onTwoFingerPanStart()

            case .changed:
                let translation = gesture.translation(in: gesture.view)
                onTwoFingerPanChange(CGSize(width: translation.x, height: translation.y))
                // Reset translation so next update gives us the delta
                gesture.setTranslation(.zero, in: gesture.view)

            case .ended, .cancelled:
                onTwoFingerPanEnd()

            default:
                break
            }
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            switch gesture.state {
            case .began:
                // Cancel the pan gesture if it started
                if isPanning {
                    singlePan?.isEnabled = false
                    singlePan?.isEnabled = true
                    isPanning = false
                }

                isLongPressing = true
                longPressStartLocation = gesture.location(in: gesture.view)
                longPressLastLocation = longPressStartLocation
                onLongPressStart()

            case .changed:
                let currentLocation = gesture.location(in: gesture.view)
                // Calculate delta from last update, not from start
                let delta = CGSize(
                    width: currentLocation.x - longPressLastLocation.x,
                    height: currentLocation.y - longPressLastLocation.y
                )
                onLongPressDrag(delta)
                longPressLastLocation = currentLocation

            case .ended, .cancelled:
                isLongPressing = false
                onLongPressEnd()

            default:
                break
            }
        }

        // MARK: - UIGestureRecognizerDelegate

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // Allow pan and long press to start simultaneously, we'll handle the conflict in code
            if (gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer is UILongPressGestureRecognizer) ||
               (gestureRecognizer is UILongPressGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer) {
                return true
            }

            // Allow tap and pan to run simultaneously - we'll cancel tap in pan's began handler
            if (gestureRecognizer is UITapGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer) ||
               (gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer is UITapGestureRecognizer) {
                return true
            }

            return false
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBegin gesture: UIGestureRecognizer) -> Bool {
            print("DEBUG shouldBegin: \(type(of: gestureRecognizer)) - returning true")
            return true
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            switch gesture.state {
            case .began:
                onPinchStart()

            case .changed:
                onPinchChange(gesture.scale)

            case .ended, .cancelled:
                onPinchEnd()

            default:
                break
            }
        }
    }
}
