import UIKit

enum DeviceInfo {
    static var manufacturer: String {
        "Apple"
    }

    static var deviceName: String {
        UIDevice.current.name
    }

    static var model: String {
        UIDevice.current.model
    }

    static var connectionType: Int {
        1 // WiFi only
    }

    static func handshakeString() -> String {
        "\(manufacturer)/\(deviceName)/\(model)/\(connectionType)"
    }
}
