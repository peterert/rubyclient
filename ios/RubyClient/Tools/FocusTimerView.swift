import SwiftUI
import UIKit

struct FocusTimerView: View {
    @State private var minutes = 25
    @State private var remaining = 25 * 60
    @State private var endDate: Date?
    @State private var running = false
    private let ticker = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Text(String(format: "%02d:%02d", remaining / 60, remaining % 60))
                .font(.system(size: 78, weight: .thin, design: .rounded))
                .monospacedDigit()
            Picker("Length", selection: $minutes) {
                ForEach([15, 25, 45, 60], id: \.self) { Text("\($0) min").tag($0) }
            }
            .pickerStyle(.segmented)
            .disabled(running)
            .padding(.horizontal, 24)
            HStack(spacing: 16) {
                Button(running ? "Pause" : "Start") { toggle() }
                    .buttonStyle(RubyButtonStyle())
                Button("Reset") { reset() }
                    .buttonStyle(RubyButtonStyle(filled: false))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .rubyScreen()
        .onChange(of: minutes) { remaining = $0 * 60 }
        .onReceive(ticker) { _ in
            guard running, let end = endDate else { return }
            remaining = max(0, Int(ceil(end.timeIntervalSinceNow)))
            if remaining == 0 {
                running = false
                endDate = nil
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    private func toggle() {
        if running {
            running = false
            endDate = nil
        } else {
            if remaining == 0 { remaining = minutes * 60 }
            endDate = Date().addingTimeInterval(Double(remaining))
            running = true
        }
    }

    private func reset() {
        running = false
        endDate = nil
        remaining = minutes * 60
    }
}
