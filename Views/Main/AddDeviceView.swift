//
//  AddDeviceView.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import SwiftUI

struct AddDeviceView: View {
    @ObservedObject var viewModel: DeviceListViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var deviceName = ""
    @State private var ipAddress = ""
    @State private var setAsDefault = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Device Name", text: $deviceName)
                        .textContentType(.name)

                    TextField("IP Address", text: $ipAddress)
                        .textContentType(.none)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Device Information")
                } footer: {
                    Text(
                        "Enter the IP address of your Mousedroid server (e.g., 192.168.1.100)"
                    )
                }

                Section {
                    // Set default device
                    Toggle(
                        "Set as Default Device",
                        isOn: $setAsDefault
                    )
                } footer: {
                    Text(
                        "If enabled, this device will be the default for auto-connection."
                    )
                }
            }
            .navigationTitle("Add Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addDevice(
                            name: deviceName,
                            ipAddress: ipAddress,
                            setAsDefault: setAsDefault
                        )
                        if !viewModel.showingConnectionError {
                            dismiss()
                        }
                    }
                    .disabled(deviceName.isEmpty || ipAddress.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddDeviceView(viewModel: DeviceListViewModel())
}
