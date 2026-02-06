//
//  InputContainerView.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import SwiftUI

struct InputContainerView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = InputViewModel()
    @StateObject private var connectionManager = ConnectionManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Connection status bar
            HStack {
                Circle()
                    .fill(connectionStatusColor)
                    .frame(width: 8, height: 8)

                Text(connectionStatusText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Button("Disconnect") {
                    viewModel.disconnect()
                    isPresented = false
                }
                .font(.subheadline)
            }
            .padding()
            .background(Color(uiColor: .secondarySystemBackground))

            // Mode picker
            Picker("Input Mode", selection: $viewModel.currentMode) {
                ForEach(InputMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // Active input view
            switch viewModel.currentMode {
            case .touchpad:
                TouchpadView(viewModel: viewModel)
            case .keyboard:
                KeyboardView(viewModel: viewModel)
            case .numpad:
                NumpadView(viewModel: viewModel)
            }
        }
        .onChange(of: connectionManager.connectionState) { _, newState in
            if case .disconnected = newState {
                isPresented = false
            } else if case .failed = newState {
                isPresented = false
            }
        }
    }

    private var connectionStatusColor: Color {
        switch connectionManager.connectionState {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .disconnected, .failed:
            return .red
        }
    }

    private var connectionStatusText: String {
        switch connectionManager.connectionState {
        case .connected:
            if let device = connectionManager.currentDevice {
                return "Connected to \(device.name)"
            }
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Disconnected"
        case .failed(let error):
            return "Failed: \(error.localizedDescription)"
        }
    }
}
