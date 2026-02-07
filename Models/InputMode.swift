//
//  InputMode.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import Foundation

/// Available input modes for interacting with the remote desktop
enum InputMode: String, CaseIterable {
  /// Touch-based mouse control with gestures
  case touchpad = "Touchpad"
  /// Full QWERTY keyboard input
  case keyboard = "Keyboard"
  /// Numeric keypad for number entry
  case numpad = "Numpad"
}
