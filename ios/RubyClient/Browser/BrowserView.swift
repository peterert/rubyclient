import SwiftUI
import WebKit

struct WebContainer: UIViewRepresentable {
    let tab: BrowserTab
    func makeUIView(context: Context) -> WKWebView { tab.webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct BrowserView: View {
    @StateObject private var store = BrowserStore()

    var body: some View {
        Group {
            if let tab = store.current {
                TabScreen(tab: tab, store: store).id(tab.id)
            } else {
                Color.clear
            }
        }
        .rubyScreen()
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct TabScreen: View {
    @ObservedObject var tab: BrowserTab
    @ObservedObject var store: BrowserStore
    @State private var text = ""
    @State private var showTabs = false
    @State private var showHistory = false
    @FocusState private var focused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            addressBar
            ZStack {
                WebContainer(tab: tab)
                if tab.isBlank {
                    StartPage(isPrivate: tab.isPrivate) { tab.load($0) }
                }
            }
            bottomBar
        }
        .onAppear { text = tab.url?.absoluteString ?? "" }
        .onChange(of: tab.url) { new in
            if !focused { text = new?.absoluteString ?? "" }
        }
        .sheet(isPresented: $showTabs) { TabsSheet(store: store) }
        .sheet(isPresented: $showHistory) {
            HistorySheet(store: store) { url in
                tab.load(url)
                showHistory = false
            }
        }
    }

    private var addressBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left.circle.fill").font(.title3)
                }
                HStack(spacing: 6) {
                    Image(systemName: tab.isPrivate ? "eye.slash.fill" : "magnifyingglass")
                        .foregroundColor(tab.isPrivate ? Theme.gold : Theme.dim)
                    TextField("Search or enter address", text: $text)
                        .focused($focused)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.webSearch)
                        .submitLabel(.go)
                        .onSubmit { tab.load(text) }
                    if tab.isLoading {
                        Button { tab.webView.stopLoading() } label: { Image(systemName: "xmark") }
                    } else if !tab.isBlank {
                        Button { tab.webView.reload() } label: { Image(systemName: "arrow.clockwise") }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Theme.glass)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(tab.isPrivate ? Theme.gold.opacity(0.7) : Theme.line)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            ProgressView(value: tab.progress)
                .progressViewStyle(.linear)
                .tint(Theme.bright)
                .opacity(tab.isLoading ? 1 : 0)
        }
    }

    private var bottomBar: some View {
        HStack {
            Button { tab.webView.goBack() } label: { Image(systemName: "chevron.left") }
                .disabled(!tab.canGoBack)
            Spacer()
            Button { tab.webView.goForward() } label: { Image(systemName: "chevron.right") }
                .disabled(!tab.canGoForward)
            Spacer()
            Button { showTabs = true } label: {
                Text("\(store.tabs.count)")
                    .font(.footnote.bold())
                    .frame(width: 24, height: 24)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.text, lineWidth: 1.5))
            }
            Spacer()
            Button { showHistory = true } label: { Image(systemName: "clock") }
            Spacer()
            Menu {
                Button { store.newTab() } label: { Label("New Tab", systemImage: "plus") }
                Button { store.newTab(isPrivate: true) } label: { Label("New Private Tab", systemImage: "eye.slash") }
                Toggle(isOn: $store.blockTrackers) { Label("Block Trackers", systemImage: "shield.lefthalf.filled") }
                if let url = tab.url {
                    ShareLink(item: url) { Label("Share", systemImage: "square.and.arrow.up") }
                }
                if !tab.isBlank {
                    Button { tab.goHome(); text = "" } label: { Label("Start Page", systemImage: "house") }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .font(.title3)
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(Theme.glass)
        .overlay(alignment: .top) { Rectangle().fill(Theme.line).frame(height: 1) }
    }
}

private struct StartPage: View {
    let isPrivate: Bool
    let open: (String) -> Void

    private let links: [(String, String)] = [
        ("DuckDuckGo", "https://duckduckgo.com"),
        ("Wikipedia", "https://wikipedia.org"),
        ("Hacker News", "https://news.ycombinator.com"),
        ("GitHub", "https://github.com"),
        ("YouTube", "https://youtube.com"),
        ("Reddit", "https://reddit.com"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: isPrivate ? "eye.slash.fill" : "diamond.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(
                        LinearGradient(colors: [Theme.bright, Theme.ruby], startPoint: .top, endPoint: .bottom)
                    )
                    .padding(.top, 50)
                Text(isPrivate ? "Private tab" : "Ruby Browser")
                    .font(.title.weight(.semibold))
                Text(isPrivate
                     ? "Nothing from this tab is saved: no history, cookies or site data."
                     : "Type an address or a search above.")
                    .font(.subheadline)
                    .foregroundColor(Theme.dim)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 10) {
                    ForEach(links, id: \.0) { link in
                        Button(link.0) { open(link.1) }
                            .buttonStyle(RubyButtonStyle(filled: false))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
    }
}

private struct TabsSheet: View {
    @ObservedObject var store: BrowserStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.tabs) { tab in
                    Button {
                        store.selectedID = tab.id
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: tab.isPrivate ? "eye.slash.fill" : "globe")
                                .foregroundColor(tab.isPrivate ? Theme.gold : Theme.bright)
                            VStack(alignment: .leading) {
                                Text(tab.title).lineLimit(1)
                                Text(tab.url?.host ?? "Start page")
                                    .font(.caption).foregroundColor(Theme.dim)
                            }
                            Spacer()
                            if tab.id == store.selectedID { Image(systemName: "checkmark") }
                        }
                    }
                    .listRowBackground(Theme.glass)
                }
                .onDelete { offsets in
                    offsets.map { store.tabs[$0] }.forEach { store.close($0) }
                }
            }
            .rubyScreen()
            .navigationTitle("Tabs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button { store.newTab(isPrivate: true); dismiss() } label: { Image(systemName: "eye.slash") }
                    Button { store.newTab(); dismiss() } label: { Image(systemName: "plus") }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct HistorySheet: View {
    @ObservedObject var store: BrowserStore
    let open: (String) -> Void
    @State private var query = ""
    @Environment(\.dismiss) private var dismiss

    private var filtered: [HistoryEntry] {
        guard !query.isEmpty else { return store.history }
        return store.history.filter {
            $0.title.localizedCaseInsensitiveContains(query) || $0.url.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { entry in
                    Button { open(entry.url) } label: {
                        VStack(alignment: .leading) {
                            Text(entry.title).lineLimit(1)
                            Text(entry.url).font(.caption).foregroundColor(Theme.dim).lineLimit(1)
                        }
                    }
                    .listRowBackground(Theme.glass)
                }
                .onDelete { store.removeHistory(at: $0, in: filtered) }
            }
            .rubyScreen()
            .searchable(text: $query, prompt: "Search history")
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .destructiveAction) {
                    Button("Clear") { store.clearHistory() }.disabled(store.history.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
