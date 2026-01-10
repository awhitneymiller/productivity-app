//
//  TaskView.swift
//  productivity-app
//
//  Created by Audrey W-M on 1/10/26.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Task View (UI-only)

struct TaskView: View {
    private let initial: TaskDraft

    // Callbacks (wire to real stores later)
    private let onSave: (TaskDraft) -> Void
    private let onDelete: ((UUID) -> Void)?

    @Environment(\.dismiss) private var dismiss

    // MARK: Editable fields

    @State private var id: UUID
    @State private var title: String

    @State private var hasDateTime: Bool
    @State private var date: Date

    @State private var durationMinutes: Int
    @State private var priority: TaskPriority

    @State private var reminderEnabled: Bool
    @State private var reminderOffsetMinutes: Int

    @State private var tagsText: String
    @State private var notes: String

    // Late handling (shifts the task date/time)
    @State private var lateEnabled: Bool = false
    @State private var minutesLate: Int = 10

    // Attachments
    @State private var showingDocPicker: Bool = false
    @State private var attachments: [TaskAttachment]

    // UI
    @FocusState private var titleFocused: Bool

    init(
        initial: TaskDraft,
        onSave: @escaping (TaskDraft) -> Void = { _ in },
        onDelete: ((UUID) -> Void)? = nil
    ) {
        self.initial = initial
        self.onSave = onSave
        self.onDelete = onDelete

        let draft = initial

        _id = State(initialValue: draft.id)
        _title = State(initialValue: draft.title)
        _hasDateTime = State(initialValue: draft.hasDateTime)
        _date = State(initialValue: draft.date)
        _durationMinutes = State(initialValue: draft.durationMinutes)
        _priority = State(initialValue: draft.priority)
        _reminderEnabled = State(initialValue: draft.reminderEnabled)
        _reminderOffsetMinutes = State(initialValue: draft.reminderOffsetMinutes)
        _tagsText = State(initialValue: draft.tags.joined(separator: ", "))
        _notes = State(initialValue: draft.notes)
        _attachments = State(initialValue: draft.attachments)
    }

    var body: some View {
        ZStack {
            TaskPastelBGView()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header

                    manualInputCard

                    lateCard

                    attachmentsCard

                    actionsCard

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)     // a bit more breathing room under nav bar
                .padding(.bottom, 22)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Task Details")
                    .font(.headline)
                    .foregroundStyle(TaskPalette.textPrimary)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    saveAndDismiss()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(TaskPalette.accent)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .sheet(isPresented: $showingDocPicker) {
            TaskDocumentPicker(
                onPick: { url in
                    attachments.append(TaskAttachment(url: url))
                },
                onCancel: { showingDocPicker = false }
            )
        }
        .onAppear {
            if title.isEmpty { titleFocused = true }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Edit details")
                .font(.title2.weight(.semibold))
                .foregroundStyle(TaskPalette.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 20)

        }
        .padding(.top, 2)
    }

    private var manualInputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Manual input")
                    .font(.headline)
                    .foregroundStyle(TaskPalette.textPrimary)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TaskPalette.textSecondary)

                TextField("What's the task?", text: $title)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
                    .focused($titleFocused)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(TaskPalette.field)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            // Date / Time / Scheduled row (fixed sizing)
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TaskPalette.textSecondary)

                    DatePicker(
                        "",
                        selection: $date,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(TaskPalette.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(TaskPalette.field)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .disabled(!hasDateTime)
                    .opacity(hasDateTime ? 1 : 0.55)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Time")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TaskPalette.textSecondary)

                    DatePicker(
                        "",
                        selection: $date,
                        displayedComponents: [.hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(TaskPalette.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(TaskPalette.field)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .disabled(!hasDateTime)
                    .opacity(hasDateTime ? 1 : 0.55)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .trailing, spacing: 8) {
                    Text("Scheduled")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TaskPalette.textSecondary)

                    Toggle("", isOn: $hasDateTime)
                        .labelsHidden()
                        .tint(TaskPalette.toggle)
                }
                .frame(width: 92)
            }

            // Duration (fixed +/- sizing)
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Duration")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TaskPalette.textSecondary)

                    Text(formatMinutes(durationMinutes))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TaskPalette.textPrimary)
                }

                Spacer()

                StepperPill(
                    value: $durationMinutes,
                    range: 5...480,
                    step: 5
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(TaskPalette.field)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                Text("Priority")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TaskPalette.textSecondary)

                HStack(spacing: 10) {
                    PriorityPill(title: "Low", isSelected: priority == .low) { priority = .low }
                    PriorityPill(title: "Normal", isSelected: priority == .normal) { priority = .normal }
                    PriorityPill(title: "High", isSelected: priority == .high) { priority = .high }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Add reminder")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TaskPalette.textPrimary)

                    Spacer()

                    Toggle("", isOn: $reminderEnabled)
                        .labelsHidden()
                        .tint(TaskPalette.toggle)
                }

                if reminderEnabled {
                    HStack(spacing: 12) {
                        Text("\(reminderOffsetMinutes) min before")
                            .font(.subheadline)
                            .foregroundStyle(TaskPalette.textSecondary)
                            .lineLimit(1)

                        Spacer()

                        StepperPill(
                            value: $reminderOffsetMinutes,
                            range: 5...240,
                            step: 5
                        )
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(TaskPalette.field)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                } else {
                    Text("Off")
                        .font(.caption)
                        .foregroundStyle(TaskPalette.textTertiary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TaskPalette.textSecondary)

                TextField("ex: school, gym", text: $tagsText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(TaskPalette.field)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TaskPalette.textSecondary)

                TextEditor(text: $notes)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 110)
                    .padding(12)
                    .background(TaskPalette.field)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(TaskPalette.textPrimary)
            }
        }
        .taskCard()
    }

    private var lateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Running late")
                    .font(.headline)
                    .foregroundStyle(TaskPalette.textPrimary)

                Spacer()

                Toggle("", isOn: $lateEnabled)
                    .labelsHidden()
                    .tint(TaskPalette.toggle)
            }

            Text("If this task starts later than planned, shift its time forward.")
                .font(.subheadline)
                .foregroundStyle(TaskPalette.textSecondary)

            HStack(spacing: 12) {
                Text("Late by")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TaskPalette.textPrimary)

                Spacer()

                StepperPill(
                    value: $minutesLate,
                    range: 0...240,
                    step: 5
                )
                .disabled(!lateEnabled || !hasDateTime)
                .opacity((lateEnabled && hasDateTime) ? 1 : 0.55)

                Text("\(minutesLate) min")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TaskPalette.textPrimary)
                    .frame(width: 84, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(TaskPalette.field)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .disabled(!lateEnabled || !hasDateTime)
            .opacity((lateEnabled && hasDateTime) ? 1 : 0.55)

            Button {
                applyLateShift()
            } label: {
                HStack {
                    Spacer()
                    Label("Apply late shift", systemImage: "clock.badge.exclamationmark")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(.vertical, 12)
                .background(TaskPalette.accent)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!lateEnabled || !hasDateTime || minutesLate == 0)
        }
        .taskCard()
    }

    private var attachmentsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Documents")
                    .font(.headline)
                    .foregroundStyle(TaskPalette.textPrimary)

                Spacer()

                Button {
                    showingDocPicker = true
                } label: {
                    Label("Add", systemImage: "paperclip")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TaskPalette.accent)
                }
                .buttonStyle(.plain)
            }

            if attachments.isEmpty {
                Text("No documents attached")
                    .font(.subheadline)
                    .foregroundStyle(TaskPalette.textSecondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(attachments) { a in
                        AttachmentRow(
                            name: a.displayName,
                            subtitle: a.url.lastPathComponent,
                            onRemove: {
                                attachments.removeAll(where: { $0.id == a.id })
                            }
                        )
                    }
                }
            }
        }
        .taskCard()
    }

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline)
                .foregroundStyle(TaskPalette.textPrimary)

            Button {
                saveAndDismiss()
            } label: {
                HStack {
                    Spacer()
                    Label("Save task", systemImage: "checkmark")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(.vertical, 12)
                .background(TaskPalette.accent)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if let onDelete {
                Button(role: .destructive) {
                    onDelete(id)
                    dismiss()
                } label: {
                    HStack {
                        Spacer()
                        Label("Delete", systemImage: "trash")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                    }
                    .foregroundStyle(TaskPalette.danger)
                    .padding(.vertical, 12)
                    .background(TaskPalette.field)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .taskCard()
    }

    // MARK: - Logic

    private func applyLateShift() {
        guard hasDateTime, lateEnabled, minutesLate > 0 else { return }
        date = Calendar.current.date(byAdding: .minute, value: minutesLate, to: date) ?? date
    }

    private func saveAndDismiss() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let draft = TaskDraft(
            id: id,
            title: trimmedTitle,
            hasDateTime: hasDateTime,
            date: date,
            durationMinutes: durationMinutes,
            priority: priority,
            reminderEnabled: reminderEnabled,
            reminderOffsetMinutes: reminderEnabled ? reminderOffsetMinutes : 0,
            tags: parseTags(tagsText),
            notes: notes,
            attachments: attachments
        )

        onSave(draft)
        dismiss()
    }

    private func parseTags(_ text: String) -> [String] {
        // commas or spaces both ok
        let raw = text
            .replacingOccurrences(of: "\n", with: " ")
            .split(whereSeparator: { $0 == "," || $0 == " " })
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        // de-dupe while preserving order
        var seen: Set<String> = []
        var out: [String] = []
        for r in raw {
            let k = r.lowercased()
            if !seen.contains(k) {
                seen.insert(k)
                out.append(r)
            }
        }
        return out
    }

    private func formatMinutes(_ mins: Int) -> String {
        let m = max(0, mins)
        let h = m / 60
        let r = m % 60
        if h == 0 { return "\(r) min" }
        if r == 0 { return "\(h) hr" }
        return "\(h) hr \(r) min"
    }
}

// MARK: - Subviews

private struct PriorityPill: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : TaskPalette.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? TaskPalette.accent : TaskPalette.pill)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct AttachmentRow: View {
    let name: String
    let subtitle: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc")
                .foregroundStyle(TaskPalette.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TaskPalette.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(TaskPalette.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(TaskPalette.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(TaskPalette.field)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// Fixed-size +/- control to avoid Stepper layout weirdness.
private struct StepperPill: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int

    var body: some View {
        HStack(spacing: 10) {
            StepperButton(symbol: "minus") {
                value = max(range.lowerBound, value - step)
            }
            .disabled(value - step < range.lowerBound)

            Divider()
                .frame(height: 18)
                .opacity(0.35)

            StepperButton(symbol: "plus") {
                value = min(range.upperBound, value + step)
            }
            .disabled(value + step > range.upperBound)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(TaskPalette.pill)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private struct StepperButton: View {
        let symbol: String
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 28, height: 28)
                    .foregroundStyle(TaskPalette.textPrimary)
                    .background(TaskPalette.field)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
}

private extension View {
    func taskCard() -> some View {
        self
            .padding(14)
            .background(TaskPalette.card)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(TaskPalette.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Models

struct TaskDraft: Identifiable, Equatable {
    let id: UUID

    var title: String

    var hasDateTime: Bool
    var date: Date

    var durationMinutes: Int
    var priority: TaskPriority

    var reminderEnabled: Bool
    var reminderOffsetMinutes: Int

    var tags: [String]
    var notes: String

    var attachments: [TaskAttachment]

    static func new() -> TaskDraft {
        TaskDraft(
            id: UUID(),
            title: "",
            hasDateTime: true,
            date: .now,
            durationMinutes: 30,
            priority: .normal,
            reminderEnabled: false,
            reminderOffsetMinutes: 15,
            tags: [],
            notes: "",
            attachments: []
        )
    }
}

enum TaskPriority: String, CaseIterable, Equatable, Codable {
    case low
    case normal
    case high
}

struct TaskAttachment: Identifiable, Equatable, Codable {
    let id: UUID
    let url: URL
    let addedAt: Date

    init(id: UUID = UUID(), url: URL, addedAt: Date = .now) {
        self.id = id
        self.url = url
        self.addedAt = addedAt
    }

    var displayName: String {
        url.deletingPathExtension().lastPathComponent
    }
}

// MARK: - Document Picker

private struct TaskDocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [
            .pdf,
            .plainText,
            .rtf,
            .image,
            .data
        ]

        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        let onCancel: () -> Void

        init(onPick: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onCancel()
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}

// MARK: - Background + local palette

private struct TaskPastelBGView: View {
    var body: some View {
        LinearGradient(
            colors: [TaskPalette.bgTop, TaskPalette.bgBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(
            ZStack {
                Circle()
                    .fill(TaskPalette.lavender.opacity(0.22))
                    .frame(width: 280, height: 280)
                    .blur(radius: 6)
                    .offset(x: -120, y: -220)

                Circle()
                    .fill(TaskPalette.periwinkle.opacity(0.18))
                    .frame(width: 320, height: 320)
                    .blur(radius: 8)
                    .offset(x: 140, y: -140)

                Circle()
                    .fill(TaskPalette.blue.opacity(0.14))
                    .frame(width: 360, height: 360)
                    .blur(radius: 10)
                    .offset(x: 40, y: 220)
            }
        )
    }
}

private enum TaskPalette {
    // Background
    static let bgTop = Color(red: 0.93, green: 0.92, blue: 0.98)
    static let bgBottom = Color(red: 0.90, green: 0.94, blue: 0.99)

    // Surfaces
    static let card = Color.white.opacity(0.60)
    static let field = Color.white.opacity(0.55)
    static let pill = Color.white.opacity(0.45)

    // Strokes
    static let stroke = Color.white.opacity(0.55)

    // Text
    static let textPrimary = Color(red: 0.14, green: 0.13, blue: 0.22)
    static let textSecondary = Color(red: 0.30, green: 0.29, blue: 0.44)
    static let textTertiary = Color(red: 0.42, green: 0.41, blue: 0.56)

    // Accents
    static let lavender = Color(red: 0.73, green: 0.67, blue: 0.95)
    static let periwinkle = Color(red: 0.63, green: 0.74, blue: 0.98)
    static let blue = Color(red: 0.62, green: 0.84, blue: 0.98)

    static let accent = Color(red: 0.56, green: 0.48, blue: 0.90)
    static let toggle = Color(red: 0.22, green: 0.80, blue: 0.45)
    static let danger = Color(red: 0.86, green: 0.19, blue: 0.23)
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TaskView(initial: TaskDraft(
            id: UUID(),
            title: "Finish HW + project",
            hasDateTime: true,
            date: .now,
            durationMinutes: 90,
            priority: .high,
            reminderEnabled: true,
            reminderOffsetMinutes: 15,
            tags: ["school", "cmsi"],
            notes: "Bring charger.",
            attachments: []
        ))
    }
}
