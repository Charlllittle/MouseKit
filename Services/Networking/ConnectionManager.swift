//
//  ConnectionManager.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import Foundation
import Network

/// Manages TCP connections to remote desktop servers
/// Handles connection lifecycle, handshake protocol, and command queuing
@MainActor
class ConnectionManager: ObservableObject {
  /// Shared singleton instance
  static let shared = ConnectionManager()

  /// Current connection state
  @Published private(set) var connectionState: ConnectionState = .disconnected
  /// Currently connected device, if any
  @Published private(set) var currentDevice: SavedDevice?

  /// Active TCP connection
  private var tcpConnection: TCPConnection?
  /// Queue of pending input commands
  private var commandQueue: [InputCommand] = []
  /// Flag indicating if the command queue is being processed
  private var isProcessingQueue = false

  private init() {}

  /**
   Establishes a connection to a remote device.
   Performs the handshake protocol after connection is established.
  
   - Parameter device: The device to connect to
   */
  func connect(to device: SavedDevice) async {
    guard connectionState == .disconnected else {
      return
    }

    connectionState = .connecting
    currentDevice = device

    let connection = TCPConnection(host: device.ipAddress, port: Constants.serverPort)
    self.tcpConnection = connection

    do {
      try await connection.connect { [weak self] state in
        Task { @MainActor [weak self] in
          self?.handleConnectionStateChange(state)
        }
      }

      // Send handshake
      let handshakeData = ProtocolEncoder.encodeHandshake()
      try await connection.send(handshakeData)

      connectionState = .connected

    } catch {
      connectionState = .failed(error)
      await disconnect()
    }
  }

  /// Disconnects from the current device and cleans up resources
  func disconnect() async {
    await tcpConnection?.disconnect()
    tcpConnection = nil
    connectionState = .disconnected
    currentDevice = nil
    commandQueue.removeAll()
    isProcessingQueue = false
  }

  /**
   Queues an input command to be sent to the connected device.
   Commands are processed sequentially to maintain order.
  
   - Parameter command: The input command to send
   */
  func sendCommand(_ command: InputCommand) async {
    guard connectionState == .connected else {
      return
    }

    commandQueue.append(command)

    if !isProcessingQueue {
      await processCommandQueue()
    }
  }

  /**
   Processes the command queue, sending commands one at a time.
   Automatically stops processing if a send error occurs.
   */
  private func processCommandQueue() async {
    guard !isProcessingQueue else { return }
    isProcessingQueue = true

    while !commandQueue.isEmpty {
      let command = commandQueue.removeFirst()
      let data = ProtocolEncoder.encode(command)

      // Debug logging
      print(
        "DEBUG ConnectionManager: Sending command - bytes: \(data.map { String(format: "%02X", $0) }.joined(separator: " "))"
      )

      do {
        try await tcpConnection?.send(data)
      } catch {
        print("Failed to send command: \(error)")
        connectionState = .failed(error)
        await disconnect()
        break
      }
    }

    isProcessingQueue = false
  }

  /**
   Handles changes in the underlying TCP connection state.
  
   - Parameter state: The new connection state
   */
  private func handleConnectionStateChange(_ state: NWConnection.State) {
    switch state {
    case .ready:
      if connectionState == .connecting {
        // Connection ready, handshake will be sent
      }
    case .failed(let error):
      connectionState = .failed(error)
      Task {
        await disconnect()
      }
    case .cancelled:
      if connectionState != .disconnected {
        connectionState = .disconnected
      }
    default:
      break
    }
  }
}
