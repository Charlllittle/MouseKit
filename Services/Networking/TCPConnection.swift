//
//  TCPConnection.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import Foundation
import Network

enum TCPConnectionError: Error, LocalizedError {
    case connectionFailed(String)
    case sendFailed(String)
    case receiveFailed(String)
    case notConnected
    case invalidState

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

actor TCPConnection {
    private var connection: NWConnection?
    private var stateUpdateHandler: ((NWConnection.State) -> Void)?

    let host: String
    let port: UInt16

    init(host: String, port: UInt16) {
        self.host = host
        self.port = port
    }

    func connect(stateUpdateHandler: @escaping (NWConnection.State) -> Void) async throws {
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

    private func waitForConnection() async throws {
        for _ in 0..<50 { // 5 seconds timeout (50 * 100ms)
            guard let connection = connection else {
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
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            }
        }

        throw TCPConnectionError.connectionFailed("Connection timeout")
    }

    private func handleStateUpdate(_ state: NWConnection.State) {
        stateUpdateHandler?(state)
    }

    func send(_ data: Data) async throws {
        guard let connection = connection else {
            throw TCPConnectionError.notConnected
        }

        guard connection.state == .ready else {
            throw TCPConnectionError.invalidState
        }

        return try await withCheckedThrowingContinuation { continuation in
            connection.send(
                content: data,
                completion: .contentProcessed { error in
                    if let error = error {
                        continuation.resume(throwing: TCPConnectionError.sendFailed(error.localizedDescription))
                    } else {
                        continuation.resume()
                    }
                }
            )
        }
    }

    func receive(minimumLength: Int = 1, maximumLength: Int = 65536) async throws -> Data {
        guard let connection = connection else {
            throw TCPConnectionError.notConnected
        }

        guard connection.state == .ready else {
            throw TCPConnectionError.invalidState
        }

        return try await withCheckedThrowingContinuation { continuation in
            connection.receive(minimumIncompleteLength: minimumLength, maximumLength: maximumLength) { data, _, isComplete, error in
                if let error = error {
                    continuation.resume(throwing: TCPConnectionError.receiveFailed(error.localizedDescription))
                } else if let data = data {
                    continuation.resume(returning: data)
                } else if isComplete {
                    continuation.resume(throwing: TCPConnectionError.receiveFailed("Connection closed"))
                } else {
                    continuation.resume(throwing: TCPConnectionError.receiveFailed("No data received"))
                }
            }
        }
    }

    func disconnect() {
        connection?.cancel()
        connection = nil
        stateUpdateHandler = nil
    }

    var isConnected: Bool {
        connection?.state == .ready
    }
}
