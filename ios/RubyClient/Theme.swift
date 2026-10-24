import SwiftUI

enum Theme {
    static let bg = Color(red: 0x10 / 255, green: 0x04 / 255, blue: 0x0a / 255)
    static let ruby = Color(red: 0xc4 / 255, green: 0x1e / 255, blue: 0x3a / 255)
    static let bright = Color(red: 1, green: 0x3d / 255, blue: 0x5e / 255)
    static let gold = Color(red: 0xd4 / 255, green: 0xaf / 255, blue: 0x37 / 255)
    static let text = Color(red: 1, green: 0xe9 / 255, blue: 0xee / 255)
    static let dim = Color(red: 0xb9 / 255, green: 0x9a / 255, blue: 0xa3 / 255)
    static let glass = Color(red: 40 / 255, green: 8 / 255, blue: 18 / 255).opacity(0.55)
    static let line = text.opacity(0.14)
}

extension View {
    /// Dark ruby background used by every screen.
    func rubyScreen() -> some View {
        self
            .foregroundColor(Theme.text)
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
    }
}

struct RubyButtonStyle: ButtonStyle {
    var filled = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 12)
            .padding(.horizontal, 22)
            .background(
                Group {
                    if filled {
                        LinearGradient(colors: [Theme.bright, Theme.ruby], startPoint: .top, endPoint: .bottom)
                    } else {
                        Theme.glass
                    }
                }
            )
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// Persists an array of Codable items in UserDefaults.
final class JSONStore<T: Codable>: ObservableObject {
    @Published var items: [T] {
        didSet { save() }
    }
    private let key: String

    init(key: String) {
        self.key = key
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([T].self, from: data) {
            items = decoded
        } else {
            items = []
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
