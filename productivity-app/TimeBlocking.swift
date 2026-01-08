//
//  TimeBlocking.swift
//  productivity-app
//
//  Created by Audrey W-M on 1/8/26.
//

import SwiftUI

// MARK: - Time Blocking (UI only / placeholders)

struct TimeBlockingView: View {
    @State private var selectedDate: Date = .now
    @State private var autoShiftEnabled: Bool = true
    @State private var showingAddBlock: Bool = false
    @State private var showingLateSheet: Bool = false
    @State private var lastShiftMinutes: Int = 0
    @State private var preShiftBlocks: [TimeBlock] = []

    // Placeholder blocks (we'll wire real data later)
    @State private var blocks: [TimeBlock] = [
        TimeBlock(title: "Deep work", note: "Finish HW + project", startHour: 9, startMinute: 0, endHour: 10, endMinute: 30, kind: .focus),
        TimeBlock(title: "Class", note: "CMSI lecture", startHour: 11, startMinute: 0, endHour: 12, endMinute: 15, kind: .event),
        TimeBlock(title: "Lunch", note: "Quick reset", startHour: 12, startMinute: 30, endHour: 13, endMinute: 0, kind: .breakTime),
        TimeBlock(title: "Errands", note: "Grab keys + charger", startHour: 15, startMinute: 0, endHour: 15, endMinute: 45, kind: .task)
    ]

    private let hours: [Int] = Array(6...22)

    var body: some View {
        ZStack {
            PastelBGView()

            VStack(spacing: 14) {
                header

                controlsRow

                timeline
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 18)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Time Blocking")
                    .font(.headline)
                    .foregroundStyle(Palette.textPrimary)
            }

            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingLateSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.system(size: 14, weight: .semibold))
                        Text("I'm late")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Palette.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Palette.stroke, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityLabel("Adjust schedule for being late")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddBlock = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Palette.textPrimary)
                        .padding(10)
                        .background(Palette.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Palette.stroke, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityLabel("Add time block")
            }
        }
        .sheet(isPresented: $showingAddBlock) {
            AddBlockSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingLateSheet) {
            LateAdjustSheet(
                onApply: { minutes in
                    applyLateShift(minutes: minutes)
                },
                onCancel: {
                    showingLateSheet = false
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Plan your day in blocks")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Palette.textPrimary)

            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Palette.accent)

                Text("AI can auto-shift blocks when things run late")
                    .font(.subheadline)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(2)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Palette.card)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Palette.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))

            if lastShiftMinutes > 0 {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(Palette.accent)

                    Text("Adjusted: +\(lastShiftMinutes) min")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.textPrimary)

                    Spacer()

                    Button("Undo") {
                        if !preShiftBlocks.isEmpty {
                            blocks = preShiftBlocks
                        }
                        lastShiftMinutes = 0
                        preShiftBlocks = []
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.accent)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Palette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Palette.stroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    // MARK: - Free / manual adjustment ("I'm late")

    private func applyLateShift(minutes: Int) {
        let delta = max(0, minutes)
        guard delta > 0 else { return }

        // Snapshot for undo
        preShiftBlocks = blocks
        lastShiftMinutes = delta

        // Shift only upcoming blocks (based on current time). If everything is in the past,
        // shift the last block and after (which effectively shifts none).
        let now = Date()
        let cal = Calendar.current
        let nowHour = cal.component(.hour, from: now)
        let nowMinute = cal.component(.minute, from: now)
        let nowTotal = nowHour * 60 + nowMinute

        let sorted = blocks.sorted(by: { $0.startTotalMinutes < $1.startTotalMinutes })

        // Find first block that hasn't ended yet
        let firstIndexToShift: Int = {
            if let idx = sorted.firstIndex(where: { $0.endTotalMinutes > nowTotal }) {
                return idx
            }
            return sorted.count // nothing upcoming
        }()

        // Build a shifted copy
        var shifted: [UUID: TimeBlock] = [:]

        for (i, b) in sorted.enumerated() {
            if i < firstIndexToShift {
                shifted[b.id] = b
            } else {
                var nb = b
                let start = b.startTotalMinutes + delta
                let end = b.endTotalMinutes + delta
                nb.startHour = max(0, min(23, start / 60))
                nb.startMinute = max(0, min(59, start % 60))
                nb.endHour = max(0, min(23, end / 60))
                nb.endMinute = max(0, min(59, end % 60))
                shifted[b.id] = nb
            }
        }

        // Apply back in original order so the UI doesn't jump
        blocks = blocks.map { shifted[$0.id] ?? $0 }

        // Close sheet if it's open
        showingLateSheet = false
    }

    // MARK: - Controls

    private var controlsRow: some View {
        HStack(spacing: 12) {
            DatePill(date: selectedDate) {
                // Placeholder: we can later show a real date picker or calendar.
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            } onRightTap: {
                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
            }

            Toggle(isOn: $autoShiftEnabled) {
                Text("Auto-shift")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.textPrimary)
            }
            .toggleStyle(SwitchToggleStyle(tint: Palette.accent))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Palette.card)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Palette.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Timeline

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today’s schedule")
                    .font(.headline)
                    .foregroundStyle(Palette.textPrimary)

                Spacer()

                Text("\(blocks.count) blocks")
                    .font(.subheadline)
                    .foregroundStyle(Palette.textSecondary)
            }

            ScrollView {
                LazyVStack(spacing: 12) {
                    // Visual timeline
                    TimelineCard(hours: hours, blocks: blocks)

                    // List view
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(blocks.sorted(by: { $0.startTotalMinutes < $1.startTotalMinutes })) { block in
                            BlockRow(block: block)
                        }
                    }
                }
                .padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)
        }
    }
}

// MARK: - Timeline visual card

private struct TimelineCard: View {
    let hours: [Int]
    let blocks: [TimeBlock]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(Palette.accent)

                Text("Timeline")
                    .font(.headline)
                    .foregroundStyle(Palette.textPrimary)

                Spacer()

                Text("UI preview")
                    .font(.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Palette.chip)
                    .clipShape(Capsule())
            }

            VStack(spacing: 10) {
                ForEach(hours, id: \.self) { hour in
                    HourRow(hour: hour, blocks: blocks)
                }
            }
        }
        .padding(14)
        .background(Palette.card)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Palette.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct HourRow: View {
    let hour: Int
    let blocks: [TimeBlock]

    private var hourLabel: String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let ampm = hour < 12 ? "AM" : "PM"
        return "\(h) \(ampm)"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(hourLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.textSecondary)
                .frame(width: 54, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                Divider().opacity(0.5)

                // Show any blocks that start within this hour
                ForEach(blocksStartingThisHour) { block in
                    TimelineMiniBlock(block: block)
                }

                // Subtle empty space
                RoundedRectangle(cornerRadius: 10)
                    .fill(Palette.fillSoft)
                    .frame(height: blocksStartingThisHour.isEmpty ? 22 : 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Palette.strokeSoft, lineWidth: 1)
                    )
            }
        }
    }

    private var blocksStartingThisHour: [TimeBlock] {
        blocks.filter { $0.startHour == hour }
            .sorted(by: { $0.startTotalMinutes < $1.startTotalMinutes })
    }
}

private struct TimelineMiniBlock: View {
    let block: TimeBlock

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(block.kind.color)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(block.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.textPrimary)

                Text("\(block.timeRangeText)  •  \(block.durationText)")
                    .font(.caption)
                    .foregroundStyle(Palette.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(block.kind.cardTint)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Palette.strokeSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Block list row

private struct BlockRow: View {
    let block: TimeBlock

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(block.title)
                        .font(.headline)
                        .foregroundStyle(Palette.textPrimary)

                    Text(block.kind.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Palette.chip)
                        .clipShape(Capsule())
                }

                Text(block.note)
                    .font(.subheadline)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(2)

                Text("\(block.timeRangeText) • \(block.durationText)")
                    .font(.caption)
                    .foregroundStyle(Palette.textSecondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Palette.textTertiary)
        }
        .padding(14)
        .background(Palette.card)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Palette.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Date pill

private struct DatePill: View {
    let date: Date
    let onLeftTap: () -> Void
    let onRightTap: () -> Void

    private var title: String {
        let df = DateFormatter()
        df.dateFormat = "EEE, MMM d"
        return df.string(from: date)
    }

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onLeftTap) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
            }

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.textPrimary)

            Button(action: onRightTap) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Palette.card)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Palette.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Add Block sheet (placeholder)

private struct AddBlockSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var input: String = "Block out 2 hours for deep work tomorrow at 10, remind me 10 min before"

    var body: some View {
        ZStack {
            PastelBGView()

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Add a block")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Palette.textPrimary)

                    Spacer()

                    Button("Done") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.accent)
                }

                Text("Type naturally. Later we’ll parse this into a block, reminder, and notes.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.textSecondary)

                TextEditor(text: $input)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .frame(minHeight: 130)
                    .background(Palette.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Palette.stroke, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(Palette.textPrimary)

                HStack(spacing: 10) {
                    Button {
                        // Placeholder: voice capture later
                    } label: {
                        Label("Speak", systemImage: "mic.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Palette.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Palette.chip)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Spacer()

                    Button {
                        // Placeholder: AI parse later
                    } label: {
                        Label("Preview", systemImage: "sparkles")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Palette.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                Spacer(minLength: 0)

                Text("(Not wired yet — just UI)")
                    .font(.caption)
                    .foregroundStyle(Palette.textTertiary)
            }
            .padding(16)
        }
    }
}

// MARK: - Models

private struct TimeBlock: Identifiable {
    let id: UUID
    var title: String
    var note: String
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var kind: BlockKind

    init(id: UUID = UUID(), title: String, note: String, startHour: Int, startMinute: Int, endHour: Int, endMinute: Int, kind: BlockKind) {
        self.id = id
        self.title = title
        self.note = note
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.kind = kind
    }

    var startTotalMinutes: Int { startHour * 60 + startMinute }
    var endTotalMinutes: Int { endHour * 60 + endMinute }

    var durationText: String {
        let mins = max(0, endTotalMinutes - startTotalMinutes)
        let h = mins / 60
        let m = mins % 60
        if h == 0 { return "\(m) min" }
        if m == 0 { return "\(h) hr" }
        return "\(h) hr \(m) min"
    }

    var timeRangeText: String {
        "\(formatTime(hour: startHour, minute: startMinute))–\(formatTime(hour: endHour, minute: endMinute))"
    }

    private func formatTime(hour: Int, minute: Int) -> String {
        let isAM = hour < 12
        let h = hour % 12 == 0 ? 12 : hour % 12
        let ampm = isAM ? "AM" : "PM"
        return String(format: "%d:%02d %@", h, minute, ampm)
    }
}

private enum BlockKind: String, CaseIterable {
    case focus
    case task
    case event
    case breakTime

    var label: String {
        switch self {
        case .focus: return "Focus"
        case .task: return "Task"
        case .event: return "Event"
        case .breakTime: return "Break"
        }
    }

    var color: Color {
        switch self {
        case .focus: return Palette.lavender
        case .task: return Palette.periwinkle
        case .event: return Palette.blue
        case .breakTime: return Palette.mutedYellow
        }
    }

    var cardTint: Color {
        color.opacity(0.18)
    }
}

// MARK: - Background + palette

private struct PastelBGView: View {
    var body: some View {
        LinearGradient(
            colors: [Palette.bgTop, Palette.bgBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(
            ZStack {
                Circle()
                    .fill(Palette.lavender.opacity(0.22))
                    .frame(width: 280, height: 280)
                    .blur(radius: 6)
                    .offset(x: -120, y: -220)

                Circle()
                    .fill(Palette.periwinkle.opacity(0.18))
                    .frame(width: 320, height: 320)
                    .blur(radius: 8)
                    .offset(x: 140, y: -140)

                Circle()
                    .fill(Palette.blue.opacity(0.14))
                    .frame(width: 360, height: 360)
                    .blur(radius: 10)
                    .offset(x: 40, y: 220)
            }
        )
    }
}

private enum Palette {
    // Background
    static let bgTop = Color(red: 0.93, green: 0.92, blue: 0.98)       // light lavender
    static let bgBottom = Color(red: 0.90, green: 0.94, blue: 0.99)    // pale blue

    // Cards
    static let card = Color.white.opacity(0.60)
    static let chip = Color.white.opacity(0.45)

    // Strokes
    static let stroke = Color.white.opacity(0.55)
    static let strokeSoft = Color.white.opacity(0.40)

    // Text
    static let textPrimary = Color(red: 0.14, green: 0.13, blue: 0.22)
    static let textSecondary = Color(red: 0.30, green: 0.29, blue: 0.44)
    static let textTertiary = Color(red: 0.42, green: 0.41, blue: 0.56)

    // Accents
    static let lavender = Color(red: 0.73, green: 0.67, blue: 0.95)
    static let periwinkle = Color(red: 0.63, green: 0.74, blue: 0.98)
    static let blue = Color(red: 0.62, green: 0.84, blue: 0.98)
    static let accent = Color(red: 0.56, green: 0.48, blue: 0.90) // gentle purple

    // Highlights
    static let mutedYellow = Color(red: 0.95, green: 0.87, blue: 0.55)

    // Fills
    static let fillSoft = Color.white.opacity(0.28)
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TimeBlockingView()
    }
}


// MARK: - Late adjust sheet (free/manual)

private struct LateAdjustSheet: View {
    let onApply: (Int) -> Void
    let onCancel: () -> Void

    @State private var minutesLate: Int = 10

    private let presets: [Int] = [5, 10, 15, 30, 45, 60]

    var body: some View {
        ZStack {
            PastelBGView()

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Running late")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Palette.textPrimary)

                    Spacer()

                    Button("Close") { onCancel() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.accent)
                }

                Text("Free mode: tell us how late you are and we’ll shift the rest of your day.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.textSecondary)

                HStack(spacing: 10) {
                    Text("Minutes")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.textPrimary)

                    Spacer()

                    Stepper("", value: $minutesLate, in: 0...240, step: 5)
                        .labelsHidden()

                    Text("\(minutesLate)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.textPrimary)
                        .frame(width: 44, alignment: .trailing)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Palette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Palette.stroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 10) {
                    Text("Quick picks")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.textPrimary)

                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(presets, id: \.self) { p in
                                Button {
                                    minutesLate = p
                                } label: {
                                    Text("+\(p)")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Palette.textPrimary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(Palette.chip)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Palette.strokeSoft, lineWidth: 1)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .scrollIndicators(.hidden)
                }

                Button {
                    onApply(minutesLate)
                } label: {
                    HStack {
                        Spacer()
                        Label("Shift schedule", systemImage: "arrow.triangle.2.circlepath")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 12)
                    .background(Palette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Text("This keeps block lengths the same. AI auto-adjust comes later.")
                    .font(.caption)
                    .foregroundStyle(Palette.textTertiary)

                Spacer(minLength: 0)
            }
            .padding(16)
        }
    }
}
