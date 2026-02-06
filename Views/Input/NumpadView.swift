import SwiftUI

struct NumpadView: View {
    @ObservedObject var viewModel: InputViewModel

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    let buttons: [[NumpadButton]] = [
        [.number("7"), .number("8"), .number("9"), .operator("/")],
        [.number("4"), .number("5"), .number("6"), .operator("*")],
        [.number("1"), .number("2"), .number("3"), .operator("-")],
        [.number("0"), .decimal, .operator("+"), .enter],
        [.backspace, .clear, .empty, .empty]
    ]

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            ForEach(0..<buttons.count, id: \.self) { row in
                HStack(spacing: 16) {
                    ForEach(0..<buttons[row].count, id: \.self) { col in
                        let button = buttons[row][col]

                        if button != .empty {
                            Button {
                                handleButtonPress(button)
                            } label: {
                                Text(button.displayText)
                                    .font(.title)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(button.backgroundColor)
                                    .cornerRadius(12)
                            }
                            .frame(height: 80)
                        } else {
                            Color.clear
                                .frame(height: 80)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
    }

    private func handleButtonPress(_ button: NumpadButton) {
        let ascii: UInt8

        switch button {
        case .number(let num):
            ascii = UInt8(num.first!.asciiValue!)
        case .operator(let op):
            ascii = UInt8(op.first!.asciiValue!)
        case .decimal:
            ascii = UInt8(Character(".").asciiValue!)
        case .enter:
            ascii = 0x0A // Newline
        case .backspace:
            ascii = 0x08 // Backspace
        case .clear:
            ascii = 0x1B // Escape
        case .empty:
            return
        }

        viewModel.sendCommand(.keyPress(char: ascii))
    }
}

enum NumpadButton: Equatable {
    case number(String)
    case `operator`(String)
    case decimal
    case enter
    case backspace
    case clear
    case empty

    var displayText: String {
        switch self {
        case .number(let num):
            return num
        case .operator(let op):
            return op
        case .decimal:
            return "."
        case .enter:
            return "↵"
        case .backspace:
            return "←"
        case .clear:
            return "C"
        case .empty:
            return ""
        }
    }

    var backgroundColor: Color {
        switch self {
        case .number, .decimal:
            return .blue
        case .operator:
            return .orange
        case .enter:
            return .green
        case .backspace, .clear:
            return .red
        case .empty:
            return .clear
        }
    }
}
