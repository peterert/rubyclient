import SwiftUI
import UIKit

struct PasswordMakerView: View {
    @State private var length = 16.0
    @State private var upper = true
    @State private var digits = true
    @State private var symbols = true
    @State private var password = ""
    @State private var copied = false

    var body: some View {
        Form {
            Section {
                Text(password)
                    .font(.system(.title3, design: .monospaced))
                    .foregroundColor(Theme.gold)
                    .textSelection(.enabled)
                HStack {
                    Button("Generate", action: generate).buttonStyle(RubyButtonStyle())
                    Button(copied ? "Copied" : "Copy") {
                        UIPasteboard.general.string = password
                        copied = true
                    }
                    .buttonStyle(RubyButtonStyle(filled: false))
                }
                .buttonStyle(.borderless)
            }
            .listRowBackground(Theme.glass)
            Section("Options") {
                VStack(alignment: .leading) {
                    Text("Length: \(Int(length))")
                    Slider(value: $length, in: 8...64, step: 1)
                }
                Toggle("Capital letters", isOn: $upper)
                Toggle("Numbers", isOn: $digits)
                Toggle("Symbols", isOn: $symbols)
            }
            .listRowBackground(Theme.glass)
        }
        .rubyScreen()
        .onAppear(perform: generate)
        .onChange(of: length) { _ in generate() }
        .onChange(of: upper) { _ in generate() }
        .onChange(of: digits) { _ in generate() }
        .onChange(of: symbols) { _ in generate() }
    }

    private func generate() {
        var pool = Array("abcdefghijklmnopqrstuvwxyz")
        if upper { pool += Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ") }
        if digits { pool += Array("0123456789") }
        if symbols { pool += Array("!@#$%^&*()-_=+[]{};:,.?") }
        // randomElement() uses the system's secure random generator.
        password = String((0..<Int(length)).map { _ in pool.randomElement()! })
        copied = false
    }
}
