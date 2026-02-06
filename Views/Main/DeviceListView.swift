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
        List {
            ForEach(viewModel.devices) { device in
                Button {
                    Task {
                        await viewModel.connectToDevice(device)
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(device.name)
                                .font(.headline)
                            Text(device.ipAddress)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .onDelete { indexSet in
                viewModel.deleteDevices(at: indexSet)
            }
        }
    }
}
