//
//  SettingsView.swift
//  MouseKit
//
//  Created by Charles Little on 22/02/2026.
//

import SwiftUI

/// Settings View for managing app preferences
struct SettingsView: View {
  @ObservedObject var viewModel: DeviceListViewModel
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Form {
        Section("Connection") {
          Toggle(
            "Auto-connect to Default Device",
            isOn: Binding(
              get: { viewModel.autoConnectEnabled },
              set: { viewModel.setAutoConnect($0) }
            )
          )

          if viewModel.autoConnectEnabled {
            if let device = viewModel.defaultDevice {
              LabeledContent("Default Device", value: device.name)
                .foregroundColor(.secondary)
            } else {
              Text("Long-press a device to set it as the default.")
                .font(.footnote)
                .foregroundColor(.secondary)
            }
          }
        }
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
  }
}

#Preview("Default Device Set") {
  SettingsView(viewModel: DeviceListViewModel())
}
