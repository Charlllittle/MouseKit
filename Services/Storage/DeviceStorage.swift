//
//  DeviceStorage.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import Foundation

class DeviceStorage: ObservableObject {
    @Published private(set) var devices: [SavedDevice] = []

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadDevices()
    }

    func loadDevices() {
        guard let data = userDefaults.data(forKey: Constants.UserDefaultsKeys.savedDevices),
              let decoded = try? JSONDecoder().decode([SavedDevice].self, from: data) else {
            devices = []
            return
        }
        devices = decoded
    }

    func saveDevice(_ device: SavedDevice) {
        devices.append(device)
        persistDevices()
    }

    func deleteDevice(_ device: SavedDevice) {
        devices.removeAll { $0.id == device.id }
        persistDevices()
    }

    func deleteDevice(at indexSet: IndexSet) {
        devices.remove(atOffsets: indexSet)
        persistDevices()
    }

    private func persistDevices() {
        guard let encoded = try? JSONEncoder().encode(devices) else {
            return
        }
        userDefaults.set(encoded, forKey: Constants.UserDefaultsKeys.savedDevices)
    }

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
