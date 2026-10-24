import SwiftUI
import WebKit

private struct SimpleWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let view = WKWebView(frame: .zero, configuration: config)
        view.allowsBackForwardNavigationGestures = true
        view.isOpaque = false
        view.backgroundColor = UIColor(Theme.bg)
        view.load(URLRequest(url: url))
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

/// Hosts a website as an app, like the Discord and Steam tiles on desktop.
struct WebAppView: View {
    let title: String
    let url: URL

    var body: some View {
        SimpleWebView(url: url)
            .background(Theme.bg)
    }
}
