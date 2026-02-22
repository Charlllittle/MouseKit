//
//  DeviceStorage.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import Foundation

/// Manages persistent storage of saved devices using UserDefaults
class DeviceStorage: ObservableObject {
  /// List of saved devices
  @Published private(set) var devices: [SavedDevice] = []
  /// UUID of the designated default device, if any
  @Published private(set) var defaultDeviceId: UUID?
  /// Whether auto-connect on launch is enabled
  @Published private(set) var autoConnectEnabled: Bool = false

  /// UserDefaults instance for persistence
  private let userDefaults: UserDefaults

  /**
   Creates a new device storage manager.

   - Parameter userDefaults: UserDefaults instance (defaults to .standard)
   */
  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
    loadDevices()
    autoConnectEnabled = userDefaults.bool(forKey: Constants.UserDefaultsKeys.autoConnectEnabled)
    if let idString = userDefaults.string(forKey: Constants.UserDefaultsKeys.defaultDeviceId),
       let id = UUID(uuidString: idString) {
      defaultDeviceId = id
    }
  }

  /// Loads saved devices from UserDefaults
  func loadDevices() {
    guard let data = userDefaults.data(forKey: Constants.UserDefaultsKeys.savedDevices),
      let decoded = try? JSONDecoder().decode([SavedDevice].self, from: data)
    else {
      devices = []
      return
    }
    devices = decoded
  }

  /**
   Adds a new device to the saved devices list.
  
   - Parameter device: The device to save
   */
  func saveDevice(_ device: SavedDevice) {
    devices.append(device)
    persistDevices()
  }

  /**
   Removes a specific device from the saved devices list.
   Clears the default device if the deleted device was the default.

   - Parameter device: The device to delete
   */
  func deleteDevice(_ device: SavedDevice) {
    if device.id == defaultDeviceId {
      setDefaultDevice(nil)
    }
    devices.removeAll { $0.id == device.id }
    persistDevices()
  }

  /**
   Removes devices at the specified indices.
   Clears the default device if the deleted device was the default.

   - Parameter indexSet: Set of indices to delete
   */
  func deleteDevice(at indexSet: IndexSet) {
    let deletedDevices = indexSet.map { devices[$0] }
    if deletedDevices.contains(where: { $0.id == defaultDeviceId }) {
      setDefaultDevice(nil)
    }
    devices.remove(atOffsets: indexSet)
    persistDevices()
  }

  /**
   Sets or clears the default device.

   - Parameter device: The device to mark as default, or nil to clear
   */
  func setDefaultDevice(_ device: SavedDevice?) {
    if let id = device?.id {
      userDefaults.set(id.uuidString, forKey: Constants.UserDefaultsKeys.defaultDeviceId)
      defaultDeviceId = id
    } else {
      userDefaults.removeObject(forKey: Constants.UserDefaultsKeys.defaultDeviceId)
      defaultDeviceId = nil
    }
  }

  /**
   Enables or disables auto-connect on launch.

   - Parameter enabled: Whether auto-connect should be enabled
   */
  func setAutoConnect(_ enabled: Bool) {
    autoConnectEnabled = enabled
    userDefaults.set(enabled, forKey: Constants.UserDefaultsKeys.autoConnectEnabled)
  }

  /// Saves the current device list to UserDefaults
  private func persistDevices() {
    guard let encoded = try? JSONEncoder().encode(devices) else {
      return
    }
    userDefaults.set(encoded, forKey: Constants.UserDefaultsKeys.savedDevices)
  }

  /**
   Validates an IP address format (IPv4 dotted decimal notation).
  
   - Parameter ipAddress: The IP address string to validate
   - Returns: True if the format is valid, false otherwise
   */
  static func isValidIPAddress(_ ipAddress: String) -> Bool {
    // Use omittingEmptySubsequences: false to catch leading/trailing/consecutive dots
    let parts = ipAddress.split(separator: ".", omittingEmptySubsequences: false)
    guard parts.count == 4 else { return false }

    return parts.allSatisfy { part in
      // Empty parts indicate leading, trailing, or consecutive dots
      guard !part.isEmpty else { return false }
      
      guard let number = Int(part), number >= 0, number <= 255 else {
        return false
      }
      return true
    }
  }
}
