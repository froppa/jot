import AppKit
import SwiftData
import SwiftUI

@main
struct JotApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            // ponytail: local persistence is the first release ceiling; switch to
            // `.private("iCloud.your-team.Jot")` after enabling the entitlement.
            let configuration = ModelConfiguration(cloudKitDatabase: .none)
            modelContainer = try ModelContainer(for: Note.self, configurations: configuration)
        } catch {
            fatalError("Unable to create the local note store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            JotView()
                .frame(minWidth: 1_080, minHeight: 720)
                .preferredColorScheme(.light)
        }
        .modelContainer(modelContainer)
        .windowStyle(.hiddenTitleBar)
    }
}

struct JotView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.createdAt, order: .reverse) private var notes: [Note]

    @State private var selectedProject: Project = .inbox
    @State private var draft = ""
    @State private var search = ""
    @State private var editingNote: Note?
    @State private var noteToDelete: Note?
    @FocusState private var isCaptureFocused: Bool

    private var visibleNotes: [Note] {
        let scoped = NoteQuery.visible(notes, in: selectedProject)
        guard !search.isEmpty else { return scoped }
        return scoped.filter { $0.text.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 268)
            Divider()
            mainContent
        }
        .background(Color(red: 0.985, green: 0.985, blue: 0.99))
        .task {
            isCaptureFocused = true
        }
        .sheet(isPresented: Binding(
            get: { editingNote != nil },
            set: { if !$0 { editingNote = nil } }
        )) {
            if let note = editingNote {
                EditNoteSheet(
                    note: note,
                    requestDelete: {
                        editingNote = nil
                        noteToDelete = note
                    }
                )
            }
        }
        .confirmationDialog(
            "Delete this note?",
            isPresented: Binding(
                get: { noteToDelete != nil },
                set: { if !$0 { noteToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let noteToDelete {
                    delete(noteToDelete)
                    self.noteToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                noteToDelete = nil
            }
        } message: {
            Text("This can’t be undone.")
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 34, height: 34)
                    .accessibilityHidden(true)
                Text("Jot")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                TextField("Search notes", text: $search)
                    .textFieldStyle(.plain)
            }
            .padding(11)
            .background(.white, in: RoundedRectangle(cornerRadius: 10))

            SidebarRow(
                project: .inbox,
                count: NoteQuery.visible(notes, in: .inbox).count,
                isSelected: selectedProject == .inbox
            ) {
                selectedProject = .inbox
            }

            Text("CATEGORIES")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            VStack(spacing: 4) {
                ForEach([Project.notes, .ideas, .tasks, .readLater]) { project in
                    SidebarRow(
                        project: project,
                        count: NoteQuery.visible(notes, in: project).count,
                        isSelected: selectedProject == project
                    ) {
                        selectedProject = project
                    }
                }
            }

            SidebarRow(
                project: .pinned,
                count: NoteQuery.visible(notes, in: .pinned).count,
                isSelected: selectedProject == .pinned
            ) {
                selectedProject = .pinned
            }

            Spacer()
        }
        .padding(20)
        .background(Color(red: 0.96, green: 0.97, blue: 0.99))
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedProject.rawValue)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("\(visibleNotes.count) note\(visibleNotes.count == 1 ? "" : "s")")
                        .foregroundStyle(.secondary)
                }
            }

            composer

            ScrollView {
                Group {
                    if visibleNotes.isEmpty {
                        ContentUnavailableView {
                            Label(emptyTitle, systemImage: selectedProject == .inbox ? "tray" : "note.text")
                        } description: {
                            Text(emptyDescription)
                        }
                        .frame(maxWidth: .infinity, minHeight: 320)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(visibleNotes, id: \.id) { note in
                                NoteCard(
                                    note: note,
                                    edit: { editingNote = note },
                                    togglePin: { togglePin(note) },
                                    requestDelete: { noteToDelete = note }
                                )
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(30)
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Quick capture", systemImage: "bolt.fill")
                    .font(.headline)
                    .foregroundStyle(.tint)
                Spacer()
                Text("Markdown · ⌘↩")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .bottom, spacing: 12) {
                TextField("Write a note…", text: $draft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .font(.title3)
                    .focused($isCaptureFocused)
                    .padding(12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 10))

                Button(action: addNote) {
                    Label("Capture", systemImage: "tray.and.arrow.down.fill")
                        .font(.headline)
                        .padding(.horizontal, 6)
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.accentColor.opacity(0.35), lineWidth: 1.5)
        }
    }

    private func addNote() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let note = Note(
            text: text,
            project: Project.inbox.rawValue
        )
        modelContext.insert(note)
        draft = ""
        selectedProject = .inbox
        isCaptureFocused = true
    }

    private func togglePin(_ note: Note) {
        note.isPinned.toggle()
    }

    private func delete(_ note: Note) {
        ReminderScheduler.cancel(for: note)
        modelContext.delete(note)
    }

    private var emptyTitle: String {
        search.isEmpty ? "No notes in \(selectedProject.rawValue)" : "No matching notes"
    }

    private var emptyDescription: String {
        if !search.isEmpty {
            return "Try a different search."
        }
        if selectedProject == .inbox {
            return "Capture a note above."
        }
        if selectedProject == .pinned {
            return "Pin notes to see them here."
        }
        return "Move notes here when you edit them."
    }
}

private struct SidebarRow: View {
    let project: Project
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 18)
                Text(project.rawValue)
                Spacer()
                Text("\(count)")
                    .foregroundStyle(isSelected ? .white.opacity(0.78) : .secondary)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(isSelected ? Color.accentColor : .clear, in: RoundedRectangle(cornerRadius: 9))
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private var icon: String {
        switch project {
        case .pinned: "pin.fill"
        case .inbox: "tray.fill"
        case .ideas: "lightbulb.fill"
        case .tasks: "checklist"
        case .readLater: "book.closed.fill"
        case .notes: "note.text"
        }
    }
}

private struct NoteCard: View {
    let note: Note
    let edit: () -> Void
    let togglePin: () -> Void
    let requestDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(note.project, systemImage: "folder.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: edit) {
                    Label("Edit", systemImage: "pencil")
                }
                .buttonStyle(.borderless)
                Menu {
                    Button(note.isPinned ? "Unpin" : "Pin", action: togglePin)
                    Button("Delete", role: .destructive, action: requestDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
            }

            Text(note.formattedText)
                .lineLimit(8)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                if let reminder = note.reminderAt {
                    Label(reminder.formatted(date: .abbreviated, time: .shortened), systemImage: "bell")
                        .font(.caption)
                } else {
                    Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                }
                Spacer()
                Image(systemName: note.isPinned ? "pin.fill" : "note.text")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(.white, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.black.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct EditNoteSheet: View {
    let note: Note
    let requestDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @State private var project: Project
    @State private var isPinned: Bool

    init(note: Note, requestDelete: @escaping () -> Void) {
        self.note = note
        self.requestDelete = requestDelete
        _text = State(initialValue: note.text)
        _project = State(initialValue: Project(rawValue: note.project) ?? .inbox)
        _isPinned = State(initialValue: note.isPinned)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Edit note")
                .font(.title2.weight(.bold))

            TextField("Write a note", text: $text, axis: .vertical)
                .lineLimit(5...12)
                .textFieldStyle(.roundedBorder)
                .font(.body.monospaced())

            Picker("Category", selection: $project) {
                ForEach(Project.allCases.filter(\.canCreateNotes)) { option in
                    Text(option.rawValue).tag(option)
                }
            }

            Toggle("Keep pinned", isOn: $isPinned)

            Spacer()

            HStack {
                Button("Delete", role: .destructive) {
                    requestDelete()
                    dismiss()
                }
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                    .keyboardShortcut(.cancelAction)
                Button("Save", action: save)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(minWidth: 460, minHeight: 350)
    }

    private func save() {
        note.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        note.project = project.rawValue
        note.isPinned = isPinned
        dismiss()
    }
}
