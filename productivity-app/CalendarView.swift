//
//  CalendarView.swift
//  productivity-app
//
//  Created by Audrey W-M on 1/10/26.
//

import SwiftUI
import HorizonCalendar

// MARK: - 1. Data Models (Renamed to avoid conflict)

// Matches the JSON response from Flask
struct CalBackendTask: Decodable {
    let id: Int
    let title: String
    let due_date: String      // "YYYY-MM-DD"
    let due_at: String?       // ISO string or null
    let duration_minutes: Int
    let priority: String
    let tags: String?
    let notes: String?
}

// The API Response Wrapper
struct CalTaskResponse: Decodable {
    let tasks: [CalBackendTask]
}

// MARK: - 2. View Model (Networking Logic)

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var items: [CalendarView.PlannedItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    func fetchTasks() async {
        guard let url = URL(string: "http://127.0.0.1:5001/api/tasks") else { return }
        
        // Check if token exists
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            self.errorMessage = "Not logged in"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                // 👇 HANDLE 401 SPECIFICALLY
                if httpResponse.statusCode == 401 {
                    print("❌ DEBUG: Token expired. Logging out...")
                    
                    // 1. Delete the invalid token so we don't use it again
                    UserDefaults.standard.removeObject(forKey: "authToken")
                    UserDefaults.standard.removeObject(forKey: "userEmail")
                    
                    await MainActor.run {
                        self.errorMessage = "Session expired. Please re-login."
                        self.isLoading = false
                    }
                    return // Stop here! Don't try to decode.
                }
            }
            
            // Decode only if successful
            let decoded = try JSONDecoder().decode(CalTaskResponse.self, from: data)
            await MainActor.run {
                self.items = decoded.tasks.map { mapBackendToUI($0) }
                self.isLoading = false
            }
        } catch {
            print("Error: \(error)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    // Mapper: Converts Flask Data -> UI Data
    // In CalendarView.swift -> CalendarViewModel
    private func mapBackendToUI(_ task: CalBackendTask) -> CalendarView.PlannedItem {
        let calendar = Calendar.current
        
        // 1. Define Formatters
        
        // Format A: Matches your error logs ("2026-01-10T13:33:00")
        let standardIsoNoTz = DateFormatter()
        standardIsoNoTz.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        standardIsoNoTz.locale = Locale(identifier: "en_US_POSIX")
        
        // Format B: Matches the weird colon format seen earlier ("2026-01-10 17:07:00:000000")
        let complexPython = DateFormatter()
        complexPython.dateFormat = "yyyy-MM-dd HH:mm:ss:SSSSSS"
        complexPython.locale = Locale(identifier: "en_US_POSIX")
        
        // Format C: Day only fallback
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        
        // Determine Start Date
        var startDate: Date
        
        if let dueAtStr = task.due_at {
            // Try parsing in order of likelihood based on your logs
            if let date = standardIsoNoTz.date(from: dueAtStr) {
                startDate = date
            } else if let date = complexPython.date(from: dueAtStr) {
                startDate = date
            } else {
                // Last resort: ISO8601 parser
                let iso = ISO8601DateFormatter()
                iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                startDate = iso.date(from: dueAtStr) ?? Date()
                if startDate == Date() { print("⚠️ DEBUG: Failed to parse time string: \(dueAtStr)") }
            }
        }
        else if let date = dayFormatter.date(from: task.due_date) {
            // Default to 9:00 AM if no time set
            startDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
        } else {
            startDate = Date()
        }
        
        // Determine End Date
        let endDate = startDate.addingTimeInterval(TimeInterval(task.duration_minutes * 60))
        
        // Map Priority
        var type: CalendarView.PlannedItemType = .task
        let p = task.priority.lowercased()
        if p == "high" { type = .focus }
        else if p == "medium" { type = .event }
        else if (task.tags ?? "").contains("personal") { type = .reminder }
        
        return CalendarView.PlannedItem(
            title: task.title,
            start: startDate,
            end: endDate,
            type: type
        )
    }
}

// MARK: - 3. The Calendar View

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    
    // Horizon Configuration
    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = .current
        c.timeZone = .current
        return c
    }()
    
    private let visibleDateRange: ClosedRange<Date>
    @State private var selectedDate: Date? = Date() // Default to today

    // UI Definitions
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
    
    init() {
        let now = Date()
        let start = Calendar.current.date(byAdding: .month, value: -6, to: now) ?? now
        let end = Calendar.current.date(byAdding: .month, value: 18, to: now) ?? now
        self.visibleDateRange = start...end
    }
    
    var body: some View {
        ZStack {
            PastelBlobBackground()
            
            VStack(spacing: 12) {
                // 👇 FIXED: Correct Navigation Destination
                NavigationLink(
                    destination: TimeBlockingView(initialDate: selectedDate ?? Date()),
                    isActive: $showTimeBlocking
                ) { EmptyView() }.hidden()
                
                header
                
                // MARK: Calendar Representable
                CalendarViewRepresentable(
                    calendar: calendar,
                    visibleDateRange: visibleDateRange,
                    monthsLayout: .vertical(options: VerticalMonthsLayoutOptions()),
                    dataDependency: CreateDataDependency(selectedDate: selectedDate, items: viewModel.items)
                )
                .days { [selectedDate] day in
                    let date = calendar.date(from: day.components)
                    let isSelected = (date != nil && selectedDate != nil && calendar.isDate(date!, inSameDayAs: selectedDate!))
                    
                    VStack(spacing: 6) {
                        Text("\(day.day)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(isSelected ? Color.white : AppTheme.textPrimary)
                        
                        // Dots Logic
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
        .task {
            // Fetch data when view appears
            await viewModel.fetchTasks()
        }
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Schedule")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                
                if viewModel.isLoading {
                    Text("Syncing...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                } else {
                    Text("Tap a day to focus")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            
            Spacer()
            
            // Refresh Button
            Button {
                Task { await viewModel.fetchTasks() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .foregroundStyle(AppTheme.textSecondary)
            }
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
            f.dateStyle = .full
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
                        Text("Time blocks")
                    }
                    .font(.system(size: 14, weight: .semibold))
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
                        .foregroundStyle(AppTheme.highlight)
                    Text("No tasks due this day.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.vertical, 6)
            } else {
                ScrollView {
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
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.45))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(AppTheme.cardStroke.opacity(0.9), lineWidth: 1)
                            )
                        }
                    }
                }
                .frame(maxHeight: 200) // Limit height so calendar doesn't squish too much
            }
        }
        .padding(18)
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
    
    // Struct to force calendar redraw when data changes
    struct CreateDataDependency: Equatable {
        let selectedDate: Date?
        let items: [PlannedItem]
        
        static func == (lhs: CreateDataDependency, rhs: CreateDataDependency) -> Bool {
            return lhs.selectedDate == rhs.selectedDate && lhs.items.count == rhs.items.count
        }
    }
    
    private func itemsForSelectedDay() -> [PlannedItem] {
        guard let selectedDate else { return [] }
        return items(for: selectedDate)
    }
    
    private func items(for date: Date?) -> [PlannedItem] {
        guard let date else { return [] }
        return viewModel.items
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

// MARK: - Theme & Background (Unchanged)

private enum AppTheme {
    static let backgroundTop = Color(red: 0.96, green: 0.95, blue: 1.00)
    static let backgroundBottom = Color(red: 0.92, green: 0.94, blue: 1.00)
    static let card = Color.white.opacity(0.72)
    static let cardStroke = Color(red: 0.56, green: 0.46, blue: 0.86).opacity(0.14)
    static let textPrimary = Color(red: 0.16, green: 0.14, blue: 0.28)
    static let textSecondary = Color(red: 0.30, green: 0.28, blue: 0.44).opacity(0.85)
    static let accent = Color(red: 0.52, green: 0.48, blue: 0.86)
    static let highlight = Color(red: 0.98, green: 0.90, blue: 0.62)
    static let blob1 = Color(red: 0.82, green: 0.73, blue: 0.97)
    static let blob2 = Color(red: 0.70, green: 0.80, blue: 0.99)
    static let blob3 = Color(red: 0.95, green: 0.78, blue: 0.90)
}

private struct PastelBlobBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.backgroundTop, AppTheme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
            
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let x1 = CGFloat(sin(t * 0.14)); let y1 = CGFloat(cos(t * 0.12))
                let x2 = CGFloat(cos(t * 0.10)); let y2 = CGFloat(sin(t * 0.15))
                
                GeometryReader { proxy in
                    let w = proxy.size.width
                    let h = proxy.size.height
                    ZStack {
                        blob(color: AppTheme.blob1, size: w * 0.95)
                            .offset(x: -w * 0.18 + x1 * 24, y: -h * 0.35 + y1 * 22)
                        blob(color: AppTheme.blob2, size: w * 0.80)
                            .offset(x: w * 0.20 + x2 * 20, y: -h * 0.10 + y2 * 18)
                    }
                }
            }.allowsHitTesting(false)
        }
    }
    
    func blob(color: Color, size: CGFloat) -> some View {
        Circle().fill(color.opacity(0.38)).frame(width: size, height: size).blur(radius: 70)
    }
}

#Preview {
    CalendarView()
}

