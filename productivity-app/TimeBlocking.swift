//
//  TimeBlocking.swift
//  productivity-app
//
//  Created by Audrey W-M on 1/8/26.
//

import SwiftUI

// MARK: - 1. Networking & Logic (ViewModel)

@MainActor
class TimeBlockingViewModel: ObservableObject {
    @Published var blocks: [TimeBlock] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // RENAMED to avoid conflict with CalendarView's BackendTask
    private var allBackendTasks: [TBBackendTask] = []
    
    func fetchTasks(for date: Date) async {
        // 👇 Ensuring Port 5001
        guard let url = URL(string: "http://127.0.0.1:5001/api/tasks") else { return }
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            self.errorMessage = "Not logged in"
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                self.errorMessage = "Session expired"
                self.isLoading = false
                return
            }
            
            // Decode using the UNIQUE struct names
            let decoded = try JSONDecoder().decode(TBTaskResponse.self, from: data)
            self.allBackendTasks = decoded.tasks
            
            // Filter and Map for the selected date
            self.updateBlocks(for: date)
            
            self.isLoading = false
        } catch {
            print("Fetch error: \(error)")
            self.errorMessage = "Could not load tasks"
            self.isLoading = false
        }
    }
    
    func updateBlocks(for date: Date) {
        let calendar = Calendar.current
        
        // 1. Filter tasks belonging to the selected date
        let daysTasks = allBackendTasks.filter { task in
            // Parse YYYY-MM-DD
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            if let taskDate = df.date(from: task.due_date) {
                return calendar.isDate(taskDate, inSameDayAs: date)
            }
            return false
        }
        
        // 2. Map to TimeBlock
        self.blocks = daysTasks.compactMap { task in
            return mapTaskToBlock(task, on: date)
        }
    }
    
    // 👇 FIXED DATE PARSING LOGIC HERE
    private func mapTaskToBlock(_ task: TBBackendTask, on date: Date) -> TimeBlock? {
        let calendar = Calendar.current
        var startHour = 9
        var startMinute = 0
        
        // 1. Define Formatters
        
        // Format A: Matches your error logs ("2026-01-10T13:33:00")
        let standardIsoNoTz = DateFormatter()
        standardIsoNoTz.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        standardIsoNoTz.locale = Locale(identifier: "en_US_POSIX")
        
        // Format B: Matches the weird colon format ("2026-01-10 17:07:00:000000")
        let complexPython = DateFormatter()
        complexPython.dateFormat = "yyyy-MM-dd HH:mm:ss:SSSSSS"
        complexPython.locale = Locale(identifier: "en_US_POSIX")
        
        if let dueAtStr = task.due_at {
            var parsedDate: Date? = nil
            
            // Try Format A
            parsedDate = standardIsoNoTz.date(from: dueAtStr)
            
            // Try Format B
            if parsedDate == nil {
                parsedDate = complexPython.date(from: dueAtStr)
            }
            
            // Try Standard ISO
            if parsedDate == nil {
                let iso = ISO8601DateFormatter()
                iso.formatOptions = [.withInternetDateTime]
                parsedDate = iso.date(from: dueAtStr)
            }
            
            if let d = parsedDate {
                startHour = calendar.component(.hour, from: d)
                startMinute = calendar.component(.minute, from: d)
            } else {
                print("⚠️ TimeBlocking: Failed to parse date string: \(dueAtStr)")
            }
        }
        
        // 2. Calculate End Time
        let startTotal = startHour * 60 + startMinute
        let endTotal = startTotal + task.duration_minutes
        
        let endHour = (endTotal / 60) % 24
        let endMinute = endTotal % 60
        
        // 3. Map Priority
        var kind: TBBlockKind = .task
        let p = task.priority.lowercased()
        
        if p == "high" { kind = .focus }
        else if (task.tags ?? "").contains("class") { kind = .event }
        else if (task.tags ?? "").contains("break") { kind = .breakTime }
        
        return TimeBlock(
            id: UUID(),
            title: task.title,
            note: task.notes ?? "",
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute,
            kind: kind
        )
    }
}

// MARK: - Unique Decoding Structs

private struct TBTaskResponse: Decodable {
    let tasks: [TBBackendTask]
}

private struct TBBackendTask: Decodable {
    let id: Int
    let title: String
    let due_date: String
    let due_at: String?
    let duration_minutes: Int
    let priority: String
    let tags: String?
    let notes: String?
}

// MARK: - 2. Time Blocking View

struct TimeBlockingView: View {
    @StateObject private var viewModel = TimeBlockingViewModel()
    @StateObject private var learning = TBTimeLearningStore()
    
    @State private var selectedDate: Date
    @State private var autoShiftEnabled: Bool = true
    @State private var showingAddBlock: Bool = false
    @State private var showingLateSheet: Bool = false
    @State private var lastShiftMinutes: Int = 0
    @State private var preShiftBlocks: [TimeBlock] = []

    @State private var showingLogActualSheet: Bool = false
    @State private var logBlockID: UUID? = nil
    @State private var logActualMinutes: Int = 0
    @State private var editingBlock: TimeBlock? = nil

    private let hours: [Int] = Array(6...22)

    init(initialDate: Date = .now) {
        _selectedDate = State(initialValue: initialDate)
    }

    var body: some View {
        ZStack {
            PastelBGView()

            VStack(spacing: 14) {
                header
                controlsRow
                
                if viewModel.isLoading {
                    ProgressView("Loading schedule...")
                        .padding(.top, 40)
                    Spacer()
                } else if viewModel.blocks.isEmpty {
                    emptyState
                } else {
                    timeline
                }
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
                Button { showingLateSheet = true } label: {
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
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.stroke, lineWidth: 1))
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAddBlock = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Palette.textPrimary)
                        .padding(10)
                        .background(Palette.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.stroke, lineWidth: 1))
                }
            }
        }
        .task(id: selectedDate) {
            await viewModel.fetchTasks(for: selectedDate)
        }
        .sheet(isPresented: $showingAddBlock) {
            AddBlockSheet().presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingLateSheet) {
            LateAdjustSheet(
                onApply: { minutes in applyLateShift(minutes: minutes) },
                onCancel: { showingLateSheet = false }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingLogActualSheet) {
            LogActualSheet(
                title: logBlockTitle,
                plannedMinutes: logPlannedMinutes,
                actualMinutes: $logActualMinutes,
                onSave: { saveLogActual() },
                onCancel: { showingLogActualSheet = false }
            )
            .presentationDetents([.medium])
        }
    }

    // MARK: - Subviews

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
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.stroke, lineWidth: 1))

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
                            viewModel.blocks = preShiftBlocks
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
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.stroke, lineWidth: 1))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(Palette.accent.opacity(0.6))
            Text("No tasks scheduled for this day.")
                .font(.headline)
                .foregroundStyle(Palette.textSecondary)
            Text("Add tasks in the main calendar view to see them here.")
                .font(.caption)
                .foregroundStyle(Palette.textTertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    private var controlsRow: some View {
        HStack(spacing: 12) {
            DatePill(date: selectedDate) {
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
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.stroke, lineWidth: 1))
        }
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today’s schedule")
                    .font(.headline)
                    .foregroundStyle(Palette.textPrimary)
                Spacer()
                Text("\(viewModel.blocks.count) blocks")
                    .font(.subheadline)
                    .foregroundStyle(Palette.textSecondary)
            }

            ScrollView {
                LazyVStack(spacing: 12) {
                    TimelineCard(hours: hours, blocks: viewModel.blocks) { tapped in
                       // Editing logic to be wired up
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.blocks.sorted(by: { $0.startTotalMinutes < $1.startTotalMinutes })) { block in
                            BlockRow(
                                block: block,
                                suggestedMinutes: suggestedMinutes(for: block),
                                onApplySuggestion: { applySuggestedDuration(for: block.id) },
                                onLogActual: { beginLogActual(for: block) },
                                onTap: { /* Edit block */ }
                            )
                        }
                    }
                }
                .padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Logic (Shift, AI, Logging)

    private func applyLateShift(minutes: Int) {
        let delta = max(0, minutes)
        guard delta > 0 else { return }

        // Snapshot for undo
        preShiftBlocks = viewModel.blocks
        lastShiftMinutes = delta

        let now = Date()
        let cal = Calendar.current
        let nowHour = cal.component(.hour, from: now)
        let nowMinute = cal.component(.minute, from: now)
        let nowTotal = nowHour * 60 + nowMinute

        let sorted = viewModel.blocks.sorted(by: { $0.startTotalMinutes < $1.startTotalMinutes })

        let firstIndexToShift: Int = {
            if let idx = sorted.firstIndex(where: { $0.endTotalMinutes > nowTotal }) {
                return idx
            }
            return sorted.count
        }()

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
        viewModel.blocks = viewModel.blocks.map { shifted[$0.id] ?? $0 }
        showingLateSheet = false
    }

    private func suggestedMinutes(for block: TimeBlock) -> Int? {
        guard block.kind == .task || block.kind == .focus else { return nil }
        guard let predicted = learning.predictedMinutes(forKey: block.learnKey) else { return nil }
        let planned = block.plannedMinutes
        if abs(predicted - planned) < 5 { return nil }
        return predicted
    }

    private func applySuggestedDuration(for id: UUID) {
        guard let idx = viewModel.blocks.firstIndex(where: { $0.id == id }) else { return }
        guard let suggested = suggestedMinutes(for: viewModel.blocks[idx]) else { return }
        
        var b = viewModel.blocks[idx]
        let start = b.startTotalMinutes
        let end = start + suggested
        b.endHour = max(0, min(23, end / 60))
        b.endMinute = max(0, min(59, end % 60))
        viewModel.blocks[idx] = b
    }

    private func beginLogActual(for block: TimeBlock) {
        logBlockID = block.id
        logActualMinutes = max(1, block.plannedMinutes)
        showingLogActualSheet = true
    }

    private var logBlockTitle: String {
        guard let id = logBlockID, let b = viewModel.blocks.first(where: { $0.id == id }) else { return "" }
        return b.title
    }

    private var logPlannedMinutes: Int {
        guard let id = logBlockID, let b = viewModel.blocks.first(where: { $0.id == id }) else { return 0 }
        return b.plannedMinutes
    }

    private func saveLogActual() {
        guard let id = logBlockID, let b = viewModel.blocks.first(where: { $0.id == id }) else {
            showingLogActualSheet = false
            return
        }
        learning.recordCompletion(key: b.learnKey, actualMinutes: logActualMinutes)
        showingLogActualSheet = false
    }
}

// MARK: - Models & Helpers

struct TimeBlock: Identifiable {
    let id: UUID
    var title: String
    var note: String
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var kind: TBBlockKind
    
    var learnKey: String { title.tbNormalizedLearnKey() }
    var plannedMinutes: Int { max(0, endTotalMinutes - startTotalMinutes) }
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

enum TBBlockKind: String, CaseIterable {
    case focus, task, event, breakTime
    
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
    
    var cardTint: Color { color.opacity(0.18) }
}

private extension String {
    func tbNormalizedLearnKey() -> String {
        let lower = self.lowercased()
        let allowed = lower.filter { $0.isLetter || $0.isNumber || $0 == " " }
        return allowed.split(separator: " ").joined(separator: " ")
    }
}

// MARK: - Timeline Components

private struct TimelineCard: View {
    let hours: [Int]
    let blocks: [TimeBlock]
    let onTapBlock: (TimeBlock) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(Palette.accent)
                Text("Timeline")
                    .font(.headline)
                    .foregroundStyle(Palette.textPrimary)
                Spacer()
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Palette.chip)
                    .clipShape(Capsule())
            }
            VStack(spacing: 10) {
                ForEach(hours, id: \.self) { hour in
                    HourRow(hour: hour, blocks: blocks, onTapBlock: onTapBlock)
                }
            }
        }
        .padding(14)
        .background(Palette.card)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.stroke, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct HourRow: View {
    let hour: Int
    let blocks: [TimeBlock]
    let onTapBlock: (TimeBlock) -> Void
    
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
                ForEach(blocksStartingThisHour) { block in
                    TimelineMiniBlock(block: block) { onTapBlock(block) }
                }
                RoundedRectangle(cornerRadius: 10)
                    .fill(Palette.fillSoft)
                    .frame(height: blocksStartingThisHour.isEmpty ? 22 : 10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Palette.strokeSoft, lineWidth: 1))
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
    let onTap: () -> Void
    
    var body: some View {
        Button { onTap() } label: {
            HStack(spacing: 10) {
                Circle().fill(block.kind.color).frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 2) {
                    Text(block.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.textPrimary)
                    Text("\(block.timeRangeText) • \(block.durationText)")
                        .font(.caption)
                        .foregroundStyle(Palette.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(block.kind.cardTint)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.strokeSoft, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

private struct BlockRow: View {
    let block: TimeBlock
    let suggestedMinutes: Int?
    let onApplySuggestion: () -> Void
    let onLogActual: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button { onTap() } label: {
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
                    if !block.note.isEmpty {
                        Text(block.note)
                            .font(.subheadline)
                            .foregroundStyle(Palette.textSecondary)
                            .lineLimit(2)
                    }
                    HStack(spacing: 8) {
                        Text("\(block.timeRangeText) • \(block.durationText)")
                            .font(.caption)
                            .foregroundStyle(Palette.textSecondary)
                        if let s = suggestedMinutes {
                            Text("Suggested: \(formatMinutes(s))")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Palette.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Palette.chip)
                                .clipShape(Capsule())
                        }
                    }
                    if suggestedMinutes != nil {
                        Button { onApplySuggestion() } label: {
                            Label("Apply suggestion", systemImage: "wand.and.stars")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Palette.accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Palette.card)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.strokeSoft, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
            Menu {
                Button { onLogActual() } label: { Label("Log actual time", systemImage: "checkmark.circle") }
                if suggestedMinutes != nil {
                    Button { onApplySuggestion() } label: { Label("Apply suggested duration", systemImage: "wand.and.stars") }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Palette.textTertiary)
                    .padding(10)
                    .background(Palette.chip)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(14)
        .background(Palette.card)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.stroke, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18))
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

// MARK: - Date Pill & Add Sheet & Sheets

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
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.stroke, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct AddBlockSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var input: String = "Block out 2 hours for deep work tomorrow at 10..."
    
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
                Text("Type naturally. Later we’ll parse this into a block.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.textSecondary)
                TextEditor(text: $input)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .frame(minHeight: 130)
                    .background(Palette.card)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.stroke, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(Palette.textPrimary)
                Spacer(minLength: 0)
            }
            .padding(16)
        }
    }
}

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
                Text("Shift the rest of your day.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.textSecondary)
                
                HStack {
                    Text("Minutes: \(minutesLate)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.textPrimary)
                    Spacer()
                    Stepper("", value: $minutesLate, in: 0...240, step: 5).labelsHidden()
                }
                
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(presets, id: \.self) { p in
                            Button("+\(p)") { minutesLate = p }
                                .padding(10)
                                .background(Palette.chip)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(Palette.textPrimary)
                        }
                    }
                }
                
                Button { onApply(minutesLate) } label: {
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
                Spacer(minLength: 0)
            }
            .padding(16)
        }
    }
}

private struct LogActualSheet: View {
    let title: String
    let plannedMinutes: Int
    @Binding var actualMinutes: Int
    let onSave: () -> Void
    let onCancel: () -> Void
    private let presets: [Int] = [10, 15, 20, 30, 45, 60]
    
    var body: some View {
        ZStack {
            PastelBGView()
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Log time")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Palette.textPrimary)
                    Spacer()
                    Button("Close") { onCancel() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.accent)
                }
                Text(title).font(.headline).foregroundStyle(Palette.textPrimary)
                Text("Planned: \(plannedMinutes) min").font(.subheadline).foregroundStyle(Palette.textSecondary)
                
                HStack {
                    Text("Actual: \(actualMinutes)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.textPrimary)
                    Spacer()
                    Stepper("", value: $actualMinutes, in: 1...480, step: 5).labelsHidden()
                }
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(presets, id: \.self) { p in
                            Button("\(p)") { actualMinutes = p }
                                .padding(10)
                                .background(Palette.chip)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(Palette.textPrimary)
                        }
                    }
                }
                Button { onSave() } label: {
                    HStack {
                        Spacer()
                        Label("Save", systemImage: "checkmark")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 12)
                    .background(Palette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                Spacer(minLength: 0)
            }
            .padding(16)
        }
    }
}

// MARK: - Styles & Stores

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
                Circle().fill(Palette.lavender.opacity(0.22)).frame(width: 280).blur(radius: 6).offset(x: -120, y: -220)
                Circle().fill(Palette.periwinkle.opacity(0.18)).frame(width: 320).blur(radius: 8).offset(x: 140, y: -140)
            }
        )
    }
}

private enum Palette {
    static let bgTop = Color(red: 0.93, green: 0.92, blue: 0.98)
    static let bgBottom = Color(red: 0.90, green: 0.94, blue: 0.99)
    static let card = Color.white.opacity(0.60)
    static let chip = Color.white.opacity(0.45)
    static let stroke = Color.white.opacity(0.55)
    static let strokeSoft = Color.white.opacity(0.40)
    static let textPrimary = Color(red: 0.14, green: 0.13, blue: 0.22)
    static let textSecondary = Color(red: 0.30, green: 0.29, blue: 0.44)
    static let textTertiary = Color(red: 0.42, green: 0.41, blue: 0.56)
    static let lavender = Color(red: 0.73, green: 0.67, blue: 0.95)
    static let periwinkle = Color(red: 0.63, green: 0.74, blue: 0.98)
    static let blue = Color(red: 0.62, green: 0.84, blue: 0.98)
    static let accent = Color(red: 0.56, green: 0.48, blue: 0.90)
    static let mutedYellow = Color(red: 0.95, green: 0.87, blue: 0.55)
    static let fillSoft = Color.white.opacity(0.28)
}

@MainActor
private final class TBTimeLearningStore: ObservableObject {
    @Published private(set) var stats: [String: TBLearnStats] = [:]
    private let defaultsKey = "time_learning_stats_v1"
    init() { load() }
    func predictedMinutes(forKey rawKey: String) -> Int? {
        let key = rawKey.tbNormalizedLearnKey()
        guard let s = stats[key], s.samples > 0 else { return nil }
        return max(5, Int(round(s.ewmaMinutes)))
    }
    func recordCompletion(key rawKey: String, actualMinutes: Int, alpha: Double = 0.25) {
        let key = rawKey.tbNormalizedLearnKey()
        let actual = Double(max(1, actualMinutes))
        if var s = stats[key] {
            s.ewmaMinutes = alpha * actual + (1.0 - alpha) * s.ewmaMinutes
            s.samples += 1
            s.lastUpdated = Date()
            stats[key] = s
        } else {
            stats[key] = TBLearnStats(ewmaMinutes: actual, samples: 1, lastUpdated: Date())
        }
        save()
    }
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return }
        do { stats = try JSONDecoder().decode([String: TBLearnStats].self, from: data) } catch { stats = [:] }
    }
    private func save() {
        do { let data = try JSONEncoder().encode(stats); UserDefaults.standard.set(data, forKey: defaultsKey) } catch {}
    }
}

private struct TBLearnStats: Codable {
    var ewmaMinutes: Double; var samples: Int; var lastUpdated: Date
}

#Preview {
    NavigationStack {
        TimeBlockingView(initialDate: Date())
    }
}
