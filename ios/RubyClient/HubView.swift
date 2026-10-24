import SwiftUI

enum AppItem: String, CaseIterable, Identifiable, Hashable {
    case browser, discord, steam, weather, notes, tasks, calculator, converter, focus, password

    var id: String { rawValue }

    var title: String {
        switch self {
        case .browser: return "Ruby Browser"
        case .discord: return "Discord"
        case .steam: return "Steam"
        case .weather: return "Weather"
        case .notes: return "Notes"
        case .tasks: return "Tasks"
        case .calculator: return "Calculator"
        case .converter: return "Converter"
        case .focus: return "Focus Timer"
        case .password: return "Password Maker"
        }
    }

    var subtitle: String {
        switch self {
        case .browser: return "Tabs, private mode, tracker blocker"
        case .discord: return "Web app"
        case .steam: return "Web app"
        case .weather: return "Current conditions"
        case .notes: return "Quick notes"
        case .tasks: return "To-do list"
        case .calculator: return "Everyday maths"
        case .converter: return "Length, mass, temperature"
        case .focus: return "Pomodoro-style countdown"
        case .password: return "Strong random passwords"
        }
    }

    var symbol: String {
        switch self {
        case .browser: return "safari"
        case .discord: return "bubble.left.and.bubble.right.fill"
        case .steam: return "gamecontroller.fill"
        case .weather: return "cloud.sun.fill"
        case .notes: return "note.text"
        case .tasks: return "checklist"
        case .calculator: return "plusminus.circle.fill"
        case .converter: return "arrow.left.arrow.right"
        case .focus: return "timer"
        case .password: return "key.fill"
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .browser: BrowserView()
        case .discord: WebAppView(title: "Discord", url: URL(string: "https://discord.com/app")!)
        case .steam: WebAppView(title: "Steam", url: URL(string: "https://store.steampowered.com")!)
        case .weather: WeatherView()
        case .notes: NotesView()
        case .tasks: TasksView()
        case .calculator: CalculatorView()
        case .converter: ConverterView()
        case .focus: FocusTimerView()
        case .password: PasswordMakerView()
        }
    }
}

struct HubView: View {
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 14)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RUBYCLIENT")
                            .font(.system(size: 13, weight: .semibold))
                            .tracking(3)
                            .foregroundColor(Theme.gold)
                        Text("A hub of apps and a browser, in one place.")
                            .font(.title2.weight(.semibold))
                    }
                    .padding(.top, 8)

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(AppItem.allCases) { item in
                            NavigationLink(value: item) {
                                AppTile(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Founded by Peter Medvediev")
                        .font(.footnote)
                        .foregroundColor(Theme.dim)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                }
                .padding(18)
            }
            .rubyScreen()
            .navigationDestination(for: AppItem.self) { item in
                item.destination
                    .navigationTitle(item.title)
                    .navigationBarTitleDisplayMode(.inline)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

struct AppTile: View {
    let item: AppItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: item.symbol)
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 52, height: 52)
                .background(
                    LinearGradient(colors: [Theme.bright, Theme.ruby], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.gold.opacity(0.6), lineWidth: 1))
            Text(item.title).font(.headline)
            Text(item.subtitle)
                .font(.caption)
                .foregroundColor(Theme.dim)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .padding(14)
        .background(Theme.glass)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.line))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
