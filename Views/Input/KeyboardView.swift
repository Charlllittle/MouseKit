//
//  KeyboardView.swift
//  MouseKit
//
//  Created by Charles Little on 06/02/2026.
//

import SwiftUI

struct KeyboardView: View {
    @ObservedObject var viewModel: InputViewModel
    @State private var text = ""
    @State private var previousText = ""
    @State private var isFocused: Bool = false


    var body: some View {
        VStack(spacing: 16) {
            // Note: Modifier keys and special function keys are not supported by the current server protocol.
            // The server only handles ASCII characters via the KEYPRESS command (0x07).
            // To add support for these keys, the server would need to implement the specialKey command (0x0A).

            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "keyboard")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)

                Text("Tap to activate keyboard")
                    .font(.headline)

                Text("Type to send input to your computer")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()

            // Custom text field that never dismisses keyboard except when explicitly toggled
            CustomKeyboardTextField(
                text: $text,
                isFocused: $isFocused,
                onTextChange: { oldValue, newValue in
                    handleTextChange(oldValue: oldValue, newValue: newValue)
                },
                onBackspace: {
                    // Always send backspace to remote, even if local field is empty
                    sendBackspace()
                },
                onReturn: {
                    // Send Enter key (newline character) without dismissing keyboard
                    viewModel.sendCommand(.keyPress(char: 0x0A))
                }
            )
            .frame(height: 0)
            .opacity(0)

            Button {
                isFocused = !isFocused
            } label: {
                Text(isFocused ? "Keyboard Active" : "Activate Keyboard")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFocused ? Color.green : Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = !isFocused
        }
    }

    private func handleTextChange(oldValue: String, newValue: String) {
        print("DEBUG handleTextChange: oldValue='\(oldValue)', newValue='\(newValue)'")

        // Only handle character additions here; backspace is handled separately
        if newValue.count > oldValue.count {
            // Character(s) added
            let startIndex = oldValue.count
            let newChars = newValue.suffix(from: newValue.index(newValue.startIndex, offsetBy: startIndex))

            for char in newChars {
                print("DEBUG: Sending character '\(char)'")
                sendCharacter(char)
            }
        }

        previousText = newValue
    }

    private func sendCharacter(_ char: Character) {
        // Convert character to ASCII
        if let ascii = char.asciiValue {
            viewModel.sendCommand(.keyPress(char: ascii))
        }
        // Note: \n is already handled above since it has ascii value 0x0A
    }

    private func sendBackspace() {
        // Server expects DEL character (127) for backspace, not BS (0x08)
        viewModel.sendCommand(.keyPress(char: 127))
    }
}

// MARK: - Custom Keyboard TextField

struct CustomKeyboardTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    var onTextChange: (String, String) -> Void
    var onBackspace: () -> Void
    var onReturn: () -> Void

    func makeUIView(context: Context) -> BackspaceDetectingTextField {
        let textField = BackspaceDetectingTextField()
        textField.delegate = context.coordinator
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.returnKeyType = .default
        textField.enablesReturnKeyAutomatically = false

        // Set the backspace handler
        textField.onBackspace = context.coordinator.handleBackspace

        // Make it invisible
        textField.textColor = .clear
        textField.tintColor = .clear
        textField.backgroundColor = .clear

        return textField
    }

    func updateUIView(_ uiView: BackspaceDetectingTextField, context: Context) {
        uiView.text = text

        // Update the backspace handler in case it changed
        uiView.onBackspace = context.coordinator.handleBackspace

        // Handle focus changes
        if isFocused && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFocused && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFocused: $isFocused, onTextChange: onTextChange, onBackspace: onBackspace, onReturn: onReturn)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        @Binding var isFocused: Bool
        var onTextChange: (String, String) -> Void
        var onBackspace: () -> Void
        var onReturn: () -> Void

        private var previousText: String = ""

        init(text: Binding<String>, isFocused: Binding<Bool>, onTextChange: @escaping (String, String) -> Void, onBackspace: @escaping () -> Void, onReturn: @escaping () -> Void) {
            self._text = text
            self._isFocused = isFocused
            self.onTextChange = onTextChange
            self.onBackspace = onBackspace
            self.onReturn = onReturn
        }

        func handleBackspace() {
            // Always call the backspace handler, regardless of text field state
            onBackspace()
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let currentText = textField.text ?? ""
            guard let stringRange = Range(range, in: currentText) else { return false }

            let oldValue = currentText
            let newValue = currentText.replacingCharacters(in: stringRange, with: string)

            print("DEBUG TextField: oldValue='\(oldValue)', newValue='\(newValue)', replacement='\(string)', range=\(range)")

            // Update binding
            text = newValue

            // Call change handler for text that was added
            // (backspace is handled by BackspaceDetectingTextField.deleteBackward)
            if !string.isEmpty {
                onTextChange(oldValue, newValue)
            }

            return true
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            // Call return handler instead of dismissing keyboard
            onReturn()

            // Clear the text field but keep keyboard open
            text = ""
            textField.text = ""

            // Prevent keyboard from dismissing
            return false
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            isFocused = true
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            // Only update if we explicitly want to unfocus
            // This prevents accidental dismissals
        }
    }
}

// MARK: - Backspace Detecting TextField

/// Custom UITextField that detects backspace even when the field is empty
class BackspaceDetectingTextField: UITextField {
    var onBackspace: (() -> Void)?

    override func deleteBackward() {
        // Call our custom handler first
        onBackspace?()

        // Then perform the default deletion
        super.deleteBackward()
    }
}
