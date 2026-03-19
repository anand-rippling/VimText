import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: NotesViewModel
    @State private var showNewFolderSheet = false
    @State private var newFolderName = ""
    @State private var renamingFolder: NoteFolder?
    @State private var renameText = ""

    var body: some View {
        List(selection: Binding(
            get: { viewModel.showAllNotes ? "all" : viewModel.selectedFolderId?.uuidString ?? "all" },
            set: { newValue in
                if newValue == "all" {
                    viewModel.showAllNotes = true
                    viewModel.selectedFolderId = nil
                } else if let uuid = UUID(uuidString: newValue ?? "") {
                    viewModel.showAllNotes = false
                    viewModel.selectedFolderId = uuid
                }
            }
        )) {
            Section {
                Label {
                    HStack {
                        Text("All Notes")
                        Spacer()
                        Text("\(viewModel.allNotesCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: Capsule())
                    }
                } icon: {
                    Image(systemName: "note.text")
                        .foregroundStyle(.orange)
                }
                .tag("all")
            }

            Section("Folders") {
                ForEach(viewModel.folders) { folder in
                    Label {
                        HStack {
                            if renamingFolder?.id == folder.id {
                                TextField("Folder name", text: $renameText, onCommit: {
                                    viewModel.renameFolder(folder, to: renameText)
                                    renamingFolder = nil
                                })
                                .textFieldStyle(.plain)
                            } else {
                                Text(folder.name)
                                Spacer()
                                Text("\(viewModel.notesCount(for: folder.id))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.quaternary, in: Capsule())
                            }
                        }
                    } icon: {
                        Image(systemName: folder.icon)
                            .foregroundStyle(.orange)
                    }
                    .tag(folder.id.uuidString)
                    .contextMenu {
                        Button("Rename") {
                            renameText = folder.name
                            renamingFolder = folder
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            viewModel.deleteFolder(folder)
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button(action: { showNewFolderSheet = true }) {
                    Label("New Folder", systemImage: "folder.badge.plus")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                Spacer()
            }
            .background(.ultraThinMaterial)
        }
        .sheet(isPresented: $showNewFolderSheet) {
            VStack(spacing: 16) {
                Text("New Folder")
                    .font(.headline)
                TextField("Folder name", text: $newFolderName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 250)
                    .onSubmit {
                        createFolder()
                    }
                HStack(spacing: 12) {
                    Button("Cancel") {
                        newFolderName = ""
                        showNewFolderSheet = false
                    }
                    .keyboardShortcut(.cancelAction)
                    Button("Create") {
                        createFolder()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(newFolderName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(24)
        }
    }

    private func createFolder() {
        let name = newFolderName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        viewModel.createFolder(name: name)
        newFolderName = ""
        showNewFolderSheet = false
    }
}
