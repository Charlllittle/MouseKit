//
//  Constants.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import Foundation

enum Constants {
  static let serverPort: UInt16 = 6969
  static let connectionTimeout: TimeInterval = 10.0
  static let reconnectDelay: TimeInterval = 2.0
  static let maxReconnectAttempts = 3
  static let gestureThrottleInterval: TimeInterval = 1.0 / 60.0  // 60 FPS
  static let doubleTapDelay: TimeInterval = 0.15  // 150ms

  enum UserDefaultsKeys {
    static let savedDevices = "savedDevices"
  }
}
