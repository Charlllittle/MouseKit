//
//  DeviceListViewModelTests.swift
//  MouseKitTests
//
//  Created by Charles Little on 22/02/2026.
//

import Foundation
import Testing

@testable import MouseKit

@MainActor
@Suite("Device List View Model Tests")
struct DeviceListViewModelTests {

  // MARK: - Test Helpers

  /// Creates a fresh UserDefaults instance for testing
  private func createTestUserDefaults() -> UserDefaults {
    let suiteName = "test.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
  }

  /// Creates a view model with a test storage instance
  private func createViewModel() -> DeviceListViewModel {
    let viewModel = DeviceListViewModel()
    viewModel.storage = DeviceStorage(
      userDefaults: createTestUserDefaults()
    )
    return viewModel
  }

  // MARK: - Initial State Tests

  @Test("View model initializes with empty state")
  func initialState() async throws {
    let viewModel = createViewModel()

    #expect(viewModel.devices.isEmpty)
    #expect(viewModel.defaultDeviceId == nil)
    #expect(viewModel.defaultDevice == nil)
    #expect(!viewModel.autoConnectEnabled)
    #expect(!viewModel.showingAddDevice)
    #expect(!viewModel.showingConnectionError)
    #expect(viewModel.errorMessage.isEmpty)
  }

  // MARK: - Add Device Tests

  @Test("Adding a valid device succeeds")
  func addValidDevice() async throws {
    let viewModel = createViewModel()

    viewModel.addDevice(name: "Test Device", ipAddress: "192.168.1.100")

    #expect(viewModel.devices.count == 1)
    #expect(viewModel.devices.first?.name == "Test Device")
    #expect(viewModel.devices.first?.ipAddress == "192.168.1.100")
    #expect(!viewModel.showingConnectionError)
  }

  @Test("Adding device with invalid IP address shows error")
  func addDeviceWithInvalidIP() async throws {
    let viewModel = createViewModel()

    viewModel.addDevice(name: "Test Device", ipAddress: "invalid.ip")

    #expect(viewModel.devices.isEmpty)
    #expect(viewModel.showingConnectionError)
    #expect(viewModel.errorMessage == "Invalid IP address format")
  }

  @Test("Adding device with IP out of range shows error")
  func addDeviceWithIPOutOfRange() async throws {
    let viewModel = createViewModel()

    viewModel.addDevice(name: "Test Device", ipAddress: "192.168.1.256")

    #expect(viewModel.devices.isEmpty)
    #expect(viewModel.showingConnectionError)
  }

  @Test("Adding multiple devices")
  func addMultipleDevices() async throws {
    let viewModel = createViewModel()

    viewModel.addDevice(name: "Device 1", ipAddress: "192.168.1.100")
    viewModel.addDevice(name: "Device 2", ipAddress: "192.168.1.101")
    viewModel.addDevice(name: "Device 3", ipAddress: "10.0.0.1")

    #expect(viewModel.devices.count == 3)
    #expect(viewModel.devices[0].name == "Device 1")
    #expect(viewModel.devices[1].name == "Device 2")
    #expect(viewModel.devices[2].name == "Device 3")
  }

  @Test("Adding device and setting as default")
  func addDeviceAsDefault() async throws {
    let viewModel = createViewModel()

    viewModel.addDevice(
      name: "Default Device",
      ipAddress: "192.168.1.100",
      setAsDefault: true
    )

    #expect(viewModel.devices.count == 1)
    let device = try #require(viewModel.devices.first)
    #expect(viewModel.defaultDeviceId == device.id)
    #expect(viewModel.defaultDevice?.id == device.id)
  }

  // MARK: - Delete Device Tests

  @Test("Deleting a specific device")
  func deleteSpecificDevice() async throws {
    let viewModel = createViewModel()

    viewModel.addDevice(name: "Device 1", ipAddress: "192.168.1.100")
    viewModel.addDevice(name: "Device 2", ipAddress: "192.168.1.101")

    let deviceToDelete = viewModel.devices[0]
    viewModel.deleteDevice(deviceToDelete)

    #expect(viewModel.devices.count == 1)
    #expect(viewModel.devices.first?.name == "Device 2")
  }

  @Test("Deleting devices by index set")
  func deleteDevicesByIndexSet() async throws {
    let viewModel = createViewModel()

    viewModel.addDevice(name: "Device 1", ipAddress: "192.168.1.100")
    viewModel.addDevice(name: "Device 2", ipAddress: "192.168.1.101")
    viewModel.addDevice(name: "Device 3", ipAddress: "192.168.1.102")

    viewModel.deleteDevices(at: IndexSet([0, 2]))

    #expect(viewModel.devices.count == 1)
    #expect(viewModel.devices.first?.name == "Device 2")
  }

  @Test("Deleting default device clears default")
  func deleteDefaultDevice() async throws {
    let viewModel = createViewModel()

    viewModel.addDevice(name: "Default Device", ipAddress: "192.168.1.100")
    let device = viewModel.devices[0]
    viewModel.setDefaultDevice(device)

    #expect(viewModel.defaultDeviceId != nil)

    viewModel.deleteDevice(device)

    #expect(viewModel.devices.isEmpty)
    #expect(viewModel.defaultDeviceId == nil)
  }

  // MARK: - Default Device Tests

  @Test("Setting a device as default")
  func setDefaultDevice() async throws {
    let viewModel = createViewModel()

    viewModel.addDevice(name: "Device 1", ipAddress: "192.168.1.100")
    viewModel.addDevice(name: "Device 2", ipAddress: "192.168.1.101")

    let device = viewModel.devices[1]
    viewModel.setDefaultDevice(device)

    #expect(viewModel.defaultDeviceId == device.id)
    #expect(viewModel.defaultDevice?.id == device.id)
    #expect(viewModel.defaultDevice?.name == "Device 2")
  }

  @Test("Removing default device")
  func removeDefaultDevice() async throws {
    let viewModel = createViewModel()

    viewModel.addDevice(name: "Device", ipAddress: "192.168.1.100")
    let device = viewModel.devices[0]
    viewModel.setDefaultDevice(device)

    #expect(viewModel.defaultDeviceId != nil)

    viewModel.removeDefaultDevice()

    #expect(viewModel.defaultDeviceId == nil)
    #expect(viewModel.defaultDevice == nil)
  }

  @Test("Changing default device from one to another")
  func changeDefaultDevice() async throws {
    let viewModel = createViewModel()

    viewModel.addDevice(name: "Device 1", ipAddress: "192.168.1.100")
    viewModel.addDevice(name: "Device 2", ipAddress: "192.168.1.101")

    let device1 = viewModel.devices[0]
    let device2 = viewModel.devices[1]

    viewModel.setDefaultDevice(device1)
    #expect(viewModel.defaultDeviceId == device1.id)

    viewModel.setDefaultDevice(device2)
    #expect(viewModel.defaultDeviceId == device2.id)
    #expect(viewModel.defaultDevice?.name == "Device 2")
  }

  @Test("Getting default device")
  func getDefaultDevice() async throws {
    let viewModel = createViewModel()

    #expect(viewModel.getDefaultDevice() == nil)

    viewModel.addDevice(name: "Default Device", ipAddress: "192.168.1.100")
    let device = viewModel.devices[0]
    viewModel.setDefaultDevice(device)

    let retrievedDevice = try #require(viewModel.getDefaultDevice())
    #expect(retrievedDevice.id == device.id)
    #expect(retrievedDevice.name == "Default Device")
  }

  // MARK: - Non-Default Devices Tests

  @Test("Getting non-default devices when no default is set")
  func getNonDefaultDevicesWithoutDefault() async throws {
    let viewModel = createViewModel()

    viewModel.addDevice(name: "Device 1", ipAddress: "192.168.1.100")
    viewModel.addDevice(name: "Device 2", ipAddress: "192.168.1.101")

    let nonDefaultDevices = viewModel.getnonDefaultDevices()

    #expect(nonDefaultDevices.count == 2)
  }

  @Test("Getting non-default devices when default is set")
  func getNonDefaultDevicesWithDefault() async throws {
    let viewModel = createViewModel()

    viewModel.addDevice(name: "Device 1", ipAddress: "192.168.1.100")
    viewModel.addDevice(name: "Device 2", ipAddress: "192.168.1.101")
    viewModel.addDevice(name: "Device 3", ipAddress: "192.168.1.102")

    let defaultDevice = viewModel.devices[1]
    viewModel.setDefaultDevice(defaultDevice)

    let nonDefaultDevices = viewModel.getnonDefaultDevices()

    #expect(nonDefaultDevices.count == 2)
    #expect(
      !nonDefaultDevices.contains(where: { $0.id == defaultDevice.id })
    )
    #expect(nonDefaultDevices.contains(where: { $0.name == "Device 1" }))
    #expect(nonDefaultDevices.contains(where: { $0.name == "Device 3" }))
  }

  @Test("Checking if non-default devices exist")
  func checkNonDefaultDevicesExist() async throws {
    let viewModel = createViewModel()

    #expect(!viewModel.doNonDefaultDevicesExist())

    viewModel.addDevice(name: "Device 1", ipAddress: "192.168.1.100")
    #expect(viewModel.doNonDefaultDevicesExist())

    let device = viewModel.devices[0]
    viewModel.setDefaultDevice(device)
    #expect(!viewModel.doNonDefaultDevicesExist())

    viewModel.addDevice(name: "Device 2", ipAddress: "192.168.1.101")
    #expect(viewModel.doNonDefaultDevicesExist())
  }

  @Test("Deleting non-default devices by index")
  func deleteNonDefaultDevices() async throws {
    let viewModel = createViewModel()

    viewModel.addDevice(name: "Default Device", ipAddress: "192.168.1.100")
    viewModel.addDevice(name: "Device 2", ipAddress: "192.168.1.101")
    viewModel.addDevice(name: "Device 3", ipAddress: "192.168.1.102")
    viewModel.addDevice(name: "Device 4", ipAddress: "192.168.1.103")

    let defaultDevice = viewModel.devices[0]
    viewModel.setDefaultDevice(defaultDevice)

    // Delete the second and third non-default devices (indices 1 and 2 in the non-default array)
    // These correspond to "Device 3" and "Device 4" in the full array
    viewModel.deleteNonDefaultDevices(at: IndexSet([1, 2]))

    #expect(viewModel.devices.count == 2)
    #expect(
      viewModel.devices.contains(where: { $0.name == "Default Device" })
    )
    #expect(viewModel.devices.contains(where: { $0.name == "Device 2" }))
    #expect(viewModel.defaultDeviceId == defaultDevice.id)  // Default should still be set
  }

  @Test("Deleting non-default device at first index")
  func deleteFirstNonDefaultDevice() async throws {
    let viewModel = createViewModel()

    viewModel.addDevice(name: "Default Device", ipAddress: "192.168.1.100")
    viewModel.addDevice(name: "Other Device 1", ipAddress: "192.168.1.101")
    viewModel.addDevice(name: "Other Device 2", ipAddress: "192.168.1.102")

    viewModel.setDefaultDevice(viewModel.devices[0])

    viewModel.deleteNonDefaultDevices(at: IndexSet([0]))

    #expect(viewModel.devices.count == 2)
    #expect(
      viewModel.devices.contains(where: { $0.name == "Default Device" })
    )
    #expect(
      viewModel.devices.contains(where: { $0.name == "Other Device 2" })
    )
  }

  // MARK: - Auto-Connect Tests

  @Test("Setting auto-connect enabled")
  func setAutoConnectEnabled() async throws {
    let viewModel = createViewModel()

    #expect(!viewModel.autoConnectEnabled)

    viewModel.setAutoConnect(true)

    #expect(viewModel.autoConnectEnabled)
  }

  @Test("Setting auto-connect disabled")
  func setAutoConnectDisabled() async throws {
    let viewModel = createViewModel()

    viewModel.setAutoConnect(true)
    #expect(viewModel.autoConnectEnabled)

    viewModel.setAutoConnect(false)
    #expect(!viewModel.autoConnectEnabled)
  }

  // MARK: - IP Validation Tests

  @Test(
    "Valid IP addresses are accepted",
    arguments: [
      "192.168.1.1",
      "10.0.0.1",
      "172.16.0.1",
      "255.255.255.255",
      "0.0.0.0",
      "127.0.0.1",
    ]
  )
  func validIPAddresses(ipAddress: String) async throws {
    let viewModel = createViewModel()

    viewModel.addDevice(name: "Test", ipAddress: ipAddress)

    #expect(viewModel.devices.count == 1)
    #expect(!viewModel.showingConnectionError)
  }

  @Test(
    "Invalid IP addresses are rejected",
    arguments: [
      "192.168.1",  // Too few octets
      "192.168.1.1.1",  // Too many octets
      "192.168.1.256",  // Octet out of range
      "192.168.-1.1",  // Negative number
      "abc.def.ghi.jkl",  // Non-numeric
      "192.168.1.1a",  // Contains letters
      "",  // Empty string
      "....",  // Only dots
      "192.168.1.",  // Trailing dot
      ".192.168.1.1",  // Leading dot
    ]
  )
  func invalidIPAddresses(ipAddress: String) async throws {
    let viewModel = createViewModel()

    viewModel.addDevice(name: "Test", ipAddress: ipAddress)

    #expect(viewModel.devices.isEmpty)
    #expect(viewModel.showingConnectionError)
    #expect(viewModel.errorMessage == "Invalid IP address format")
  }

  // MARK: - State Management Tests

  @Test("showingAddDevice flag toggles correctly")
  func showingAddDeviceToggle() async throws {
    let viewModel = createViewModel()

    #expect(!viewModel.showingAddDevice)

    viewModel.showingAddDevice = true
    #expect(viewModel.showingAddDevice)

    // Adding a valid device should close the sheet
    viewModel.addDevice(name: "Test", ipAddress: "192.168.1.100")
    #expect(!viewModel.showingAddDevice)
  }

  @Test("Error state is set correctly on invalid input")
  func errorStateOnInvalidInput() async throws {
    let viewModel = createViewModel()

    #expect(!viewModel.showingConnectionError)
    #expect(viewModel.errorMessage.isEmpty)

    viewModel.addDevice(name: "Test", ipAddress: "invalid")

    #expect(viewModel.showingConnectionError)
    #expect(!viewModel.errorMessage.isEmpty)
  }

  // MARK: - Complex Scenarios

  @Test("Complete workflow: Add, set default, add more, delete")
  func completeWorkflow() async throws {
    let viewModel = createViewModel()

    // Start with empty state
    #expect(viewModel.devices.isEmpty)

    // Add first device and set as default
    viewModel.addDevice(name: "Main Computer", ipAddress: "192.168.1.100")
    let mainDevice = viewModel.devices[0]
    viewModel.setDefaultDevice(mainDevice)

    #expect(viewModel.devices.count == 1)
    #expect(viewModel.defaultDeviceId == mainDevice.id)

    // Add more devices
    viewModel.addDevice(name: "Laptop", ipAddress: "192.168.1.101")
    viewModel.addDevice(name: "Work PC", ipAddress: "192.168.1.102")

    #expect(viewModel.devices.count == 3)
    #expect(viewModel.getnonDefaultDevices().count == 2)

    // Delete a non-default device
    viewModel.deleteNonDefaultDevices(at: IndexSet([0]))

    #expect(viewModel.devices.count == 2)
    #expect(viewModel.defaultDeviceId == mainDevice.id)  // Default unchanged

    // Change default
    let newDefault = viewModel.getnonDefaultDevices()[0]
    viewModel.setDefaultDevice(newDefault)

    #expect(viewModel.defaultDeviceId == newDefault.id)
    #expect(viewModel.getnonDefaultDevices().count == 1)
  }

  @Test("Persistence across view model instances")
  func persistenceAcrossInstances() async throws {
    let userDefaults = createTestUserDefaults()

    // First instance
    let viewModel1 = DeviceListViewModel()
    viewModel1.storage = DeviceStorage(userDefaults: userDefaults)

    viewModel1.addDevice(
      name: "Persistent Device",
      ipAddress: "192.168.1.100"
    )
    viewModel1.setDefaultDevice(viewModel1.devices[0])
    viewModel1.setAutoConnect(true)

    let deviceId = viewModel1.devices[0].id

    // Second instance with same UserDefaults
    let viewModel2 = DeviceListViewModel()
    viewModel2.storage = DeviceStorage(userDefaults: userDefaults)

    #expect(viewModel2.devices.count == 1)
    #expect(viewModel2.devices[0].name == "Persistent Device")
    #expect(viewModel2.defaultDeviceId == deviceId)
    #expect(viewModel2.autoConnectEnabled)
  }

  @Test("Edge case: Delete all devices")
  func deleteAllDevices() async throws {
    let viewModel = createViewModel()

    viewModel.addDevice(name: "Device 1", ipAddress: "192.168.1.100")
    viewModel.addDevice(name: "Device 2", ipAddress: "192.168.1.101")
    viewModel.setDefaultDevice(viewModel.devices[0])

    #expect(viewModel.devices.count == 2)

    viewModel.deleteDevices(at: IndexSet([0, 1]))

    #expect(viewModel.devices.isEmpty)
    #expect(viewModel.defaultDeviceId == nil)
    #expect(!viewModel.doNonDefaultDevicesExist())
  }

  @Test("Edge case: Only default device exists")
  func onlyDefaultDeviceExists() async throws {
    let viewModel = createViewModel()

    viewModel.addDevice(name: "Only Device", ipAddress: "192.168.1.100")
    viewModel.setDefaultDevice(viewModel.devices[0])

    #expect(viewModel.devices.count == 1)
    #expect(viewModel.getnonDefaultDevices().isEmpty)
    #expect(!viewModel.doNonDefaultDevicesExist())
    #expect(viewModel.getDefaultDevice() != nil)
  }
}
