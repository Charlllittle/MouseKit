//
//  InputCommand.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import Foundation

enum InputCommand {
  case leftClick
  case rightClick
  case mouseDown
  case mouseUp
  case mouseMove(dx: Int8, dy: Int8)
  case scroll(delta: Int8)
  case keyPress(char: UInt8)
  case scrollHorizontal(delta: Int8)
  case zoom(scale: UInt8)
  case specialKey(keyCode: UInt8)  // New command for virtual key codes

  var commandCode: UInt8 {
    switch self {
    case .leftClick:
      return 0x01
    case .rightClick:
      return 0x02
    case .mouseDown:
      return 0x03
    case .mouseUp:
      return 0x04
    case .mouseMove:
      return 0x05
    case .scroll:
      return 0x06
    case .keyPress:
      return 0x07
    case .scrollHorizontal:
      return 0x08
    case .zoom:
      return 0x09
    case .specialKey:
      return 0x0A  // New command code
    }
  }
}
