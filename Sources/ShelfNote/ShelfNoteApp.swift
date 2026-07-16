import AppKit
import SwiftData
import SwiftUI

@main
struct ShelfNoteApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            // ponytail: local persistence is the first release ceiling; switch to
            // `.private("iCloud.your-team.ShelfNote")` after enabling the entitlement.
            let configuration = ModelConfiguration(cloudKitDatabase: .none)
            modelContainer = try ModelContainer(for: Note.self, configurations: configuration)
        } catch {
            fatalError("Unable to create the local note store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ShelfView()
                .frame(minWidth: 1_080, minHeight: 720)
                .preferredColorScheme(.light)
        }
        .modelContainer(modelContainer)
        .windowStyle(.hiddenTitleBar)
    }
}

struct ShelfView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.createdAt, order: .reverse) private var notes: [Note]

    @State private var selectedProject: Project = .pinned
    @State private var draft = ""
    @State private var reminderChoice: ReminderChoice = .none
    @State private var color: NoteColor = .indigo
    @State private var search = ""

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
        .onAppear(perform: seedIfNeeded)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                TextField("Search notes", text: $search)
                    .textFieldStyle(.plain)
            }
            .padding(11)
            .background(.white, in: RoundedRectangle(cornerRadius: 10))

            Text("CAPTURE")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            VStack(spacing: 4) {
                ForEach(Project.allCases) { project in
                    SidebarRow(
                        project: project,
                        count: NoteQuery.visible(notes, in: project).count,
                        isSelected: selectedProject == project
                    ) {
                        selectedProject = project
                    }
                }
            }

            Spacer()

            Label("Local store", systemImage: "externaldrive.fill")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("iCloud-ready")
                .font(.caption)
                .foregroundStyle(.secondary)
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
                Spacer()
                Menu {
                    Picker("Note color", selection: $color) {
                        ForEach(NoteColor.allCases) { color in
                            Text(color.rawValue.capitalized).tag(color)
                        }
                    }
                } label: {
                    Label("Style", systemImage: "paintpalette")
                }
            }

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 18)], spacing: 18) {
                    ForEach(visibleNotes, id: \.id) { note in
                        NoteCard(note: note, togglePin: { togglePin(note) }, delete: { delete(note) })
                    }
                }
                .padding(.vertical, 4)
            }

            composer
        }
        .padding(30)
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Quick note… anything on your mind?", text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(2...4)
                .font(.title3)

            HStack {
                Picker("Reminder", selection: $reminderChoice) {
                    ForEach(ReminderChoice.allCases) { choice in
                        Text(choice.label).tag(choice)
                    }
                }
                .labelsHidden()
                .frame(width: 170)

                Picker("Color", selection: $color) {
                    ForEach(NoteColor.allCases) { option in
                        Circle().fill(NotePalette.color(for: option)).frame(width: 10, height: 10).tag(option)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 180)

                Spacer()

                Button(action: addNote) {
                    Label("Add Note", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
    }

    private func addNote() {
        let target = selectedProject.canCreateNotes ? selectedProject : .inbox
        let note = Note(
            text: draft.trimmingCharacters(in: .whitespacesAndNewlines),
            project: target.rawValue,
            isPinned: selectedProject == .pinned,
            reminderAt: reminderChoice.date,
            colorName: color.rawValue
        )
        modelContext.insert(note)
        ReminderScheduler.schedule(for: note)
        draft = ""
        reminderChoice = .none
    }

    private func togglePin(_ note: Note) {
        note.isPinned.toggle()
    }

    private func delete(_ note: Note) {
        ReminderScheduler.cancel(for: note)
        modelContext.delete(note)
    }

    private func seedIfNeeded() {
        guard notes.isEmpty else { return }
        let examples: [(String, Project, Bool, NoteColor)] = [
            ("Ship first note\nKeep the capture flow fast and out of the way.", .inbox, true, .indigo),
            ("Call with Mom\nFollow up with the doctor after work.", .tasks, true, .coral),
            ("Weekend hike ideas\nCascade Lake or Tolmie Peak. Pack water and layers.", .ideas, true, .citrus),
            ("Read: Atomic Habits\nCapture one useful takeaway from chapter three.", .readLater, true, .mint),
            ("Meeting notes\nDecide the next action before closing the note.", .notes, true, .sky),
            ("Plan next bike tune-up\nReplace chain and book shop time this week.", .tasks, true, .lavender)
        ]
        for (text, project, pinned, noteColor) in examples {
            modelContext.insert(Note(text: text, project: project.rawValue, isPinned: pinned, colorName: noteColor.rawValue))
        }
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
    let togglePin: () -> Void
    let delete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(note.project, systemImage: "folder.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Menu {
                    Button(note.isPinned ? "Unpin" : "Pin", action: togglePin)
                    Button("Delete", role: .destructive, action: delete)
                } label: {
                    Image(systemName: note.isPinned ? "pin.fill" : "ellipsis")
                }
                .menuStyle(.borderlessButton)
            }

            Text(note.title)
                .font(.title3.weight(.bold))
                .lineLimit(2)
            Text(note.preview)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

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
        .frame(minHeight: 220, alignment: .topLeading)
        .background(NotePalette.color(for: NoteColor(rawValue: note.colorName) ?? .indigo).opacity(0.16), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(NotePalette.color(for: NoteColor(rawValue: note.colorName) ?? .indigo).opacity(0.38), lineWidth: 1)
        }
    }
}

private enum NotePalette {
    static func color(for color: NoteColor) -> Color {
        switch color {
        case .indigo: Color(red: 0.25, green: 0.36, blue: 0.92)
        case .coral: Color(red: 0.91, green: 0.28, blue: 0.29)
        case .citrus: Color(red: 0.78, green: 0.49, blue: 0.03)
        case .mint: Color(red: 0.08, green: 0.52, blue: 0.33)
        case .sky: Color(red: 0.17, green: 0.51, blue: 0.87)
        case .lavender: Color(red: 0.48, green: 0.33, blue: 0.82)
        }
    }
}

private enum ReminderChoice: String, CaseIterable, Identifiable {
    case none, inOneHour, tomorrowMorning

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: "No reminder"
        case .inOneHour: "In one hour"
        case .tomorrowMorning: "Tomorrow 9 AM"
        }
    }

    var date: Date? {
        switch self {
        case .none:
            return nil
        case .inOneHour:
            return Calendar.current.date(byAdding: .hour, value: 1, to: .now)
        case .tomorrowMorning:
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
            return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow)
        }
    }
}
