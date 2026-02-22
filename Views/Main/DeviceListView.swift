//
//  DeviceListView.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import SwiftUI

struct DeviceListView: View {
    @ObservedObject var viewModel: DeviceListViewModel
    @Binding var showingInputView: Bool

    var body: some View {
        let defaultDevice = viewModel.getDefaultDevice()
        let nonDefaultDevices = viewModel.getnonDefaultDevices()
        
        List {
            // Default Device Section
            if let device = defaultDevice {
                Section {
                    DeviceRow(
                        device: device,
                        isDefault: true,
                        onTap: {
                            Task {
                                await viewModel.connectToDevice(device)
                            }
                        },
                        onRemoveDefault: {
                            viewModel.removeDefaultDevice()
                        },
                        onSetDefault: nil
                    )
                    .id(device.id)
                } header: {
                    Text("Default Device")
                }
            }

            // Other Devices Section
            if !nonDefaultDevices.isEmpty {
                Section {
                    ForEach(nonDefaultDevices) { device in
                        DeviceRow(
                            device: device,
                            isDefault: false,
                            onTap: {
                                Task {
                                    await viewModel.connectToDevice(device)
                                }
                            },
                            onRemoveDefault: nil,
                            onSetDefault: {
                                viewModel.setDefaultDevice(device)
                            }
                        )
                        .id(device.id)
                    }
                    .onDelete { indexSet in
                        viewModel.deleteNonDefaultDevices(at: indexSet)
                    }
                } header: {
                    Text("Other Devices")
                }
            }
        }
        .animation(.easeInOut, value: viewModel.storage.defaultDeviceId)
    }
}

#Preview {
    let viewModel = DeviceListViewModel()
    viewModel.addDevice(name: "Office Laptop", ipAddress: "192.168.0.100", setAsDefault: true)
    return DeviceListView(viewModel: viewModel, showingInputView: .constant(false))
}
