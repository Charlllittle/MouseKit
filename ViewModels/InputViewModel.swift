//
//  InputViewModel.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import Foundation
import SwiftUI

@MainActor
class InputViewModel: ObservableObject {
  @Published var currentMode: InputMode = .touchpad
  @Published var isConnected = false

  private let connectionManager = ConnectionManager.shared

  func sendCommand(_ command: InputCommand) {
    Task {
      await connectionManager.sendCommand(command)
    }
  }

  func disconnect() {
    Task {
      await connectionManager.disconnect()
    }
  }
}
