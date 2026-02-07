//
//  InputViewModel.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import Foundation
import SwiftUI

/// View model for the input screen, managing input mode and command sending
@MainActor
class InputViewModel: ObservableObject {
    /// Current input mode (touchpad, keyboard, or numpad)
    @Published var currentMode: InputMode = .touchpad
    /// Connection status indicator
    @Published var isConnected = false

    /// Reference to the shared connection manager
    private let connectionManager = ConnectionManager.shared

    /**
     Sends an input command to the connected remote desktop.

     - Parameter command: The input command to send
     */
    func sendCommand(_ command: InputCommand) {
        Task {
            await connectionManager.sendCommand(command)
        }
    }

    /// Disconnects from the current remote desktop
    func disconnect() {
        Task {
            await connectionManager.disconnect()
        }
    }
}
