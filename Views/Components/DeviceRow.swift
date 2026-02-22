//
//  DeviceRow.swift
//  MouseKit
//
//  Created by Charles Little on 22/02/2026.
//

import SwiftUI

///Device Row Component
struct DeviceRow: View {
  let device: SavedDevice
  let isDefault: Bool
  let onTap: () -> Void
  let onRemoveDefault: (() -> Void)?
  let onSetDefault: (() -> Void)?

  var body: some View {
    Button {
      onTap()
    } label: {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 6) {
            Text(device.name)
              .font(.headline)
            if isDefault {
              Image(systemName: "star.fill")
                .font(.caption)
                .foregroundColor(.yellow)
            }
          }
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
    .contextMenu {
      if let onRemoveDefault {
        Button(role: .destructive) {
          onRemoveDefault()
        } label: {
          Label("Remove Default", systemImage: "star.slash")
        }
      }

      if let onSetDefault {
        Button {
          onSetDefault()
        } label: {
          Label("Set as Default", systemImage: "star")
        }
      }
    }
  }
}

#Preview("Default Device") {
  DeviceRow(
    device: SavedDevice(id: UUID(), name: "My Computer", ipAddress: "192.168.1.100", ),
    isDefault: true, onTap: {}, onRemoveDefault: {}, onSetDefault: {}
  )
  .padding()
}

#Preview("Non-Default Device") {
  DeviceRow(
    device: SavedDevice(id: UUID(), name: "My Computer", ipAddress: "192.168.1.100", ),
    isDefault: false, onTap: {}, onRemoveDefault: {}, onSetDefault: {}
  )
  .padding()
}
