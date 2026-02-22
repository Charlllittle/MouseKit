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

    /// UUID of the designated default device, if any
    var defaultDeviceId: UUID? { storage.defaultDeviceId }
    /// Whether auto-connect on launch is enabled
    var autoConnectEnabled: Bool { storage.autoConnectEnabled }
    /// The designated default device, if any
    var defaultDevice: SavedDevice? {
        devices.first { $0.id == storage.defaultDeviceId }
    }

    /**
     Adds a new device to the saved devices list.
     Validates the IP address format before saving.
    
     - Parameters:
       - name: Display name for the device
       - ipAddress: IP address in dotted decimal format
     */
    func addDevice(name: String, ipAddress: String, setAsDefault: Bool = false) {
        guard DeviceStorage.isValidIPAddress(ipAddress) else {
            errorMessage = "Invalid IP address format"
            showingConnectionError = true
            return
        }

        let device = SavedDevice(name: name, ipAddress: ipAddress)
        storage.saveDevice(device)
        if setAsDefault {
            storage.setDefaultDevice(device)
        }
        showingAddDevice = false
        objectWillChange.send()
    }

    /**
     Deletes a specific device from the saved devices list.
    
     - Parameter device: The device to delete
     */
    func deleteDevice(_ device: SavedDevice) {
        storage.deleteDevice(device)
        objectWillChange.send()
    }

    /**
     Deletes devices at the specified indices.
    
     - Parameter indexSet: Set of indices to delete
     */
    func deleteDevices(at indexSet: IndexSet) {
        storage.deleteDevice(at: indexSet)
        objectWillChange.send()
    }

    /**
     Sets a device as the default device.
    
     - Parameter device: The device to set as default
     */
    func setDefaultDevice(_ device: SavedDevice) {
        withAnimation {
            storage.setDefaultDevice(device)
            objectWillChange.send()
        }
    }

    /// Clears the current default device.
    func removeDefaultDevice() {
        withAnimation {
            storage.setDefaultDevice(nil)
            objectWillChange.send()
        }
    }

    /**
     Enables or disables auto-connect on launch.
    
     - Parameter enabled: Whether auto-connect should be enabled
     */
    func setAutoConnect(_ enabled: Bool) {
        storage.setAutoConnect(enabled)
    }
    
    /**
     Retrieves the current default device, if one is set.
     
     - Returns: The default device, or nil if no default is set
     */
    func getDefaultDevice() -> SavedDevice? {
        guard let defaultId = storage.defaultDeviceId else { return nil }
        return devices.first { $0.id == defaultId }
    }
    
    /**
     Retrieves the list of non-default devices.
     
     - Returns: An array of devices that are not set as the default
     */
    func getnonDefaultDevices() -> [SavedDevice] {
        guard let defaultId = storage.defaultDeviceId else { return devices }
        return devices.filter { $0.id != defaultId }
    }
    
    /**
     Checks if there are any non-default devices in the saved devices list.
     
     - Returns: True if there are non-default devices, false otherwise
     */
    func doNonDefaultDevicesExist() -> Bool {
        guard let defaultId = storage.defaultDeviceId else { return !devices.isEmpty }
        return devices.contains { $0.id != defaultId }
    }
    
    /**
     Deletes non-default devices at the specified indices.
     This method maps indices from the non-default devices array to the full devices array.
     
     - Parameter indexSet: Set of indices from the non-default devices array
     */
    func deleteNonDefaultDevices(at indexSet: IndexSet) {
        let nonDefaultDevices = getnonDefaultDevices()
        
        // Map the indices from nonDefaultDevices to the full devices array
        let devicesToDelete = indexSet.map { nonDefaultDevices[$0] }
        let actualIndices = IndexSet(devicesToDelete.compactMap { deviceToDelete in
            devices.firstIndex(where: { $0.id == deviceToDelete.id })
        })
        
        deleteDevices(at: actualIndices)
    }

    /**
     Initiates a connection to the specified device.
    
     - Parameter device: The device to connect to
     */
    func connectToDevice(_ device: SavedDevice) async {
        await ConnectionManager.shared.connect(to: device)
    }
}
