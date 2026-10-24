import SwiftUI

struct TodoItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var done = false
}

struct TasksView: View {
    @StateObject private var store = JSONStore<TodoItem>(key: "tasks")
    @State private var newTitle = ""

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("New task", text: $newTitle)
                        .submitLabel(.done)
                        .onSubmit(add)
                    Button("Add", action: add).disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .listRowBackground(Theme.glass)
            }
            Section {
                ForEach($store.items) { $item in
                    Button { item.done.toggle() } label: {
                        HStack {
                            Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(item.done ? Theme.gold : Theme.dim)
                            Text(item.title)
                                .strikethrough(item.done)
                                .foregroundColor(item.done ? Theme.dim : Theme.text)
                        }
                    }
                    .listRowBackground(Theme.glass)
                }
                .onDelete { store.items.remove(atOffsets: $0) }
            }
        }
        .rubyScreen()
        .toolbar {
            Button("Clear done") { store.items.removeAll { $0.done } }
                .disabled(!store.items.contains { $0.done })
        }
    }

    private func add() {
        let t = newTitle.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        store.items.insert(TodoItem(title: t), at: 0)
        newTitle = ""
    }
}
