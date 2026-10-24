import SwiftUI

struct Note: Identifiable, Codable {
    var id = UUID()
    var text: String
    var date = Date()
}

struct NotesView: View {
    @StateObject private var store = JSONStore<Note>(key: "notes")

    var body: some View {
        List {
            ForEach($store.items) { $note in
                NavigationLink {
                    TextEditor(text: $note.text)
                        .scrollContentBackground(.hidden)
                        .padding()
                        .rubyScreen()
                        .navigationTitle("Note")
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(note.text.isEmpty ? "Empty note" : note.text)
                            .lineLimit(2)
                        Text(note.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption).foregroundColor(Theme.dim)
                    }
                }
                .listRowBackground(Theme.glass)
            }
            .onDelete { store.items.remove(atOffsets: $0) }
        }
        .rubyScreen()
        .overlay {
            if store.items.isEmpty {
                Text("No notes yet. Tap + to add one.").foregroundColor(Theme.dim)
            }
        }
        .toolbar {
            Button { store.items.insert(Note(text: ""), at: 0) } label: { Image(systemName: "plus") }
        }
    }
}
