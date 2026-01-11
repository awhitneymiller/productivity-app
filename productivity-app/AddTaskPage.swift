//
//  AddTaskPage.swift
//  productivity-app
//
//  Created by Audrey W-M on 1/8/26.
//

import SwiftUI

// MARK: - API DTOs


struct CreateTaskResponse: Decodable {
    let message: String
    let task: TaskDTO
}

struct TaskDTO: Decodable {
    let id: Int
    let title: String
    let due_date: String
    let due_at: String?
    let duration_minutes: Int
    let priority: String
    let reminder_offset_minutes: Int?
    let tags: String?
    let notes: String?
}

enum APIError: LocalizedError {
    case missingToken
    case badURL
    case serverError(status: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .missingToken:
            return "Missing access token. Please sign in again."
        case .badURL:
            return "Bad server URL."
        case .serverError(_, let message):
            return message.isEmpty ? "Request failed." : message
        }
    }
}

struct AddTaskPage: View {
    // MARK: - Modes
    enum InputMode: String, CaseIterable, Identifiable {
        case quick = "Quick Capture"
        case manual = "Manual"
        var id: String { rawValue }
    }
    
    @EnvironmentObject private var auth: AuthManager

    @Environment(\.dismiss) private var dismiss

    @State private var mode: InputMode = .quick
    @StateObject private var voiceTranscriber = VoiceTranscriber()

    // MARK: - Quick capture
    @State private var naturalInput: String = "Meet with Maya tomorrow at 3, remind me 30 min before, and bring my charger"
    @State private var didRunAI: Bool = false

    // Parsed preview (placeholder)
    @State private var parsedTitle: String = "Meet with Maya"
    @State private var parsedDate: String = "Tomorrow"
    @State private var parsedTime: String = "3:00 PM"
    @State private var parsedReminder: String = "30 min before"
    @State private var parsedExtras: [String] = ["Bring charger"]

    // MARK: - Manual fallback
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var date: Date = Date()
    @State private var hasTime: Bool = true
    @State private var time: Date = Date()
    @State private var durationMinutes: Int = 30
    @State private var priority: Priority = .normal
    @State private var addReminder: Bool = true
    @State private var reminderMinutesBefore: Int = 15
    @State private var tagText: String = ""

    // MARK: - Networking state
    @State private var isSaving: Bool = false
    @State private var saveError: String? = nil

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    background

                    accentBlobs(in: geo.size)
                        .ignoresSafeArea()

                    ScrollView {
                        VStack(spacing: 16) {
                            headerCard
                                .padding(.top, 14)

                            modePicker

                            if mode == .quick {
                                quickCaptureCard
                                aiPreviewCard
                            } else {
                                manualCard
                            }

                            actionButtons

                            if let saveError {
                                Text(saveError)
                                    .font(.footnote)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            Spacer(minLength: 18)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onChange(of: hasTime) { newValue in
            // Don’t allow reminders if time is off (backend will reject it)
            if !newValue { addReminder = false }
        }
    }

    // MARK: - UI Pieces

    private var background: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.96, green: 0.94, blue: 0.99),
                Color(red: 0.92, green: 0.90, blue: 0.98),
                Color(red: 0.90, green: 0.93, blue: 0.99)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tell me what you’re doing")
                .font(.system(size: 22, weight: .bold, design: .rounded))

            Text("Type or speak naturally. AI will turn it into a task, time block, reminders, and notes. You can always switch to manual input.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(glassCard)
        .overlay(glassStroke)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var modePicker: some View {
        HStack(spacing: 10) {
            ForEach(InputMode.allCases) { m in
                Button {
                    withAnimation(.easeOut(duration: 0.15)) {
                        mode = m
                    }
                } label: {
                    Text(m.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(mode == m ? .white : Color(red: 0.39, green: 0.28, blue: 0.60))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(mode == m ? AnyShapeStyle(primaryGradient) : AnyShapeStyle(Color.white.opacity(0.65)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 999, style: .continuous)
                                .stroke(Color.white.opacity(0.55), lineWidth: mode == m ? 0 : 1)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var quickCaptureCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick capture")
                    .font(.headline)

                Spacer()

                Button {
                    withAnimation(.easeOut(duration: 0.12)) {
                        voiceTranscriber.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: voiceTranscriber.isRecording ? "waveform.circle.fill" : "mic.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text(voiceTranscriber.isRecording ? "Listening" : "Speak")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(Color(red: 0.39, green: 0.28, blue: 0.60))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.65))
                    .overlay(
                        RoundedRectangle(cornerRadius: 999, style: .continuous)
                            .stroke(Color.white.opacity(0.55), lineWidth: 1)
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Text(voiceTranscriber.status)
                .font(.footnote.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.top, 2)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $naturalInput)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .padding(10)
                    .background(Color.white.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .onChange(of: voiceTranscriber.transcript) {
                        let trimmed = voiceTranscriber.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        guard !voiceTranscriber.isRecording else { return }
                        naturalInput = trimmed
                        didRunAI = false
                    }

                if naturalInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Example: \"Work on CMSI homework tonight for 45 minutes, remind me at 7, and pack my laptop\"")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 18)
                }
            }

            HStack(spacing: 10) {
                Button {
                    naturalInput = ""
                    voiceTranscriber.transcript = ""
                    didRunAI = false
                } label: {
                    Text("Clear")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(SecondaryPillButtonStyle())

                Button {
                    didRunAI = true
                    parsedTitle = guessTitle(from: naturalInput)
                    parsedExtras = guessExtras(from: naturalInput)
                    parsedDate = naturalInput.lowercased().contains("tomorrow") ? "Tomorrow" : (naturalInput.lowercased().contains("today") ? "Today" : "")
                    parsedTime = (naturalInput.lowercased().contains(" at ") ? "" : parsedTime)
                    parsedReminder = naturalInput.lowercased().contains("remind") ? (parsedReminder.isEmpty ? "15 min before" : parsedReminder) : ""
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("AI Fill")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PrimaryPillButtonStyle())
            }
        }
        .padding(16)
        .background(glassCard)
        .overlay(glassStroke)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var aiPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI preview")
                    .font(.headline)

                Spacer()

                Text(didRunAI ? "Draft" : "Run AI Fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(didRunAI ? Color(red: 0.39, green: 0.28, blue: 0.60) : .secondary)
            }

            if !didRunAI {
                Text("—")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                previewRow(label: "Title", value: parsedTitle.isEmpty ? "New task" : parsedTitle)
                previewRow(label: "Date", value: parsedDate.isEmpty ? "—" : parsedDate)
                previewRow(label: "Time", value: parsedTime.isEmpty ? "—" : parsedTime)

                if !parsedReminder.isEmpty {
                    previewRow(label: "Reminder", value: parsedReminder)
                }

                if !parsedExtras.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Extra")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)

                        FlowChips(items: parsedExtras)
                    }
                }

                Text("AI preview isn’t wired to save yet — switch to Manual to save.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(16)
        .background(glassCard)
        .overlay(glassStroke)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var manualCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Manual input")
                .font(.headline)

            LabeledField(title: "Title") {
                TextField("What’s the task?", text: $title)
                    .textInputAutocapitalization(.sentences)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)

                    DatePicker("", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Time", isOn: $hasTime)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)

                    if hasTime {
                        DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    } else {
                        Text("No specific time")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Duration")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)

                Stepper(value: $durationMinutes, in: 5...240, step: 5) {
                    Text("\(durationMinutes) min")
                        .font(.subheadline)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Priority")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)

                HStack(spacing: 10) {
                    ForEach(Priority.allCases) { p in
                        Button { priority = p } label: {
                            Text(p.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(priority == p ? .white : Color(red: 0.39, green: 0.28, blue: 0.60))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(priority == p ? AnyShapeStyle(primaryGradient) : AnyShapeStyle(Color.white.opacity(0.65)))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                                        .stroke(Color.white.opacity(0.55), lineWidth: priority == p ? 0 : 1)
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Toggle("Add reminder", isOn: $addReminder)
                    .font(.subheadline.weight(.semibold))

                if addReminder {
                    Stepper(value: $reminderMinutesBefore, in: 5...180, step: 5) {
                        Text("\(reminderMinutesBefore) min before")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            LabeledField(title: "Tags") {
                TextField("ex: school, gym", text: $tagText)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)

                TextEditor(text: $notes)
                    .frame(minHeight: 90)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .background(Color.white.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(16)
        .background(glassCard)
        .overlay(glassStroke)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                Task { await saveManualTask() }
            } label: {
                HStack(spacing: 10) {
                    if isSaving { ProgressView().tint(.white) }
                    Text(isSaving ? "Saving..." : "Save")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(PrimaryPillButtonStyle())
            .disabled(isSaving)

            Button {
                // Placeholder: create as time block later
            } label: {
                Text("Save as time block")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color(red: 0.39, green: 0.28, blue: 0.60))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.65))
                    .overlay(
                        RoundedRectangle(cornerRadius: 999, style: .continuous)
                            .stroke(Color.white.opacity(0.55), lineWidth: 1)
                    )
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }

    private func previewRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
                .frame(width: 72, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }

    private var glassCard: some ShapeStyle {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.70),
                Color.white.opacity(0.52)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var glassStroke: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(Color.white.opacity(0.45), lineWidth: 1)
    }

    private var primaryGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.76, green: 0.70, blue: 0.95),
                Color(red: 0.93, green: 0.62, blue: 0.82)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func accentBlobs(in size: CGSize) -> some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.93, green: 0.62, blue: 0.82).opacity(0.35))
                .frame(width: size.width * 0.75, height: size.width * 0.75)
                .blur(radius: 18)
                .offset(x: -size.width * 0.25, y: -size.height * 0.35)

            Circle()
                .fill(Color(red: 0.76, green: 0.70, blue: 0.95).opacity(0.35))
                .frame(width: size.width * 0.70, height: size.width * 0.70)
                .blur(radius: 18)
                .offset(x: size.width * 0.35, y: -size.height * 0.20)

            Circle()
                .fill(Color(red: 0.90, green: 0.93, blue: 0.99).opacity(0.55))
                .frame(width: size.width * 0.85, height: size.width * 0.85)
                .blur(radius: 24)
                .offset(x: size.width * 0.05, y: size.height * 0.35)
        }
    }

    // MARK: - Networking

    private func saveManualTask() async {
        await MainActor.run {
            saveError = nil
            isSaving = true
        }

        do {
            // Only allow saving from Manual mode for now
            guard mode == .manual else {
                throw APIError.serverError(status: 0, message: "Switch to Manual to save for now.")
            }

            guard let token = auth.accessToken, !token.isEmpty else { throw APIError.missingToken }

            guard let url = URL(string: "http://127.0.0.1:5001/api/create/task") else {
                throw APIError.badURL
            }

            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            // Required fields
            let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedTitle.isEmpty {
                throw APIError.serverError(status: 400, message: "Title is required.")
            }

            // Formatters to match Flask parsing
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone.current
            dateFormatter.dateFormat = "yyyy-MM-dd"

            let timeFormatter = DateFormatter()
            timeFormatter.locale = Locale(identifier: "en_US_POSIX")
            timeFormatter.timeZone = TimeZone.current
            timeFormatter.dateFormat = "HH:mm"

            var payload: [String: Any] = [
                "title": trimmedTitle,
                "due_date": dateFormatter.string(from: date),
                "duration_minutes": durationMinutes,
                "priority": priority.rawValue
            ]

            // Optional time
            if hasTime {
                let cal = Calendar.current
                let hour = cal.component(.hour, from: time)
                let minute = cal.component(.minute, from: time)
                payload["due_time"] = String(format: "%02d:%02d", hour, minute)

                if addReminder {
                    payload["reminder_minutes"] = reminderMinutesBefore
                }
            }


            // Optional tags/notes
            let tags = tagText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !tags.isEmpty { payload["tags"] = tags }

            let n = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            if !n.isEmpty { payload["notes"] = n }

            req.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else {
                throw APIError.serverError(status: 0, message: "No server response.")
            }

            if !(200..<300).contains(http.statusCode) {
                let serverText = String(data: data, encoding: .utf8) ?? ""
                throw APIError.serverError(status: http.statusCode, message: serverText)
            }

            // Optional: decode response to confirm shape
            _ = try? JSONDecoder().decode(CreateTaskResponse.self, from: data)

            await MainActor.run {
                isSaving = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                isSaving = false
                saveError = error.localizedDescription
            }
        }
    }

    // MARK: - Tiny placeholder “AI” helpers

    private func guessTitle(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "New task" }

        let lower = trimmed.lowercased()
        if let r = lower.range(of: ",") {
            let head = String(trimmed[..<r.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            return head.isEmpty ? trimmed : head
        }
        if let r = lower.range(of: " and ") {
            let head = String(trimmed[..<r.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            return head.isEmpty ? trimmed : head
        }
        return trimmed
    }

    private func guessExtras(from text: String) -> [String] {
        let lower = text.lowercased()
        var extras: [String] = []
        if lower.contains("charger") { extras.append("Bring charger") }
        if lower.contains("keys") { extras.append("Grab keys") }
        if lower.contains("wallet") { extras.append("Bring wallet") }
        if lower.contains("laptop") { extras.append("Bring laptop") }
        if lower.contains("water") || lower.contains("bottle") { extras.append("Bring water") }
        return Array(Set(extras)).sorted()
    }
}

// MARK: - Supporting Views

struct FlowChips: View {
    let items: [String]

    var body: some View {
        FlexibleView(
            data: items,
            spacing: 8,
            alignment: .leading
        ) { item in
            Text(item)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color(red: 0.39, green: 0.28, blue: 0.60))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .stroke(Color.white.opacity(0.55), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
    }
}

struct LabeledField<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)

            content
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

enum Priority: String, CaseIterable, Identifiable {
    case low
    case normal
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        }
    }
}

// Simple flexible layout for chips
struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content

    @State private var availableWidth: CGFloat = 0

    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { availableWidth = proxy.size.width }
                    .onChange(of: proxy.size.width) { availableWidth = $0 }
            }
            .frame(height: 0)

            generateContent(in: availableWidth)
        }
    }

    private func generateContent(in width: CGFloat) -> some View {
        var currentRow: [Data.Element] = []
        var rows: [[Data.Element]] = []
        var currentWidth: CGFloat = 0

        for item in data {
            let estimated = CGFloat(String(describing: item).count) * 8.0 + 34.0
            if currentWidth + estimated + spacing > width, !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow = [item]
                currentWidth = estimated
            } else {
                currentRow.append(item)
                currentWidth += estimated + spacing
            }
        }
        if !currentRow.isEmpty { rows.append(currentRow) }

        return VStack(alignment: alignment, spacing: spacing) {
            ForEach(rows.indices, id: \.self) { r in
                HStack(spacing: spacing) {
                    ForEach(rows[r], id: \.self) { item in
                        content(item)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

#Preview {
    AddTaskPage()
}
