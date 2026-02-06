# MouseKit - A native IOS client for Mousedroid

Native iOS client for Mousedroid, providing touchpad, keyboard, and numpad input for your computer over WiFi.

## Features

- **Touchpad Mode**: Full gesture support including:
  - Single tap → Left click
  - Double tap → Double-click
  - Two-finger tap → Right click
  - Drag → Mouse movement
  - Two-finger drag → Scroll (vertical/horizontal)
  - Long press + drag → Drag & drop
  - Pinch → Zoom

- **Keyboard Mode**: Full keyboard input support
  - Type text directly from iOS keyboard
  - Special characters supported
  - Backspace and Enter keys

- **Numpad Mode**: Numeric keypad for calculator/spreadsheet use
  - Numbers 0-9
  - Operators (+, -, *, /)
  - Enter, Backspace, Decimal

## Requirements

- iOS 17.0 or later
- iPhone or iPad
- WiFi connection to the same network as your Mousedroid server

## Setup

1. Open the project in Xcode 14 or later
2. Select your development team in project settings
3. Build and run on your iOS device or simulator

## Usage

1. Start the Mousedroid server on your computer
2. Launch the iOS app
3. Add a device with your server's IP address
4. Connect to the device
5. Choose your input mode (Touchpad/Keyboard/Numpad)
6. Start controlling your computer!

## Architecture

- **MVVM Pattern**: ViewModels manage business logic, Views handle UI
- **Swift Concurrency**: Async/await for networking operations
- **Network Framework**: Native TCP connections using NWConnection
- **SwiftUI**: Modern declarative UI

## Project Structure

```
MouseKit/
├── App/                    # App entry point
├── Models/                 # Data models
├── ViewModels/             # Business logic
├── Views/                  # SwiftUI views
│   ├── Main/              # Device management
│   └── Input/             # Input modes
├── Services/              # Core services
│   ├── Networking/        # TCP connection
│   ├── Input/             # Gesture processing
│   └── Storage/           # Device persistence
└── Utilities/             # Helpers and constants
```

## Protocol

The MouseKit client uses the same binary protocol as the Android client:

- Handshake: `"Apple/[DeviceName]/[Model]/1"`
- Command codes: 0x01-0x09 for various input types
- Binary encoding for mouse movement, scrolling, and keyboard input

## License

Same as Mousedroid project
