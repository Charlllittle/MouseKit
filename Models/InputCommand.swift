//
//  InputCommand.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import Foundation

/// Represents input commands that can be sent to the remote desktop
enum InputCommand {
    /// Single left mouse button click
    case leftClick
    /// Single right mouse button click
    case rightClick
    /// Mouse button down (for drag operations)
    case mouseDown
    /// Mouse button up (for drag operations)
    case mouseUp
    /// Move mouse cursor by relative delta
    case mouseMove(dx: Int8, dy: Int8)
    /// Vertical scroll wheel movement
    case scroll(delta: Int8)
    /// Character key press (ASCII)
    case keyPress(char: UInt8)
    /// Horizontal scroll wheel movement
    case scrollHorizontal(delta: Int8)
    /// Zoom/pinch gesture
    case zoom(scale: UInt8)
    /// Special key press (virtual key codes for arrow keys, function keys, etc.)
    case specialKey(keyCode: UInt8)

    /// The binary command code sent in the protocol
    var commandCode: UInt8 {
        switch self {
        case .leftClick:
            return 0x01
        case .rightClick:
            return 0x02
        case .mouseDown:
            return 0x03
        case .mouseUp:
            return 0x04
        case .mouseMove:
            return 0x05
        case .scroll:
            return 0x06
        case .keyPress:
            return 0x07
        case .scrollHorizontal:
            return 0x08
        case .zoom:
            return 0x09
        case .specialKey:
            return 0x0A  // New command code
        }
    }
}
