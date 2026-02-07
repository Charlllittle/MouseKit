//
//  DeviceInfo.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import UIKit

enum DeviceInfo {
    static var manufacturer: String {
        "Apple"
    }

    @MainActor
    static var deviceName: String {
        UIDevice.current.name
    }

    @MainActor
    static var model: String {
        UIDevice.current.model
    }

    static var connectionType: Int {
        1 // WiFi only
    }

    @MainActor
    static func handshakeString() -> String {
        "\(manufacturer)/\(deviceName)/\(model)/\(connectionType)"
    }
}
