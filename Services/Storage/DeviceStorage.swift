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

    /// UserDefaults instance for persistence
    private let userDefaults: UserDefaults

    /**
     Creates a new device storage manager.

     - Parameter userDefaults: UserDefaults instance (defaults to .standard)
     */
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadDevices()
    }

    /// Loads saved devices from UserDefaults
    func loadDevices() {
        guard let data = userDefaults.data(forKey: Constants.UserDefaultsKeys.savedDevices),
              let decoded = try? JSONDecoder().decode([SavedDevice].self, from: data) else {
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

     - Parameter device: The device to delete
     */
    func deleteDevice(_ device: SavedDevice) {
        devices.removeAll { $0.id == device.id }
        persistDevices()
    }

    /**
     Removes devices at the specified indices.

     - Parameter indexSet: Set of indices to delete
     */
    func deleteDevice(at indexSet: IndexSet) {
        devices.remove(atOffsets: indexSet)
        persistDevices()
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
        let parts = ipAddress.split(separator: ".")
        guard parts.count == 4 else { return false }

        return parts.allSatisfy { part in
            guard let number = Int(part), number >= 0, number <= 255 else {
                return false
            }
            return true
        }
    }
}
