//
//  TCPConnection.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import Foundation
import Network

/// Errors that can occur during TCP connection operations
enum TCPConnectionError: Error, LocalizedError {
  /// Connection establishment failed
  case connectionFailed(String)
  /// Data send operation failed
  case sendFailed(String)
  /// Data receive operation failed
  case receiveFailed(String)
  /// Operation attempted when not connected
  case notConnected
  /// Connection is in an invalid state for the requested operation
  case invalidState

  /// Human-readable error description
  var errorDescription: String? {
    switch self {
    case .connectionFailed(let message):
      return "Connection failed: \(message)"
    case .sendFailed(let message):
      return "Send failed: \(message)"
    case .receiveFailed(let message):
      return "Receive failed: \(message)"
    case .notConnected:
      return "Not connected"
    case .invalidState:
      return "Invalid connection state"
    }
  }
}

/// Thread-safe TCP connection wrapper using Network framework
/// Provides async/await interface for network operations
actor TCPConnection {
  /// The underlying network connection
  private var connection: NWConnection?
  /// Handler called when connection state changes
  private var stateUpdateHandler: (@Sendable (NWConnection.State) -> Void)?

  /// Remote host address
  let host: String
  /// Remote port number
  let port: UInt16

  /// Creates a new TCP connection to the specified host and port.
  ///
  /// - Parameters:
  ///   - host: The IP address or hostname
  ///   - port: The port number
  init(host: String, port: UInt16) {
    self.host = host
    self.port = port
  }

  /// Establishes a TCP connection with WiFi-only requirement.
  /// Waits for the connection to be ready before returning.
  ///
  /// - Parameter stateUpdateHandler: Callback for connection state changes
  /// - Throws: TCPConnectionError if connection fails or times out
  func connect(stateUpdateHandler: @escaping @Sendable (NWConnection.State) -> Void) async throws {
    self.stateUpdateHandler = stateUpdateHandler

    let endpoint = NWEndpoint.hostPort(
      host: NWEndpoint.Host(host),
      port: NWEndpoint.Port(rawValue: port)!
    )

    let parameters = NWParameters.tcp
    parameters.prohibitedInterfaceTypes = [.cellular, .loopback]
    parameters.requiredInterfaceType = .wifi

    let newConnection = NWConnection(to: endpoint, using: parameters)
    self.connection = newConnection

    newConnection.stateUpdateHandler = { [weak self] state in
      Task { [weak self] in
        await self?.handleStateUpdate(state)
      }
    }

    newConnection.start(queue: .main)

    // Wait for connection to be ready or fail
    try await waitForConnection()
  }

  /// Waits for the connection to reach ready state or fail.
  /// Polls the connection state with a 5-second timeout.
  ///
  /// - Throws: TCPConnectionError if connection fails or times out
  private func waitForConnection() async throws {
    for _ in 0..<50 {  // 5 seconds timeout (50 * 100ms)
      guard let connection else {
        throw TCPConnectionError.notConnected
      }

      switch connection.state {
      case .ready:
        return
      case .failed(let error):
        throw TCPConnectionError.connectionFailed(error.localizedDescription)
      case .cancelled:
        throw TCPConnectionError.connectionFailed("Connection cancelled")
      default:
        try await Task.sleep(nanoseconds: 100_000_000)  // 100ms
      }
    }

    throw TCPConnectionError.connectionFailed("Connection timeout")
  }

  /// Forwards connection state updates to the registered handler.
  ///
  /// - Parameter state: The new connection state
  private func handleStateUpdate(_ state: NWConnection.State) {
    stateUpdateHandler?(state)
  }

  /// Sends binary data over the TCP connection.
  ///
  /// - Parameter data: The data to send
  /// - Throws: TCPConnectionError if not connected or send fails
  func send(_ data: Data) async throws {
    guard let connection else {
      throw TCPConnectionError.notConnected
    }

    guard connection.state == .ready else {
      throw TCPConnectionError.invalidState
    }

    return try await withCheckedThrowingContinuation { continuation in
      connection.send(
        content: data,
        completion: .contentProcessed { error in
          if let error {
            continuation.resume(throwing: TCPConnectionError.sendFailed(error.localizedDescription))
          } else {
            continuation.resume()
          }
        }
      )
    }
  }

  /// Receives binary data from the TCP connection.
  ///
  /// - Parameters:
  ///   - minimumLength: Minimum number of bytes to receive before returning
  ///   - maximumLength: Maximum number of bytes to receive
  /// - Returns: The received data
  /// - Throws: TCPConnectionError if not connected or receive fails
  func receive(minimumLength: Int = 1, maximumLength: Int = 65536) async throws -> Data {
    guard let connection else {
      throw TCPConnectionError.notConnected
    }

    guard connection.state == .ready else {
      throw TCPConnectionError.invalidState
    }

    return try await withCheckedThrowingContinuation { continuation in
      connection.receive(minimumIncompleteLength: minimumLength, maximumLength: maximumLength) {
        data, _, isComplete, error in
        if let error {
          continuation.resume(
            throwing: TCPConnectionError.receiveFailed(error.localizedDescription))
        } else if let data {
          continuation.resume(returning: data)
        } else if isComplete {
          continuation.resume(throwing: TCPConnectionError.receiveFailed("Connection closed"))
        } else {
          continuation.resume(throwing: TCPConnectionError.receiveFailed("No data received"))
        }
      }
    }
  }

  /// Closes the TCP connection and cleans up resources
  func disconnect() {
    connection?.cancel()
    connection = nil
    stateUpdateHandler = nil
  }

  /// Indicates whether the connection is currently ready for data transfer
  var isConnected: Bool {
    connection?.state == .ready
  }
}
