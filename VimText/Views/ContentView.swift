import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = NotesViewModel()

    var body: some View {
        NavigationSplitView {
            NoteListView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 360)
        } detail: {
            if let noteId = viewModel.selectedNoteId,
               viewModel.notes.contains(where: { $0.id == noteId }) {
                NoteEditorView(viewModel: viewModel, noteId: noteId)
                    .id(noteId)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 48, weight: .ultraLight))
                        .foregroundStyle(.tertiary)
                    Text("Select or create a note")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("⌘N to create a new note")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { viewModel.createNote() }) {
                    Image(systemName: "square.and.pencil")
                }
                .keyboardShortcut("n", modifiers: .command)
                .help("New Note (⌘N)")
            }
        }
        .navigationTitle("")
        .frame(minWidth: 700, minHeight: 500)
    }
}
