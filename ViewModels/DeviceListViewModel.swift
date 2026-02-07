//
//  DeviceListViewModel.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import Foundation
import SwiftUI

@MainActor
class DeviceListViewModel: ObservableObject {
  @Published var storage = DeviceStorage()
  @Published var showingAddDevice = false
  @Published var showingConnectionError = false
  @Published var errorMessage = ""

  var devices: [SavedDevice] {
    storage.devices
  }

  func addDevice(name: String, ipAddress: String) {
    guard DeviceStorage.isValidIPAddress(ipAddress) else {
      errorMessage = "Invalid IP address format"
      showingConnectionError = true
      return
    }

    let device = SavedDevice(name: name, ipAddress: ipAddress)
    storage.saveDevice(device)
    showingAddDevice = false
  }

  func deleteDevice(_ device: SavedDevice) {
    storage.deleteDevice(device)
  }

  func deleteDevices(at indexSet: IndexSet) {
    storage.deleteDevice(at: indexSet)
  }

  func connectToDevice(_ device: SavedDevice) async {
    await ConnectionManager.shared.connect(to: device)
  }
}
