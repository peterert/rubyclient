import SwiftUI
import WebKit

struct HistoryEntry: Codable, Identifiable {
    var id = UUID()
    var title: String
    var url: String
    var date = Date()
}

final class BrowserStore: ObservableObject {
    @Published var tabs: [BrowserTab] = []
    @Published var selectedID: UUID?
    @Published var history: [HistoryEntry] = []
    @Published var blockTrackers: Bool {
        didSet {
            UserDefaults.standard.set(blockTrackers, forKey: "browser.blockTrackers")
            applyBlocker()
        }
    }

    private var ruleList: WKContentRuleList?
    private let historyKey = "browser.history"

    private static let trackerDomains = [
        "doubleclick.net", "googlesyndication.com", "google-analytics.com", "googletagmanager.com",
        "googleadservices.com", "facebook.net", "scorecardresearch.com", "adnxs.com", "taboola.com",
        "outbrain.com", "criteo.com", "hotjar.com", "mixpanel.com", "segment.io", "amplitude.com",
        "quantserve.com", "rubiconproject.com", "pubmatic.com", "openx.net", "moatads.com", "adsrvr.org",
    ]

    var current: BrowserTab? { tabs.first { $0.id == selectedID } }

    init() {
        blockTrackers = UserDefaults.standard.object(forKey: "browser.blockTrackers") as? Bool ?? true
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) {
            history = decoded
        }
        newTab()
        compileBlocker()
    }

    // MARK: Tabs

    @discardableResult
    func newTab(isPrivate: Bool = false, request: URLRequest? = nil) -> BrowserTab {
        let tab = BrowserTab(isPrivate: isPrivate, ruleList: blockTrackers ? ruleList : nil)
        tab.onVisit = { [weak self] url, title in self?.record(url: url, title: title) }
        tab.onNewTab = { [weak self] req in self?.newTab(isPrivate: isPrivate, request: req) }
        tabs.append(tab)
        selectedID = tab.id
        if let request { tab.load(request) }
        return tab
    }

    func close(_ tab: BrowserTab) {
        guard let index = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        tabs.remove(at: index)
        if tabs.isEmpty {
            newTab()
        } else if selectedID == tab.id {
            selectedID = tabs[min(index, tabs.count - 1)].id
        }
    }

    // MARK: History

    private func record(url: URL, title: String) {
        if history.first?.url == url.absoluteString { return }
        history.insert(HistoryEntry(title: title, url: url.absoluteString), at: 0)
        if history.count > 500 { history.removeLast(history.count - 500) }
        saveHistory()
    }

    func clearHistory() {
        history = []
        saveHistory()
    }

    func removeHistory(at offsets: IndexSet, in entries: [HistoryEntry]) {
        let ids = Set(offsets.map { entries[$0].id })
        history.removeAll { ids.contains($0.id) }
        saveHistory()
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    // MARK: Tracker blocker

    private func compileBlocker() {
        let rules: [[String: Any]] = Self.trackerDomains.map { domain in
            [
                "trigger": [
                    "url-filter": ".*" + domain.replacingOccurrences(of: ".", with: "\\."),
                    "load-type": ["third-party"],
                ],
                "action": ["type": "block"],
            ]
        }
        guard let data = try? JSONSerialization.data(withJSONObject: rules),
              let json = String(data: data, encoding: .utf8) else { return }
        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "RubyTrackerBlocker", encodedContentRuleList: json
        ) { [weak self] list, _ in
            DispatchQueue.main.async {
                self?.ruleList = list
                self?.applyBlocker()
            }
        }
    }

    private func applyBlocker() {
        guard let ruleList else { return }
        for tab in tabs {
            let controller = tab.webView.configuration.userContentController
            controller.remove(ruleList)
            if blockTrackers { controller.add(ruleList) }
        }
    }
}
