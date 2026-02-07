//
//  DeviceListViewModel.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import Foundation
import SwiftUI

/// View model for the device list screen
/// Manages saved devices and connection initiation
@MainActor
class DeviceListViewModel: ObservableObject {
  /// Device storage manager
  @Published var storage = DeviceStorage()
  /// Controls visibility of the add device sheet
  @Published var showingAddDevice = false
  /// Controls visibility of connection error alerts
  @Published var showingConnectionError = false
  /// Current error message to display
  @Published var errorMessage = ""

  /// List of all saved devices
  var devices: [SavedDevice] {
    storage.devices
  }

  /**
   Adds a new device to the saved devices list.
   Validates the IP address format before saving.
  
   - Parameters:
     - name: Display name for the device
     - ipAddress: IP address in dotted decimal format
   */
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

  /**
   Deletes a specific device from the saved devices list.
  
   - Parameter device: The device to delete
   */
  func deleteDevice(_ device: SavedDevice) {
    storage.deleteDevice(device)
  }

  /**
   Deletes devices at the specified indices.
  
   - Parameter indexSet: Set of indices to delete
   */
  func deleteDevices(at indexSet: IndexSet) {
    storage.deleteDevice(at: indexSet)
  }

  /**
   Initiates a connection to the specified device.
  
   - Parameter device: The device to connect to
   */
  func connectToDevice(_ device: SavedDevice) async {
    await ConnectionManager.shared.connect(to: device)
  }
}
