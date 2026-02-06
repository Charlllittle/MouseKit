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
                    Text("Enter the IP address of your Mousedroid server (e.g., 192.168.1.100)")
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
                        viewModel.addDevice(name: deviceName, ipAddress: ipAddress)
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
