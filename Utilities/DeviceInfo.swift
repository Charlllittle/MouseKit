//
//  DeviceInfo.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import UIKit

/// Provides device information for the handshake protocol
enum DeviceInfo {
  /// The device manufacturer (always "Apple" for iOS devices)
  static var manufacturer: String {
    "Apple"
  }

  /// The user-assigned device name (e.g., "Charles's iPhone")
  @MainActor
  static var deviceName: String {
    UIDevice.current.name
  }

  /// The device model (e.g., "iPhone", "iPad")
  @MainActor
  static var model: String {
    UIDevice.current.model
  }

  /// The connection type identifier (1 = WiFi only)
  static var connectionType: Int {
    1  // WiFi only
  }

  /**
   Generates the handshake string sent to the server during connection.
   Format: "manufacturer/deviceName/model/connectionType"
  
   - Returns: A formatted handshake string
   */
  @MainActor
  static func handshakeString() -> String {
    "\(manufacturer)/\(deviceName)/\(model)/\(connectionType)"
  }
}
