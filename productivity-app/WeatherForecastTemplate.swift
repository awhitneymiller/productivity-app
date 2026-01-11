//
//  HomePage.swift
//  productivity-app
//
//  Created by Audrey W-M on 1/8/26.
//

import SwiftUI

// MARK: - Focus Stats Store (placeholder)
// If you already have a FocusStatsStore elsewhere, delete this duplicate and
// import/use the existing one instead.
final class FocusStatsStore: ObservableObject {
    @Published var todayFocusMinutes: Int = 58
    @Published var focusPoints: Int = 12

    init() {}
}

struct HomePage: View {
    @EnvironmentObject private var auth: AuthManager

    @StateObject var focusStore = FocusStatsStore()
    @State private var showLogoutConfirm: Bool = false

    private let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 0.96, green: 0.94, blue: 0.99),
            Color(red: 0.92, green: 0.90, blue: 0.98)
        ]),
        startPoint: .top,
        endPoint: .bottom
    )

    @ViewBuilder
    private func quickLinkCell(for link: QuickLink) -> some View {
        switch link.title {
        case "Add Task":
            NavigationLink {
                AddTaskPage()
            } label: {
                QuickLinkButton(link: link)
            }
            .buttonStyle(.plain)

        case "Time Block":
            NavigationLink {
                TimeBlockingView()
            } label: {
                QuickLinkButton(link: link)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

        case "Calendar":
            NavigationLink {
                CalendarView()
            } label: {
                QuickLinkButton(link: link)
            }
            .buttonStyle(.plain)

        case "Pomodoro", "Focus":
            NavigationLink {
                PomodoroTimerView()
                    .environmentObject(focusStore)
            } label: {
                QuickLinkButton(link: link)
            }
            .buttonStyle(.plain)

        case "Reminders":
            NavigationLink {
                RemindersView()
            } label: {
                QuickLinkButton(link: link)
            }
            .buttonStyle(.plain)

        case "Insights":
            NavigationLink {
                WrappedView()
            } label: {
                QuickLinkButton(link: link)
            }
            .buttonStyle(.plain)

        default:
            Button {
                // Placeholder: wire actions later
            } label: {
                QuickLinkButton(link: link)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func overviewCell(for item: OverviewItem) -> some View {
        if item.title == "Focus" {
            NavigationLink {
                PomodoroTimerView()
                    .environmentObject(focusStore)
            } label: {
                OverviewRow(item: item)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else if item.title == "Schedule" {
            NavigationLink {
                CalendarView()
            } label: {
                OverviewRow(item: item)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            OverviewRow(item: item)
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    HomeHeaderCard()
                        .padding(.horizontal)
                        .padding(.top, 16)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Links")
                            .font(.headline)
                            .padding(.horizontal)

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(minimum: 160), spacing: 14),
                                GridItem(.flexible(minimum: 160), spacing: 14)
                            ],
                            spacing: 14
                        ) {
                            ForEach(quickLinks) { link in
                                quickLinkCell(for: link)
                            }
                        }
                        .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Today's Overview")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            ForEach(overviewItems) { item in
                                overviewCell(for: item)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showLogoutConfirm = true
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .imageScale(.medium)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.39, green: 0.28, blue: 0.60),
                                        Color(red: 0.76, green: 0.34, blue: 0.60)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .accessibilityLabel("Log Out")
                }
            }
            .alert("Log out?", isPresented: $showLogoutConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Log Out", role: .destructive) {
                    auth.signOut()
                }
            } message: {
                Text("You can log back in any time.")
            }
            .background(backgroundGradient.ignoresSafeArea())
        }
    }
}


// MARK: - Header Card
struct HomeHeaderCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.76, green: 0.70, blue: 0.95),
                            Color(red: 0.93, green: 0.62, blue: 0.82)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Day")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Thu • 10:30 AM")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.white)
                            Text("3 tasks done")
                                .font(.headline)
                                .foregroundColor(.white)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .foregroundColor(.white.opacity(0.95))
                            Text("Next: Study block at 2:00 PM")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Image(systemName: "cloud.sun.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)

                    Text("72°")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Partly Cloudy")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            .padding(22)
        }
        .frame(height: 170)
    }
}

// MARK: - Quick Links
struct QuickLink: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
}

let quickLinks: [QuickLink] = [
    .init(title: "Add Task", subtitle: "Quick capture", icon: "plus.circle.fill"),
    .init(title: "Time\u{00A0}Block", subtitle: "Plan your day", icon: "clock.fill"),
    .init(title: "Calendar", subtitle: "See your month", icon: "calendar"),
    .init(title: "Pomodoro", subtitle: "Focus timer", icon: "timer"),
    .init(title: "Reminders", subtitle: "Don’t forget", icon: "bell.fill"),
    .init(title: "Notes", subtitle: "In-context", icon: "note.text"),
    .init(title: "Checklists", subtitle: "Small wins", icon: "checklist"),
    .init(title: "Insights", subtitle: "Your stats", icon: "chart.bar.fill")
]

struct QuickLinkButton: View {
    let link: QuickLink

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.7))

                Image(systemName: link.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.39, green: 0.28, blue: 0.60))
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(link.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                    .multilineTextAlignment(.leading)

                Text(link.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .multilineTextAlignment(.leading)
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .frame(height: 74)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.75))
        )
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.76, green: 0.70, blue: 0.95).opacity(0.25),
                            Color(red: 0.93, green: 0.62, blue: 0.82).opacity(0.25)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blur(radius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 0.5)
        )
        .shadow(color: Color(red: 0.76, green: 0.70, blue: 0.95).opacity(0.25), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Today's Overview
struct OverviewItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let detail: String
    let icon: String
}

let overviewItems: [OverviewItem] = [
    .init(title: "Tasks", value: "3 / 8", detail: "You’re on track", icon: "checkmark.circle.fill"),
    .init(title: "Focus", value: "58 min", detail: "Best block: 10:00 AM", icon: "timer"),
    .init(title: "Schedule", value: "4 blocks", detail: "1 flexible block left", icon: "calendar.badge.clock"),
    .init(title: "Reminders", value: "2", detail: "Next: grab charger", icon: "bell.badge.fill")
]

struct OverviewRow: View {
    let item: OverviewItem

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.6))

                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.39, green: 0.28, blue: 0.60))
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.headline)

                Text(item.detail)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(item.value)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground).opacity(0.7))
        )
    }
}

#Preview {
    HomePage()
        .environmentObject(AuthManager())
}
