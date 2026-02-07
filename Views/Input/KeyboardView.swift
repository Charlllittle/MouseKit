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

  // Modifier key states
  @State private var ctrlPressed = false
  @State private var altPressed = false
  @State private var shiftPressed = false

  var body: some View {
    VStack(spacing: 16) {
      // Modifier keys section
      VStack(spacing: 12) {
        Text("Modifier Keys")
          .font(.headline)
          .foregroundColor(.secondary)

        HStack(spacing: 12) {
          ModifierKeyButton(title: "Ctrl", isPressed: $ctrlPressed) {
            viewModel.sendCommand(.specialKey(keyCode: 0x11))  // VK_CONTROL
          }

          ModifierKeyButton(title: "Alt", isPressed: $altPressed) {
            viewModel.sendCommand(.specialKey(keyCode: 0x12))  // VK_MENU
          }

          ModifierKeyButton(title: "Shift", isPressed: $shiftPressed) {
            viewModel.sendCommand(.specialKey(keyCode: 0x10))  // VK_SHIFT
          }
        }
      }
      .padding(.horizontal)
      .padding(.top, 20)

      // Special keys section
      VStack(spacing: 12) {
        Text("Special Keys")
          .font(.headline)
          .foregroundColor(.secondary)

        HStack(spacing: 12) {
          SpecialKeyButton(title: "Esc", keyCode: 0x1B, viewModel: viewModel)

          SpecialKeyButton(title: "Tab", keyCode: 0x09, viewModel: viewModel)

          SpecialKeyButton(title: "Win", keyCode: 0x5B, viewModel: viewModel)

          SpecialKeyButton(title: "Delete", keyCode: 0x2E, viewModel: viewModel)
        }
      }
      .padding(.horizontal)

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

    // Detect what changed
    if newValue.count > oldValue.count {
      // Character(s) added
      let startIndex = oldValue.count
      let newChars = newValue.suffix(
        from: newValue.index(newValue.startIndex, offsetBy: startIndex))

      for char in newChars {
        print("DEBUG: Sending character '\(char)'")
        sendCharacter(char)
      }
    } else if newValue.count < oldValue.count {
      // Character deleted (backspace)
      print("DEBUG: Sending backspace")
      sendBackspace()
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

// MARK: - Modifier Key Button

struct ModifierKeyButton: View {
  let title: String
  @Binding var isPressed: Bool
  let action: () -> Void

  var body: some View {
    Button {
      isPressed.toggle()
      action()
    } label: {
      Text(title)
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(isPressed ? .white : .primary)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(isPressed ? Color.blue : Color(uiColor: .secondarySystemBackground))
        .cornerRadius(10)
    }
  }
}

// MARK: - Special Key Button

struct SpecialKeyButton: View {
  let title: String
  let keyCode: UInt8
  let viewModel: InputViewModel

  var body: some View {
    Button {
      print(
        "DEBUG SpecialKeyButton: Sending \(title) with keyCode: 0x\(String(format: "%02X", keyCode))"
      )
      viewModel.sendCommand(.specialKey(keyCode: keyCode))
    } label: {
      Text(title)
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(.primary)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(8)
    }
  }
}

// MARK: - Custom Keyboard TextField

struct CustomKeyboardTextField: UIViewRepresentable {
  @Binding var text: String
  @Binding var isFocused: Bool
  var onTextChange: (String, String) -> Void
  var onReturn: () -> Void

  func makeUIView(context: Context) -> UITextField {
    let textField = UITextField()
    textField.delegate = context.coordinator
    textField.autocorrectionType = .no
    textField.autocapitalizationType = .none
    textField.returnKeyType = .default
    textField.enablesReturnKeyAutomatically = false

    // Make it invisible
    textField.textColor = .clear
    textField.tintColor = .clear
    textField.backgroundColor = .clear

    return textField
  }

  func updateUIView(_ uiView: UITextField, context: Context) {
    uiView.text = text

    // Handle focus changes
    if isFocused && !uiView.isFirstResponder {
      uiView.becomeFirstResponder()
    } else if !isFocused && uiView.isFirstResponder {
      uiView.resignFirstResponder()
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(text: $text, isFocused: $isFocused, onTextChange: onTextChange, onReturn: onReturn)
  }

  class Coordinator: NSObject, UITextFieldDelegate {
    @Binding var text: String
    @Binding var isFocused: Bool
    var onTextChange: (String, String) -> Void
    var onReturn: () -> Void

    private var previousText: String = ""

    init(
      text: Binding<String>, isFocused: Binding<Bool>,
      onTextChange: @escaping (String, String) -> Void, onReturn: @escaping () -> Void
    ) {
      self._text = text
      self._isFocused = isFocused
      self.onTextChange = onTextChange
      self.onReturn = onReturn
    }

    func textField(
      _ textField: UITextField, shouldChangeCharactersIn range: NSRange,
      replacementString string: String
    ) -> Bool {
      let currentText = textField.text ?? ""
      guard let stringRange = Range(range, in: currentText) else { return false }

      let oldValue = currentText
      let newValue = currentText.replacingCharacters(in: stringRange, with: string)

      print(
        "DEBUG TextField: oldValue='\(oldValue)', newValue='\(newValue)', replacement='\(string)', range=\(range)"
      )

      // Update binding
      text = newValue

      // Call change handler
      onTextChange(oldValue, newValue)

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
