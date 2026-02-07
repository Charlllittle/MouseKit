//
//  Constants.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import Foundation

/// Application-wide constants and configuration values
enum Constants {
  /// TCP port number for the remote desktop server
  static let serverPort: UInt16 = 6969
  /// Maximum time to wait for connection establishment
  static let connectionTimeout: TimeInterval = 10.0
  /// Delay before attempting to reconnect after failure
  static let reconnectDelay: TimeInterval = 2.0
  /// Maximum number of automatic reconnection attempts
  static let maxReconnectAttempts = 3
  /// Minimum time between gesture updates (60 FPS target)
  static let gestureThrottleInterval: TimeInterval = 1.0 / 60.0
  /// Time window for detecting double-tap gestures (150ms)
  static let doubleTapDelay: TimeInterval = 0.15

  /// Keys used for UserDefaults storage
  enum UserDefaultsKeys {
    /// Key for storing saved device list
    static let savedDevices = "savedDevices"
  }
}
