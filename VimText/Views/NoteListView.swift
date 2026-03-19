import SwiftUI

struct NoteListView: View {
    @ObservedObject var viewModel: NotesViewModel
    @State private var selectedNoteIds: Set<UUID> = []
    @State private var isSelectionMode = false
    @State private var showDeleteAllConfirm = false
    @State private var showDeleteSelectedConfirm = false
    @State private var searchFocusTrigger = false
    @State private var highlightedIndex: Int? = nil

    private var allSelected: Bool {
        !viewModel.filteredNotes.isEmpty && selectedNoteIds.count == viewModel.filteredNotes.count
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
                SearchField(
                    text: $viewModel.searchText,
                    focusTrigger: $searchFocusTrigger,
                    onArrowDown: { moveHighlight(down: true) },
                    onArrowUp: { moveHighlight(down: false) },
                    onEnter: { selectHighlighted() },
                    onEscape: { dismissSearch() }
                )
                .frame(height: 22)
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.searchText = ""
                        highlightedIndex = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)

            Divider()

            if isSelectionMode {
                HStack(spacing: 8) {
                    Button(allSelected ? "Deselect All" : "Select All") {
                        if allSelected {
                            selectedNoteIds.removeAll()
                        } else {
                            selectedNoteIds = Set(viewModel.filteredNotes.map { $0.id })
                        }
                    }
                    .font(.caption)

                    Spacer()

                    Text("\(selectedNoteIds.count) selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Done") {
                        isSelectionMode = false
                        selectedNoteIds.removeAll()
                    }
                    .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))

                Divider()
            }

            if viewModel.filteredNotes.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: viewModel.searchText.isEmpty ? "note.text" : "magnifyingglass")
                        .font(.system(size: 32, weight: .ultraLight))
                        .foregroundStyle(.tertiary)
                    Text(viewModel.searchText.isEmpty ? "No Notes" : "No Results")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    if viewModel.searchText.isEmpty {
                        Text("Create a note to get started")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if isSelectionMode {
                List {
                    let pinned = viewModel.filteredNotes.filter { $0.isPinned }
                    let unpinned = viewModel.filteredNotes.filter { !$0.isPinned }

                    if !pinned.isEmpty {
                        Section("Pinned") {
                            ForEach(pinned) { note in
                                selectableNoteRow(note: note)
                            }
                        }
                    }

                    if !unpinned.isEmpty {
                        Section(pinned.isEmpty ? "" : "Notes") {
                            ForEach(unpinned) { note in
                                selectableNoteRow(note: note)
                            }
                        }
                    }
                }
                .listStyle(.inset)
            } else {
                notesList
            }

            Divider()

            HStack {
                Text("\(viewModel.filteredNotes.count) notes")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()

                if isSelectionMode && !selectedNoteIds.isEmpty {
                    Button(role: .destructive) {
                        showDeleteSelectedConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Delete selected notes")
                }

                Menu {
                    if !isSelectionMode {
                        Button("Select Notes…") {
                            isSelectionMode = true
                            selectedNoteIds.removeAll()
                        }
                    }

                    Divider()

                    Button("Delete All Notes…", role: .destructive) {
                        showDeleteAllConfirm = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 20)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .confirmationDialog(
            "Delete All Notes?",
            isPresented: $showDeleteAllConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) {
                viewModel.deleteAllNotes()
                isSelectionMode = false
                selectedNoteIds.removeAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all \(viewModel.notes.count) notes. This action cannot be undone.")
        }
        .confirmationDialog(
            "Delete \(selectedNoteIds.count) Notes?",
            isPresented: $showDeleteSelectedConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete \(selectedNoteIds.count) Notes", role: .destructive) {
                viewModel.deleteNotes(ids: selectedNoteIds)
                selectedNoteIds.removeAll()
                isSelectionMode = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(selectedNoteIds.count) selected notes. This action cannot be undone.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusNoteSearch)) { _ in
            searchFocusTrigger.toggle()
        }
        .onChange(of: viewModel.searchText) {
            if viewModel.searchText.isEmpty {
                highlightedIndex = nil
            } else {
                highlightedIndex = viewModel.filteredNotes.isEmpty ? nil : 0
            }
        }
    }

    @ViewBuilder
    private var notesList: some View {
        let notes = viewModel.filteredNotes
        let isSearching = !viewModel.searchText.isEmpty

        ScrollViewReader { proxy in
            List(selection: isSearching ? nil : $viewModel.selectedNoteId) {
                let pinned = notes.filter { $0.isPinned }
                let unpinned = notes.filter { !$0.isPinned }

                if !pinned.isEmpty {
                    Section("Pinned") {
                        ForEach(Array(pinned.enumerated()), id: \.element.id) { idx, note in
                            let flatIdx = idx
                            noteRow(note: note, flatIndex: flatIdx, isSearching: isSearching)
                        }
                    }
                }

                if !unpinned.isEmpty {
                    Section(pinned.isEmpty ? "" : "Notes") {
                        ForEach(Array(unpinned.enumerated()), id: \.element.id) { idx, note in
                            let flatIdx = pinned.count + idx
                            noteRow(note: note, flatIndex: flatIdx, isSearching: isSearching)
                        }
                    }
                }
            }
            .listStyle(.inset)
            .onChange(of: highlightedIndex) {
                if let idx = highlightedIndex, idx < notes.count {
                    proxy.scrollTo(notes[idx].id, anchor: .center)
                }
            }
        }
    }

    @ViewBuilder
    private func noteRow(note: Note, flatIndex: Int, isSearching: Bool) -> some View {
        let isHighlighted = isSearching && highlightedIndex == flatIndex

        NoteRowView(note: note)
            .id(note.id)
            .tag(note.id)
            .listRowBackground(
                isHighlighted
                    ? Color.accentColor.opacity(0.2)
                    : (viewModel.selectedNoteId == note.id ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.selectedNoteId = note.id
                highlightedIndex = nil
                viewModel.searchText = ""
            }
            .contextMenu {
                noteContextMenu(for: note)
            }
    }

    private func moveHighlight(down: Bool) {
        let count = viewModel.filteredNotes.count
        guard count > 0 else { return }

        if let current = highlightedIndex {
            if down {
                highlightedIndex = min(current + 1, count - 1)
            } else {
                highlightedIndex = max(current - 1, 0)
            }
        } else {
            highlightedIndex = down ? 0 : count - 1
        }
    }

    private func selectHighlighted() {
        let notes = viewModel.filteredNotes
        guard !notes.isEmpty else { return }

        if let idx = highlightedIndex, idx < notes.count {
            viewModel.selectedNoteId = notes[idx].id
        } else if let first = notes.first {
            viewModel.selectedNoteId = first.id
        }

        highlightedIndex = nil
        viewModel.searchText = ""
    }

    private func dismissSearch() {
        highlightedIndex = nil
        viewModel.searchText = ""
    }

    @ViewBuilder
    private func selectableNoteRow(note: Note) -> some View {
        HStack(spacing: 10) {
            Image(systemName: selectedNoteIds.contains(note.id) ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(selectedNoteIds.contains(note.id) ? Color.blue : Color.gray.opacity(0.4))
                .font(.title3)

            NoteRowView(note: note)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if selectedNoteIds.contains(note.id) {
                selectedNoteIds.remove(note.id)
            } else {
                selectedNoteIds.insert(note.id)
            }
        }
    }

    @ViewBuilder
    private func noteContextMenu(for note: Note) -> some View {
        Button(note.isPinned ? "Unpin" : "Pin") {
            viewModel.togglePin(note)
        }

        Divider()

        Button("Delete", role: .destructive) {
            viewModel.deleteNote(note)
        }
    }
}

struct SearchField: NSViewRepresentable {
    @Binding var text: String
    @Binding var focusTrigger: Bool
    var onArrowDown: () -> Void
    var onArrowUp: () -> Void
    var onEnter: () -> Void
    var onEscape: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.placeholderString = "Search"
        field.isBordered = false
        field.drawsBackground = false
        field.font = .systemFont(ofSize: NSFont.systemFontSize)
        field.focusRingType = .none
        field.delegate = context.coordinator
        context.coordinator.textField = field
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        if focusTrigger != context.coordinator.lastTriggerValue {
            context.coordinator.lastTriggerValue = focusTrigger
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }

    func makeCoordinator() -> SearchFieldCoordinator {
        SearchFieldCoordinator(self)
    }

    class SearchFieldCoordinator: NSObject, NSTextFieldDelegate {
        let parent: SearchField
        weak var textField: NSTextField?
        var lastTriggerValue: Bool = false

        init(_ parent: SearchField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            parent.text = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.moveDown(_:)) {
                parent.onArrowDown()
                return true
            }
            if commandSelector == #selector(NSResponder.moveUp(_:)) {
                parent.onArrowUp()
                return true
            }
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onEnter()
                return true
            }
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                parent.onEscape()
                return true
            }
            return false
        }
    }
}
