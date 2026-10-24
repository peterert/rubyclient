import Combine
import SwiftUI
import WebKit

final class BrowserTab: NSObject, ObservableObject, Identifiable, WKNavigationDelegate, WKUIDelegate {
    let id = UUID()
    let isPrivate: Bool
    let webView: WKWebView

    @Published var title = "New Tab"
    @Published var url: URL?
    @Published var progress = 0.0
    @Published var isLoading = false
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isBlank = true

    var onVisit: ((URL, String) -> Void)?
    var onNewTab: ((URLRequest) -> Void)?

    private var cancellables = Set<AnyCancellable>()

    init(isPrivate: Bool, ruleList: WKContentRuleList?) {
        self.isPrivate = isPrivate
        let config = WKWebViewConfiguration()
        config.websiteDataStore = isPrivate ? .nonPersistent() : .default()
        config.allowsInlineMediaPlayback = true
        if let ruleList { config.userContentController.add(ruleList) }
        webView = WKWebView(frame: .zero, configuration: config)
        super.init()
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.backgroundColor = UIColor(Theme.bg)
        webView.isOpaque = false

        webView.publisher(for: \.title).receive(on: DispatchQueue.main)
            .sink { [weak self] in
                if let t = $0, !t.isEmpty { self?.title = t }
            }.store(in: &cancellables)
        webView.publisher(for: \.url).receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.url = $0 }.store(in: &cancellables)
        webView.publisher(for: \.estimatedProgress).receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.progress = $0 }.store(in: &cancellables)
        webView.publisher(for: \.isLoading).receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isLoading = $0 }.store(in: &cancellables)
        webView.publisher(for: \.canGoBack).receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.canGoBack = $0 }.store(in: &cancellables)
        webView.publisher(for: \.canGoForward).receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.canGoForward = $0 }.store(in: &cancellables)
    }

    /// Turns what was typed into a URL, or a DuckDuckGo search.
    static func resolve(_ input: String) -> URL? {
        let t = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }
        if let u = URL(string: t), let s = u.scheme, ["http", "https"].contains(s) { return u }
        if !t.contains(" "), t.contains("."), let u = URL(string: "https://" + t) { return u }
        var c = URLComponents(string: "https://duckduckgo.com/")!
        c.queryItems = [URLQueryItem(name: "q", value: t)]
        return c.url
    }

    func load(_ input: String) {
        guard let u = Self.resolve(input) else { return }
        load(URLRequest(url: u))
    }

    func load(_ request: URLRequest) {
        isBlank = false
        webView.load(request)
    }

    func goHome() {
        isBlank = true
        title = "New Tab"
        url = nil
    }

    // MARK: WKNavigationDelegate

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isBlank = false
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard !isPrivate, let u = webView.url else { return }
        onVisit?(u, webView.title ?? u.host ?? u.absoluteString)
    }

    // MARK: WKUIDelegate

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Links that want a new window (target=_blank) open in a new tab instead.
        if navigationAction.targetFrame == nil { onNewTab?(navigationAction.request) }
        return nil
    }
}
