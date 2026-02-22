//
//  MainView.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = DeviceListViewModel()
    @StateObject private var connectionManager = ConnectionManager.shared
    @State private var showingInputView = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.devices.isEmpty {
                    ContentUnavailableView(
                        "No Devices",
                        systemImage: "laptopcomputer.and.iphone",
                        description: Text("Add a device to get started")
                    )
                } else {
                    DeviceListView(
                        viewModel: viewModel,
                        showingInputView: $showingInputView
                    )
                }
            }
            .navigationTitle("MouseKit")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingAddDevice = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddDevice) {
                AddDeviceView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel)
            }
            .onAppear {
                guard viewModel.autoConnectEnabled,
                    let device = viewModel.defaultDevice
                else { return }
                Task { await viewModel.connectToDevice(device) }
            }
            .fullScreenCover(isPresented: $showingInputView) {
                InputContainerView(isPresented: $showingInputView)
            }
            .alert(
                "Connection Error",
                isPresented: $viewModel.showingConnectionError
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .overlay {
                if case .connecting = connectionManager.connectionState {
                    ConnectingIndicatorView()
                }
            }
            .onChange(of: connectionManager.connectionState) { _, newState in
                if case .connected = newState {
                    showingInputView = true
                } else if case .failed(let error) = newState {
                    viewModel.errorMessage = error.localizedDescription
                    viewModel.showingConnectionError = true
                }
            }
        }
    }
}

#Preview {
    MainView()
}
