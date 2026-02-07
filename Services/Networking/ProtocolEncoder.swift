//
//  ProtocolEncoder.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import Foundation

/// Encodes input commands and handshake data into binary protocol format
struct ProtocolEncoder {
  /**
   Encodes the handshake message for initial connection.
  
   - Returns: UTF-8 encoded handshake data
   */
  @MainActor
  static func encodeHandshake() -> Data {
    let handshake = DeviceInfo.handshakeString()
    return Data(handshake.utf8)
  }

  /**
   Encodes an input command into binary protocol format.
   Each command consists of a command code followed by command-specific data.
  
   - Parameter command: The input command to encode
   - Returns: Binary data ready to be sent over the network
   */
  static func encode(_ command: InputCommand) -> Data {
    var data = Data()
    data.append(command.commandCode)

    switch command {
    case .leftClick, .rightClick, .mouseDown, .mouseUp:
      // No additional data needed
      break

    case .mouseMove(let dx, let dy):
      data.append(UInt8(bitPattern: clamp(dx)))
      data.append(UInt8(bitPattern: clamp(dy)))

    case .scroll(let delta):
      data.append(UInt8(bitPattern: clamp(delta)))

    case .keyPress(let char):
      data.append(char)

    case .scrollHorizontal(let delta):
      data.append(UInt8(bitPattern: clamp(delta)))

    case .zoom(let scale):
      data.append(scale)

    case .specialKey(let keyCode):
      data.append(keyCode)
    }

    return data
  }

  /**
   Clamps an Int8 value to valid range (-128 to 127).
  
   - Parameter value: The value to clamp
   - Returns: The clamped value
   */
  private static func clamp(_ value: Int8) -> Int8 {
    return max(-128, min(127, value))
  }

  /**
   Converts a CGFloat delta to a clamped Int8 value.
   Used for mouse movement and scroll deltas.
  
   - Parameter value: The floating-point delta value
   - Returns: An Int8 value clamped to -128...127
   */
  static func deltaToInt8(_ value: CGFloat) -> Int8 {
    let clamped = max(-128.0, min(127.0, value))
    return Int8(clamped)
  }

  /**
   Converts a CGFloat scale to UInt8 (0-255).
   Used for zoom/pinch gestures.
  
   - Parameter scale: The scale value (typically 0-2.55)
   - Returns: A UInt8 value from 0 to 255
   */
  static func scaleToUInt8(_ scale: CGFloat) -> UInt8 {
    let normalized = max(0.0, min(255.0, scale * 100.0))
    return UInt8(normalized)
  }
}
