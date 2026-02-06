//
//  ProtocolEncoderTests.swift
//  MouseKitTests
//
//  Created by Charles Little on 06/02/2026.
//

import Foundation
import Testing

@testable import MouseKit

struct ProtocolEncoderTests {

    // MARK: - Command Encoding Tests

    @Test func testLeftClickEncoding() {
        let command = InputCommand.leftClick
        let data = ProtocolEncoder.encode(command)

        #expect(data.count == 1)
        #expect(data[0] == 0x01)
    }

    @Test func testRightClickEncoding() {
        let command = InputCommand.rightClick
        let data = ProtocolEncoder.encode(command)

        #expect(data.count == 1)
        #expect(data[0] == 0x02)
    }

    @Test func testMouseDownEncoding() {
        let command = InputCommand.mouseDown
        let data = ProtocolEncoder.encode(command)

        #expect(data.count == 1)
        #expect(data[0] == 0x03)
    }

    @Test func testMouseUpEncoding() {
        let command = InputCommand.mouseUp
        let data = ProtocolEncoder.encode(command)

        #expect(data.count == 1)
        #expect(data[0] == 0x04)
    }

    @Test func testMouseMoveEncoding() {
        let command = InputCommand.mouseMove(dx: 10, dy: -5)
        let data = ProtocolEncoder.encode(command)

        #expect(data.count == 3)
        #expect(data[0] == 0x05)  // Command code
        #expect(data[1] == UInt8(bitPattern: 10))  // dx
        #expect(data[2] == UInt8(bitPattern: -5))  // dy
    }

    @Test func testMouseMoveWithExtremeValues() {
        let command = InputCommand.mouseMove(dx: 127, dy: -128)
        let data = ProtocolEncoder.encode(command)

        #expect(data.count == 3)
        #expect(data[0] == 0x05)
        #expect(data[1] == UInt8(bitPattern: 127))
        #expect(data[2] == UInt8(bitPattern: -128))
    }

    @Test func testScrollEncoding() {
        let command = InputCommand.scroll(delta: 5)
        let data = ProtocolEncoder.encode(command)

        #expect(data.count == 2)
        #expect(data[0] == 0x06)
        #expect(data[1] == UInt8(bitPattern: 5))
    }

    @Test func testScrollHorizontalEncoding() {
        let command = InputCommand.scrollHorizontal(delta: -3)
        let data = ProtocolEncoder.encode(command)

        #expect(data.count == 2)
        #expect(data[0] == 0x08)
        #expect(data[1] == UInt8(bitPattern: -3))
    }

    @Test func testKeyPressEncoding() {
        let command = InputCommand.keyPress(char: 65)  // 'A'
        let data = ProtocolEncoder.encode(command)

        #expect(data.count == 2)
        #expect(data[0] == 0x07)
        #expect(data[1] == 65)
    }

    @Test func testZoomEncoding() {
        let command = InputCommand.zoom(scale: 150)
        let data = ProtocolEncoder.encode(command)

        #expect(data.count == 2)
        #expect(data[0] == 0x09)
        #expect(data[1] == 150)
    }

    @Test func testSpecialKeyEncoding() {
        let command = InputCommand.specialKey(keyCode: 0x2E)  // Delete key
        let data = ProtocolEncoder.encode(command)

        #expect(data.count == 2)
        #expect(data[0] == 0x0A)
        #expect(data[1] == 0x2E)
    }

    // MARK: - Delta Conversion Tests

    @Test func testDeltaToInt8WithinRange() {
        let result = ProtocolEncoder.deltaToInt8(50.0)
        #expect(result == 50)
    }

    @Test func testDeltaToInt8NegativeValue() {
        let result = ProtocolEncoder.deltaToInt8(-75.5)
        #expect(result == -75)
    }

    @Test func testDeltaToInt8MaxClamp() {
        let result = ProtocolEncoder.deltaToInt8(200.0)
        #expect(result == 127)
    }

    @Test func testDeltaToInt8MinClamp() {
        let result = ProtocolEncoder.deltaToInt8(-200.0)
        #expect(result == -128)
    }

    @Test func testDeltaToInt8Zero() {
        let result = ProtocolEncoder.deltaToInt8(0.0)
        #expect(result == 0)
    }

    @Test func testDeltaToInt8SmallPositive() {
        let result = ProtocolEncoder.deltaToInt8(0.7)
        #expect(result == 0)
    }

    @Test func testDeltaToInt8SmallNegative() {
        let result = ProtocolEncoder.deltaToInt8(-0.3)
        #expect(result == 0)
    }

    // MARK: - Scale Conversion Tests

    @Test func testScaleToUInt8Normal() {
        let result = ProtocolEncoder.scaleToUInt8(1.0)
        #expect(result == 100)
    }

    @Test func testScaleToUInt8Zero() {
        let result = ProtocolEncoder.scaleToUInt8(0.0)
        #expect(result == 0)
    }

    @Test func testScaleToUInt8Max() {
        let result = ProtocolEncoder.scaleToUInt8(2.55)
        #expect(result == 254)
    }

    @Test func testScaleToUInt8OverMax() {
        let result = ProtocolEncoder.scaleToUInt8(10.0)
        #expect(result == 255)
    }

    @Test func testScaleToUInt8Negative() {
        let result = ProtocolEncoder.scaleToUInt8(-1.0)
        #expect(result == 0)
    }

    @Test func testScaleToUInt8Half() {
        let result = ProtocolEncoder.scaleToUInt8(0.5)
        #expect(result == 50)
    }
}
