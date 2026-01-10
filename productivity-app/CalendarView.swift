//
//  CalendarView.swift
//  productivity-app
//
//  Created by Audrey W-M on 1/10/26.
//

import SwiftUI
import HorizonCalendar

// MARK: - CalendarView (HorizonCalendar + app theme)

struct CalendarView: View {
    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = .current
        c.timeZone = .current
        return c
    }()

    private let visibleDateRange: ClosedRange<Date>

    @State private var selectedDate: Date? = nil

    // MARK: - Placeholder planned items (swap with backend later)

    enum PlannedItemType: String {
        case event, task, reminder, focus

        var dotColor: Color {
            switch self {
            case .event: return AppTheme.accent
            case .task: return Color(red: 0.40, green: 0.60, blue: 0.95)
            case .reminder: return AppTheme.highlight
            case .focus: return Color(red: 0.58, green: 0.46, blue: 0.90)
            }
        }

        var label: String {
            switch self {
            case .event: return "Event"
            case .task: return "Task"
            case .reminder: return "Reminder"
            case .focus: return "Focus"
            }
        }

        var icon: String {
            switch self {
            case .event: return "calendar"
            case .task: return "checkmark.circle"
            case .reminder: return "bell"
            case .focus: return "timer"
            }
        }
    }

    struct PlannedItem: Identifiable {
        let id = UUID()
        let title: String
        let start: Date
        let end: Date
        let type: PlannedItemType

        var timeText: String {
            let df = DateFormatter()
            df.dateFormat = "h:mm a"
            return "\(df.string(from: start))–\(df.string(from: end))"
        }
    }

    @State private var showTimeBlocking: Bool = false

    // Demo data so the calendar looks alive even before backend.
    @State private var demoItems: [PlannedItem] = []

    init() {
        let now = Date()
        let start = Calendar.current.date(byAdding: .month, value: -6, to: now) ?? now
        let end = Calendar.current.date(byAdding: .month, value: 18, to: now) ?? now
        self.visibleDateRange = start...end

        // Demo items (remove when backend is ready)
        var tmp: [PlannedItem] = []
        let cal = Calendar.current
        func make(_ dayOffset: Int, _ sh: Int, _ sm: Int, _ eh: Int, _ em: Int, _ title: String, _ type: PlannedItemType) {
            guard let d = cal.date(byAdding: .day, value: dayOffset, to: now) else { return }
            let startDate = cal.date(bySettingHour: sh, minute: sm, second: 0, of: d) ?? d
            let endDate = cal.date(bySettingHour: eh, minute: em, second: 0, of: d) ?? d
            tmp.append(PlannedItem(title: title, start: startDate, end: endDate, type: type))
        }

        // A few days scattered around "now" so month view shows dots.
        make(0, 9, 0, 10, 30, "Deep work", .focus)
        make(0, 11, 0, 12, 15, "Class", .event)
        make(0, 15, 0, 15, 45, "Errands", .task)
        make(1, 10, 0, 10, 30, "Call w/ Maya", .event)
        make(2, 8, 30, 9, 0, "Drink water", .reminder)
        make(3, 13, 0, 14, 0, "Gym", .event)
        make(5, 16, 0, 16, 30, "Pick up meds", .task)
        make(8, 12, 0, 12, 30, "Lunch", .event)
        make(12, 9, 0, 11, 0, "Focus block", .focus)
        make(14, 14, 0, 14, 10, "Pay rent", .reminder)

        _demoItems = State(initialValue: tmp)
    }

    var body: some View {
        ZStack {
            PastelBlobBackground()

            VStack(spacing: 12) {
                NavigationLink(
                    destination: TimeBlockingView(initialDate: selectedDate ?? Date()),
                    isActive: $showTimeBlocking
                ) {
                    EmptyView()
                }
                .hidden()

                header

                // Minimal SwiftUI integration that compiles across HorizonCalendar versions.
                // If you want fully custom day cells (dots, pills, range highlight, etc.), we can add that next.
                CalendarViewRepresentable(
                    calendar: calendar,
                    visibleDateRange: visibleDateRange,
                    monthsLayout: .vertical(options: VerticalMonthsLayoutOptions()),
                    dataDependency: selectedDate
                )
                .days { [selectedDate] day in
                    let date = calendar.date(from: day.components)
                    let isSelected = (date != nil && date == selectedDate)

                    VStack(spacing: 6) {
                        Text("\(day.day)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isSelected ? Color.white : AppTheme.textPrimary)

                        // Dots like Apple Calendar (placeholder data for now)
                        let dots = dotTypes(for: date)
                        if !dots.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(dots.prefix(3), id: \.self) { t in
                                    Circle()
                                        .fill(t.dotColor)
                                        .frame(width: 5, height: 5)
                                }
                            }
                            .opacity(isSelected ? 0.95 : 0.85)
                        } else {
                            // Keep rows aligned even with no dots
                            Color.clear.frame(height: 5)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isSelected ? AppTheme.accent : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppTheme.accent.opacity(isSelected ? 0 : 0.35), lineWidth: 1)
                    )
                }
                .interMonthSpacing(24)
                .verticalDayMargin(8)
                .horizontalDayMargin(8)
                .layoutMargins(.init(top: 12, leading: 16, bottom: 16, trailing: 16))
                .onDaySelection { day in
                    selectedDate = calendar.date(from: day.components)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                )
                .padding(.horizontal, 16)

                selectedDayCard
            }
            .padding(.top, 12)
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppTheme.accent)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text("Schedule")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Tap a day to focus")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private var selectedDayCard: some View {
        let label: String = {
            guard let selectedDate else { return "No day selected" }
            let f = DateFormatter()
            f.locale = .current
            f.dateStyle = .full
            f.timeStyle = .none
            return f.string(from: selectedDate)
        }()

        let items = itemsForSelectedDay()

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Selected")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)

                    Text(label)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                Spacer()

                Button {
                    showTimeBlocking = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Time blocks")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(AppTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(selectedDate == nil)
                .opacity(selectedDate == nil ? 0.6 : 1)
            }

            Divider().opacity(0.5)

            if items.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.highlight)

                    Text("No items yet — this will populate once your backend is wired.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.vertical, 6)
            } else {
                VStack(spacing: 10) {
                    ForEach(items) { item in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(item.type.dotColor)
                                .frame(width: 10, height: 10)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppTheme.textPrimary)

                                Text("\(item.timeText) • \(item.type.label)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AppTheme.textSecondary.opacity(0.7))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.45))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppTheme.cardStroke.opacity(0.9), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }

    // MARK: - Helpers

    private func itemsForSelectedDay() -> [PlannedItem] {
        guard let selectedDate else { return [] }
        return items(for: selectedDate)
    }

    private func items(for date: Date) -> [PlannedItem] {
        demoItems
            .filter { calendar.isDate($0.start, inSameDayAs: date) }
            .sorted(by: { $0.start < $1.start })
    }

    private func dotTypes(for date: Date?) -> [PlannedItemType] {
        guard let date else { return [] }
        let types = items(for: date).map { $0.type }
        // Unique, stable order
        let order: [PlannedItemType] = [.event, .task, .reminder, .focus]
        return order.filter { types.contains($0) }
    }
}

// MARK: - AppTheme

private enum AppTheme {
    // Background (light, airy)
    static let backgroundTop = Color(red: 0.96, green: 0.95, blue: 1.00)
    static let backgroundBottom = Color(red: 0.92, green: 0.94, blue: 1.00)

    // Cards (white + soft stroke)
    static let card = Color.white.opacity(0.72)
    static let cardStroke = Color(red: 0.56, green: 0.46, blue: 0.86).opacity(0.14)

    // Text (dark, readable)
    static let textPrimary = Color(red: 0.16, green: 0.14, blue: 0.28)
    static let textSecondary = Color(red: 0.30, green: 0.28, blue: 0.44).opacity(0.85)

    // Accent (periwinkle / lavender)
    static let accent = Color(red: 0.52, green: 0.48, blue: 0.86)

    // Muted highlight (soft yellow)
    static let highlight = Color(red: 0.98, green: 0.90, blue: 0.62)

    // Blob colors
    static let blob1 = Color(red: 0.82, green: 0.73, blue: 0.97) // lavender
    static let blob2 = Color(red: 0.70, green: 0.80, blue: 0.99) // pale blue
    static let blob3 = Color(red: 0.95, green: 0.78, blue: 0.90) // soft pink-lilac
}

// MARK: - Background

private struct PastelBlobBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.backgroundTop, AppTheme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let x1 = CGFloat(sin(t * 0.14))
                let y1 = CGFloat(cos(t * 0.12))
                let x2 = CGFloat(cos(t * 0.10))
                let y2 = CGFloat(sin(t * 0.15))
                let x3 = CGFloat(sin(t * 0.09))
                let y3 = CGFloat(cos(t * 0.11))

                GeometryReader { proxy in
                    let w = proxy.size.width
                    let h = proxy.size.height

                    ZStack {
                        blob(color: AppTheme.blob1, size: w * 0.95)
                            .offset(x: -w * 0.18 + x1 * 24, y: -h * 0.35 + y1 * 22)

                        blob(color: AppTheme.blob2, size: w * 0.80)
                            .offset(x: w * 0.20 + x2 * 20, y: -h * 0.10 + y2 * 18)

                        blob(color: AppTheme.blob3, size: w * 0.90)
                            .offset(x: -w * 0.05 + x3 * 18, y: h * 0.28 + y3 * 20)
                    }
                }
            }
            .allowsHitTesting(false)
        }
    }

    private func blob(color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(color.opacity(0.38))
            .frame(width: size, height: size)
            .blur(radius: 70)
    }
}

#Preview {
    NavigationStack {
        CalendarView()
    }
}
