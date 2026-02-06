//
//  InputCommandTests.swift
//  MouseKitTests
//
//  Created by Charles Little on 06/02/2026.
//

import Testing
import Foundation
@testable import MouseKit

struct InputCommandTests {

    // MARK: - Command Code Tests

    @Test func testLeftClickCommandCode() {
        let command = InputCommand.leftClick
        #expect(command.commandCode == 0x01)
    }

    @Test func testRightClickCommandCode() {
        let command = InputCommand.rightClick
        #expect(command.commandCode == 0x02)
    }

    @Test func testMouseDownCommandCode() {
        let command = InputCommand.mouseDown
        #expect(command.commandCode == 0x03)
    }

    @Test func testMouseUpCommandCode() {
        let command = InputCommand.mouseUp
        #expect(command.commandCode == 0x04)
    }

    @Test func testMouseMoveCommandCode() {
        let command = InputCommand.mouseMove(dx: 0, dy: 0)
        #expect(command.commandCode == 0x05)
    }

    @Test func testScrollCommandCode() {
        let command = InputCommand.scroll(delta: 0)
        #expect(command.commandCode == 0x06)
    }

    @Test func testKeyPressCommandCode() {
        let command = InputCommand.keyPress(char: 0)
        #expect(command.commandCode == 0x07)
    }

    @Test func testScrollHorizontalCommandCode() {
        let command = InputCommand.scrollHorizontal(delta: 0)
        #expect(command.commandCode == 0x08)
    }

    @Test func testZoomCommandCode() {
        let command = InputCommand.zoom(scale: 0)
        #expect(command.commandCode == 0x09)
    }

    @Test func testSpecialKeyCommandCode() {
        let command = InputCommand.specialKey(keyCode: 0)
        #expect(command.commandCode == 0x0A)
    }

    // MARK: - Command Equality Tests

    @Test func testMouseMoveWithDifferentValues() {
        let command1 = InputCommand.mouseMove(dx: 10, dy: 20)
        let command2 = InputCommand.mouseMove(dx: -5, dy: 15)

        // Both should have the same command code
        #expect(command1.commandCode == command2.commandCode)
    }

    @Test func testScrollWithDifferentValues() {
        let command1 = InputCommand.scroll(delta: 5)
        let command2 = InputCommand.scroll(delta: -3)

        #expect(command1.commandCode == command2.commandCode)
    }

    @Test func testKeyPressWithDifferentCharacters() {
        let commandA = InputCommand.keyPress(char: 65) // 'A'
        let commandZ = InputCommand.keyPress(char: 90) // 'Z'

        #expect(commandA.commandCode == commandZ.commandCode)
    }

    // MARK: - Command Code Uniqueness Tests

    @Test func testAllCommandCodesAreUnique() {
        let commands: [InputCommand] = [
            .leftClick,
            .rightClick,
            .mouseDown,
            .mouseUp,
            .mouseMove(dx: 0, dy: 0),
            .scroll(delta: 0),
            .keyPress(char: 0),
            .scrollHorizontal(delta: 0),
            .zoom(scale: 0),
            .specialKey(keyCode: 0)
        ]

        let commandCodes = commands.map { $0.commandCode }
        let uniqueCodes = Set(commandCodes)

        #expect(commandCodes.count == uniqueCodes.count)
    }

    @Test func testCommandCodesAreInExpectedRange() {
        let commands: [InputCommand] = [
            .leftClick,
            .rightClick,
            .mouseDown,
            .mouseUp,
            .mouseMove(dx: 0, dy: 0),
            .scroll(delta: 0),
            .keyPress(char: 0),
            .scrollHorizontal(delta: 0),
            .zoom(scale: 0),
            .specialKey(keyCode: 0)
        ]

        for command in commands {
            // All command codes should be in the range 0x01 to 0x0A
            #expect(command.commandCode >= 0x01)
            #expect(command.commandCode <= 0x0A)
        }
    }

    // MARK: - Edge Case Tests

    @Test func testMouseMoveWithMaximumValues() {
        let command = InputCommand.mouseMove(dx: 127, dy: 127)
        #expect(command.commandCode == 0x05)
    }

    @Test func testMouseMoveWithMinimumValues() {
        let command = InputCommand.mouseMove(dx: -128, dy: -128)
        #expect(command.commandCode == 0x05)
    }

    @Test func testScrollWithZeroDelta() {
        let command = InputCommand.scroll(delta: 0)
        #expect(command.commandCode == 0x06)
    }

    @Test func testZoomWithMaxScale() {
        let command = InputCommand.zoom(scale: 255)
        #expect(command.commandCode == 0x09)
    }

    @Test func testZoomWithMinScale() {
        let command = InputCommand.zoom(scale: 0)
        #expect(command.commandCode == 0x09)
    }

    @Test func testSpecialKeyWithVariousKeyCodes() {
        let backspace = InputCommand.specialKey(keyCode: 0x2A)
        let delete = InputCommand.specialKey(keyCode: 0x2E)
        let enter = InputCommand.specialKey(keyCode: 0x28)

        #expect(backspace.commandCode == 0x0A)
        #expect(delete.commandCode == 0x0A)
        #expect(enter.commandCode == 0x0A)
    }
}
