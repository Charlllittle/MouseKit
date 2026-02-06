import Foundation
import Network

@MainActor
class ConnectionManager: ObservableObject {
    static let shared = ConnectionManager()

    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published private(set) var currentDevice: SavedDevice?

    private var tcpConnection: TCPConnection?
    private var commandQueue: [InputCommand] = []
    private var isProcessingQueue = false

    private init() {}

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

    func disconnect() async {
        await tcpConnection?.disconnect()
        tcpConnection = nil
        connectionState = .disconnected
        currentDevice = nil
        commandQueue.removeAll()
        isProcessingQueue = false
    }

    func sendCommand(_ command: InputCommand) async {
        guard connectionState == .connected else {
            return
        }

        commandQueue.append(command)

        if !isProcessingQueue {
            await processCommandQueue()
        }
    }

    private func processCommandQueue() async {
        guard !isProcessingQueue else { return }
        isProcessingQueue = true

        while !commandQueue.isEmpty {
            let command = commandQueue.removeFirst()
            let data = ProtocolEncoder.encode(command)

            // Debug logging
            print("DEBUG ConnectionManager: Sending command - bytes: \(data.map { String(format: "%02X", $0) }.joined(separator: " "))")

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
