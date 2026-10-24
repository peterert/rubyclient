import SwiftUI

@main
struct RubyClientApp: App {
    var body: some Scene {
        WindowGroup {
            HubView()
                .preferredColorScheme(.dark)
                .tint(Theme.bright)
        }
    }
}
