import SwiftUI

struct NoteEditorView: View {
    @ObservedObject var viewModel: NotesViewModel
    let noteId: UUID

    @StateObject private var vimEngine = VimEngine()
    @StateObject private var findController = FindController()
    @State private var content: String = ""
    @State private var rtfData: Data = Data()
    @State private var hasLoaded = false
    @State private var startInInsertMode = false
    @FocusState private var isFindFieldFocused: Bool
    @AppStorage("editorFontSize") private var fontSize: Double = 15
    @AppStorage("showLineNumbers") private var showLineNumbers: Bool = false

    private var editorFont: NSFont {
        NSFont.monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular)
    }

    private var note: Note? {
        viewModel.notes.first { $0.id == noteId }
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                editorArea
                if findController.isVisible {
                    findBar
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                }
            }
            if vimEngine.showCommandLine {
                commandLine
            }
            statusBar
        }
        .onAppear {
            loadNote()
        }
        .onDisappear {
            saveCurrentNote()
        }
        .onChange(of: findController.focusTrigger) { _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFindFieldFocused = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .findInNote)) { _ in
            withAnimation(.easeInOut(duration: 0.15)) {
                findController.isVisible = true
            }
            findController.focusTrigger += 1
        }
    }

    private var editorArea: some View {
        VimTextView(
            text: $content,
            rtfData: $rtfData,
            vimEngine: vimEngine,
            findController: findController,
            onSave: { saveCurrentNote() },
            font: editorFont,
            startInInsertMode: startInInsertMode
        )
        .onChange(of: content) { _, newValue in
            let newTitle = extractTitle(from: newValue)
            viewModel.updateNoteContent(id: noteId, title: newTitle.isEmpty ? "Untitled" : newTitle, content: newValue, rtfData: rtfData)
        }
        .onChange(of: rtfData) { _, newValue in
            let title = extractTitle(from: content)
            viewModel.updateNoteContent(id: noteId, title: title.isEmpty ? "Untitled" : title, content: content, rtfData: newValue)
        }
    }

    private var findBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 13))

            TextField("Find in note…", text: $findController.query)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isFindFieldFocused)
                .onSubmit {
                    findController.findNext?()
                }
                .onExitCommand {
                    closeFindBar()
                }
                .onChange(of: findController.query) { _, newValue in
                    findController.performFind?(newValue)
                }

            if findController.totalMatches > 0 {
                Text("\(findController.currentMatch) of \(findController.totalMatches)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .fixedSize()
            } else if !findController.query.isEmpty {
                Text("No results")
                    .font(.system(size: 11))
                    .foregroundStyle(.red.opacity(0.8))
                    .fixedSize()
            }

            Button(action: { findController.findPrev?() }) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .disabled(findController.totalMatches == 0)

            Button(action: { findController.findNext?() }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .disabled(findController.totalMatches == 0)

            Divider()
                .frame(height: 16)

            Button(action: { closeFindBar() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(Color(nsColor: .separatorColor)),
            alignment: .bottom
        )
    }

    private func closeFindBar() {
        withAnimation(.easeInOut(duration: 0.15)) {
            findController.isVisible = false
        }
        findController.dismiss?()
        findController.query = ""
        findController.currentMatch = 0
        findController.totalMatches = 0
        findController.refocusEditor?()
    }

    private var commandLine: some View {
        HStack(spacing: 4) {
            Text(vimEngine.commandLinePrefix)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.primary)
            Text(vimEngine.commandLineText)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var statusBar: some View {
        HStack(spacing: 12) {
            modeIndicator

            if !vimEngine.statusMessage.isEmpty {
                Text(vimEngine.statusMessage)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let note = note {
                Text(formatDate(note.modifiedAt))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text(cursorInfo)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)

            Menu {
                fontSizeMenu
                Divider()
                Toggle("Line Numbers", isOn: $showLineNumbers)
            } label: {
                Image(systemName: "textformat.size")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 24)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
    }

    private var modeIndicator: some View {
        Text(vimEngine.mode.displayName)
            .font(.system(.caption, design: .monospaced).bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(modeColor, in: RoundedRectangle(cornerRadius: 4))
    }

    private var modeColor: Color {
        switch vimEngine.mode {
        case .normal: return .blue
        case .insert: return .green
        case .visual, .visualLine, .visualBlock: return .purple
        case .command: return .orange
        case .replace: return .red
        }
    }

    @ViewBuilder
    private var fontSizeMenu: some View {
        Button("Increase Font Size") { fontSize = min(fontSize + 1, 32) }
            .keyboardShortcut("+", modifiers: .command)
        Button("Decrease Font Size") { fontSize = max(fontSize - 1, 10) }
            .keyboardShortcut("-", modifiers: .command)
        Button("Reset Font Size") { fontSize = 15 }
    }

    private var cursorInfo: String {
        let lines = content.components(separatedBy: "\n")
        let totalLines = lines.count
        return "Ln \(totalLines) | \(content.count) chars"
    }

    private func loadNote() {
        if let note = viewModel.notes.first(where: { $0.id == noteId }) {
            content = note.content
            rtfData = note.rtfData ?? Data()
            hasLoaded = true
            let isNewEmpty = note.content.isEmpty
            startInInsertMode = isNewEmpty
            vimEngine.mode = isNewEmpty ? .insert : .normal
            vimEngine.resetBuffers()
            vimEngine.statusMessage = ""
            vimEngine.showCommandLine = false
            if findController.isVisible {
                closeFindBar()
            }
        }
    }

    private func saveCurrentNote() {
        let title = extractTitle(from: content)
        viewModel.updateNoteContent(id: noteId, title: title.isEmpty ? "Untitled" : title, content: content, rtfData: rtfData)
    }

    private func extractTitle(from text: String) -> String {
        let firstLine = text.components(separatedBy: .newlines).first ?? ""
        return String(firstLine.prefix(100)).trimmingCharacters(in: .whitespaces)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
