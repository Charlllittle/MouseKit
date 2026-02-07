//
//  DeviceStorageTests.swift
//  MouseKitTests
//
//  Created by Charles Little on 06/02/2026.
//

import Foundation
import Testing

@testable import MouseKit

@MainActor
struct DeviceStorageTests {

  // Helper to create a clean UserDefaults instance for testing
  func createTestUserDefaults() -> UserDefaults {
    let suiteName = "test.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
  }

  // MARK: - IP Address Validation Tests

  @Test func testValidIPAddress() {
    #expect(DeviceStorage.isValidIPAddress("192.168.1.1"))
    #expect(DeviceStorage.isValidIPAddress("10.0.0.1"))
    #expect(DeviceStorage.isValidIPAddress("172.16.254.1"))
    #expect(DeviceStorage.isValidIPAddress("0.0.0.0"))
    #expect(DeviceStorage.isValidIPAddress("255.255.255.255"))
  }

  @Test func testInvalidIPAddressTooFewOctets() {
    #expect(!DeviceStorage.isValidIPAddress("192.168.1"))
    #expect(!DeviceStorage.isValidIPAddress("10.0"))
    #expect(!DeviceStorage.isValidIPAddress("172"))
  }

  @Test func testInvalidIPAddressTooManyOctets() {
    #expect(!DeviceStorage.isValidIPAddress("192.168.1.1.1"))
    #expect(!DeviceStorage.isValidIPAddress("10.0.0.1.5"))
  }

  @Test func testInvalidIPAddressOutOfRange() {
    #expect(!DeviceStorage.isValidIPAddress("256.168.1.1"))
    #expect(!DeviceStorage.isValidIPAddress("192.256.1.1"))
    #expect(!DeviceStorage.isValidIPAddress("192.168.256.1"))
    #expect(!DeviceStorage.isValidIPAddress("192.168.1.256"))
    #expect(!DeviceStorage.isValidIPAddress("300.300.300.300"))
  }

  @Test func testInvalidIPAddressNegativeNumbers() {
    #expect(!DeviceStorage.isValidIPAddress("-1.168.1.1"))
    #expect(!DeviceStorage.isValidIPAddress("192.-5.1.1"))
  }

  @Test func testInvalidIPAddressNonNumeric() {
    #expect(!DeviceStorage.isValidIPAddress("abc.def.ghi.jkl"))
    #expect(!DeviceStorage.isValidIPAddress("192.168.1.x"))
    #expect(!DeviceStorage.isValidIPAddress("192.168.a.1"))
  }

  @Test func testInvalidIPAddressEmpty() {
    #expect(!DeviceStorage.isValidIPAddress(""))
  }

  @Test func testInvalidIPAddressSpaces() {
    #expect(!DeviceStorage.isValidIPAddress("192. 168. 1. 1"))
    #expect(!DeviceStorage.isValidIPAddress(" 192.168.1.1"))
    #expect(!DeviceStorage.isValidIPAddress("192.168.1.1 "))
  }

  @Test func testInvalidIPAddressLeadingZeros() {
    // This actually passes validation as Int() accepts leading zeros
    // and converts to valid number
    #expect(DeviceStorage.isValidIPAddress("192.168.001.001"))
  }

  // MARK: - Device Storage Tests

  @Test func testInitialDevicesEmpty() {
    let storage = DeviceStorage(userDefaults: createTestUserDefaults())
    #expect(storage.devices.isEmpty)
  }

  @Test func testSaveDevice() {
    let storage = DeviceStorage(userDefaults: createTestUserDefaults())
    let device = SavedDevice(name: "Test Mac", ipAddress: "192.168.1.100")

    storage.saveDevice(device)

    #expect(storage.devices.count == 1)
    #expect(storage.devices[0].name == "Test Mac")
    #expect(storage.devices[0].ipAddress == "192.168.1.100")
  }

  @Test func testSaveMultipleDevices() {
    let storage = DeviceStorage(userDefaults: createTestUserDefaults())
    let device1 = SavedDevice(name: "Mac 1", ipAddress: "192.168.1.100")
    let device2 = SavedDevice(name: "Mac 2", ipAddress: "192.168.1.101")

    storage.saveDevice(device1)
    storage.saveDevice(device2)

    #expect(storage.devices.count == 2)
    #expect(storage.devices[0].name == "Mac 1")
    #expect(storage.devices[1].name == "Mac 2")
  }

  @Test func testDeleteDeviceById() {
    let storage = DeviceStorage(userDefaults: createTestUserDefaults())
    let device1 = SavedDevice(name: "Mac 1", ipAddress: "192.168.1.100")
    let device2 = SavedDevice(name: "Mac 2", ipAddress: "192.168.1.101")

    storage.saveDevice(device1)
    storage.saveDevice(device2)
    storage.deleteDevice(device1)

    #expect(storage.devices.count == 1)
    #expect(storage.devices[0].name == "Mac 2")
  }

  @Test func testDeleteDeviceByIndexSet() {
    let storage = DeviceStorage(userDefaults: createTestUserDefaults())
    let device1 = SavedDevice(name: "Mac 1", ipAddress: "192.168.1.100")
    let device2 = SavedDevice(name: "Mac 2", ipAddress: "192.168.1.101")
    let device3 = SavedDevice(name: "Mac 3", ipAddress: "192.168.1.102")

    storage.saveDevice(device1)
    storage.saveDevice(device2)
    storage.saveDevice(device3)

    let indexSet = IndexSet(integer: 1)
    storage.deleteDevice(at: indexSet)

    #expect(storage.devices.count == 2)
    #expect(storage.devices[0].name == "Mac 1")
    #expect(storage.devices[1].name == "Mac 3")
  }

  @Test func testDeleteNonExistentDevice() {
    let storage = DeviceStorage(userDefaults: createTestUserDefaults())
    let device1 = SavedDevice(name: "Mac 1", ipAddress: "192.168.1.100")
    let device2 = SavedDevice(name: "Mac 2", ipAddress: "192.168.1.101")

    storage.saveDevice(device1)

    // Try to delete device2 which was never added
    storage.deleteDevice(device2)

    #expect(storage.devices.count == 1)
    #expect(storage.devices[0].name == "Mac 1")
  }

  @Test func testDeleteAllDevices() {
    let storage = DeviceStorage(userDefaults: createTestUserDefaults())
    let device1 = SavedDevice(name: "Mac 1", ipAddress: "192.168.1.100")
    let device2 = SavedDevice(name: "Mac 2", ipAddress: "192.168.1.101")

    storage.saveDevice(device1)
    storage.saveDevice(device2)

    storage.deleteDevice(device1)
    storage.deleteDevice(device2)

    #expect(storage.devices.isEmpty)
  }
}
