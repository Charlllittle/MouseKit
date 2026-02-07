//
//  SavedDevice.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import Foundation

/// Represents a saved remote desktop device configuration
struct SavedDevice: Codable, Identifiable, Equatable {
  /// Unique identifier for the device
  let id: UUID
  /// User-assigned name for the device
  let name: String
  /// IP address of the device on the local network
  let ipAddress: String

  /**
   Creates a new saved device.
  
   - Parameters:
     - id: Unique identifier (auto-generated if not provided)
     - name: Display name for the device
     - ipAddress: IP address in dotted decimal format
   */
  init(id: UUID = UUID(), name: String, ipAddress: String) {
    self.id = id
    self.name = name
    self.ipAddress = ipAddress
  }
}
