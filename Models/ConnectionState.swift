//
//  ConnectionState.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import Foundation

/// Represents the current state of the TCP connection to the remote desktop
enum ConnectionState: Equatable {
    /// No active connection
    case disconnected
    /// Connection attempt in progress
    case connecting
    /// Successfully connected and ready for commands
    case connected
    /// Connection failed with an error
    case failed(Error)

    /**
     Compares two connection states for equality.
     Failed states are considered equal if their error descriptions match.

     - Parameters:
       - lhs: The left-hand side connection state
       - rhs: The right-hand side connection state
     - Returns: True if the states are equal, false otherwise
     */
    static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected),
             (.connecting, .connecting),
             (.connected, .connected):
            return true
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
