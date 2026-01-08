//
//  AddTaskPage.swift
//  productivity-app
//
//  Created by Audrey W-M on 1/8/26.
//

import SwiftUI

struct AddTaskPage: View {
    // MARK: - Modes
    enum InputMode: String, CaseIterable, Identifiable {
        case quick = "Quick Capture"
        case manual = "Manual"
        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss

    @State private var mode: InputMode = .quick

    // MARK: - Quick capture
    @State private var naturalInput: String = "Meet with Maya tomorrow at 3, remind me 30 min before, and bring my charger"
    @State private var isListening: Bool = false
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
                    // Placeholder: wire speech-to-text later
                    withAnimation(.easeOut(duration: 0.12)) {
                        isListening.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isListening ? "waveform.circle.fill" : "mic.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text(isListening ? "Listening" : "Speak")
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

            ZStack(alignment: .topLeading) {
                TextEditor(text: $naturalInput)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .padding(10)
                    .background(Color.white.opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

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
                    // Placeholder: clear
                    naturalInput = ""
                    didRunAI = false
                } label: {
                    Text("Clear")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(SecondaryPillButtonStyle())

                Button {
                    // Placeholder: AI parse
                    didRunAI = true

                    // Super simple demo behavior: keep existing placeholders unless text changes
                    if naturalInput.lowercased().contains("tomorrow") { parsedDate = "Tomorrow" }
                    if naturalInput.lowercased().contains("3") { parsedTime = "3:00 PM" }

                    if naturalInput.count > 8 {
                        parsedTitle = guessTitle(from: naturalInput)
                    }

                    parsedExtras = guessExtras(from: naturalInput)
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

            previewRow(label: "Title", value: didRunAI ? parsedTitle : "—")
            previewRow(label: "When", value: didRunAI ? "\(parsedDate) • \(parsedTime)" : "—")
            previewRow(label: "Reminder", value: didRunAI ? parsedReminder : "—")

            VStack(alignment: .leading, spacing: 8) {
                Text("Extra")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)

                if didRunAI && !parsedExtras.isEmpty {
                    FlowChips(items: parsedExtras)
                } else {
                    Text("—")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 2)

            Text("You’ll be able to edit anything before saving.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top, 2)
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

                HStack {
                    Stepper(value: $durationMinutes, in: 5...240, step: 5) {
                        Text("\(durationMinutes) min")
                            .font(.subheadline)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Priority")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)

                HStack(spacing: 10) {
                    ForEach(Priority.allCases) { p in
                        Button {
                            priority = p
                        } label: {
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
                // Placeholder: save later
            } label: {
                Text("Save")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(PrimaryPillButtonStyle())

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

    // MARK: - Tiny placeholder “AI” helpers

    private func guessTitle(from text: String) -> String {
        // naive: take up to the first comma or "and"
        let lowered = text
        let stops = [",", " and ", " then ", " so "]
        var cut = lowered
        for stop in stops {
            if let r = lowered.range(of: stop) {
                cut = String(lowered[..<r.lowerBound])
                break
            }
        }
        let trimmed = cut.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "New task" : trimmed
    }

    private func guessExtras(from text: String) -> [String] {
        let t = text.lowercased()
        var out: [String] = []
        if t.contains("charger") { out.append("Bring charger") }
        if t.contains("keys") { out.append("Grab keys") }
        if t.contains("water") || t.contains("bottle") { out.append("Bring water") }
        if t.contains("laptop") { out.append("Bring laptop") }
        return out
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
            // estimate chip width based on text length
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
                    ForEach(rows[r], id: \ .self) { item in
                        content(item)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

// MARK: - Button Styles (kept local so this page compiles even if other files change)

struct AButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.76, green: 0.70, blue: 0.95),
                        Color(red: 0.93, green: 0.62, blue: 0.82)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 6)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct OtherPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(Color(red: 0.39, green: 0.28, blue: 0.60))
            .background(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(Color.white.opacity(0.65))
                    .overlay(
                        RoundedRectangle(cornerRadius: 999, style: .continuous)
                            .stroke(Color.white.opacity(0.55), lineWidth: 1)
                    )
            )
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    AddTaskPage()
}
