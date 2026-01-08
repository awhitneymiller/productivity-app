//
//  RemindersView.swift
//  productivity-app
//
//  Created by Audrey W-M on 1/8/26.
//

import SwiftUI
import UIKit

// MARK: - Models
struct ReminderItem: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var dueDate: Date?
    var notes: String
    var isCompleted: Bool
    
    var dueLabel: String? {
        guard let dueDate = dueDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: dueDate)
    }
}

// MARK: - View
struct RemindersView: View {
    init() {
        // List background (UITableView)
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
        UITableView.appearance().separatorStyle = .none
        let bgView = UIView()
        bgView.backgroundColor = .clear
        UITableView.appearance().backgroundView = bgView

        // Transparent navigation bar so the gradient/blobs show behind it
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
    
    @State private var reminders: [ReminderItem] = [
        .init(title: "Bring charger", dueDate: Calendar.current.date(byAdding: .hour, value: 2, to: Date()), notes: "For study group", isCompleted: false),
        .init(title: "Water plants", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()), notes: "", isCompleted: false),
        .init(title: "Email professor", dueDate: nil, notes: "Ask about extension", isCompleted: true)
    ]

    @State private var showAdd = false
    @State private var newTitle: String = ""
    @State private var newNotes: String = ""
    @State private var newHasDate: Bool = false
    @State private var newDate: Date = Date()

    // MARK: - Background drift
    @State private var driftA: CGSize = .zero
    @State private var driftB: CGSize = .zero
    @State private var driftC: CGSize = .zero

    var body: some View {
        ZStack {
            // Soft themed background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.96, green: 0.94, blue: 0.99),
                    Color(red: 0.92, green: 0.90, blue: 0.98)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Decorative blobs (behind the list)
            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height

                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.14))
                        .frame(width: 280, height: 280)
                        .blur(radius: 70)
                        .position(x: w * 0.18, y: h * 0.18)
                        .offset(driftA)

                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 240, height: 240)
                        .blur(radius: 70)
                        .position(x: w * 0.86, y: h * 0.22)
                        .offset(driftB)

                    Circle()
                        .fill(Color.yellow.opacity(0.11))
                        .frame(width: 260, height: 260)
                        .blur(radius: 80)
                        .position(x: w * 0.55, y: h * 0.82)
                        .offset(driftC)
                }
                .allowsHitTesting(false)
            }
            .ignoresSafeArea()

            NavigationView {
                List {
                    Section(header: Text("Upcoming")) {
                        ForEach(reminders.filter { !$0.isCompleted }) { item in
                            ReminderRow(item: binding(for: item))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        }
                        .onDelete(perform: delete)
                    }

                    Section(header: Text("Completed")) {
                        ForEach(reminders.filter { $0.isCompleted }) { item in
                            ReminderRow(item: binding(for: item))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        }
                        .onDelete(perform: delete)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .onAppear {
                    // Make sure the system table background stays transparent
                    UITableView.appearance().backgroundColor = .clear
                    UITableViewCell.appearance().backgroundColor = .clear
                }
                .navigationTitle("Reminders")
                .toolbarBackground(.clear, for: .navigationBar)
                .toolbarBackground(.clear, for: .navigationBar, .tabBar)
                .toolbarColorScheme(.light, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showAdd = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .background(Color.clear)
            .navigationViewStyle(.stack)
        }
        .sheet(isPresented: $showAdd) {
            addSheet
        }
        .onAppear {
            // Gentle drifting motion (loops forever)
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                driftA = CGSize(width: 18, height: -14)
            }
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                driftB = CGSize(width: -16, height: 12)
            }
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                driftC = CGSize(width: 10, height: -18)
            }
        }
    }

    // MARK: - Add Sheet
    private var addSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Title")) {
                    TextField("What do you need to remember?", text: $newTitle)
                }

                Section(header: Text("Notes")) {
                    TextField("Optional", text: $newNotes)
                }

                Section(header: Text("Due")) {
                    Toggle("Add date", isOn: $newHasDate)
                    if newHasDate {
                        DatePicker("When", selection: $newDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle("New Reminder")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        clearDraft()
                        showAdd = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addReminder()
                        showAdd = false
                    }
                    .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    // MARK: - Helpers
    private func binding(for item: ReminderItem) -> Binding<ReminderItem> {
        guard let index = reminders.firstIndex(of: item) else {
            return .constant(item)
        }
        return $reminders[index]
    }

    private func delete(at offsets: IndexSet) {
        let visible = reminders
        let idsToDelete = offsets.map { visible[$0].id }
        reminders.removeAll { idsToDelete.contains($0.id) }
    }

    private func addReminder() {
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let notes = newNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        let item = ReminderItem(
            title: title,
            dueDate: newHasDate ? newDate : nil,
            notes: notes,
            isCompleted: false
        )
        reminders.insert(item, at: 0)
        clearDraft()
    }

    private func clearDraft() {
        newTitle = ""
        newNotes = ""
        newHasDate = false
        newDate = Date()
    }
}

// MARK: - Row
struct ReminderRow: View {
    @Binding var item: ReminderItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                item.isCompleted.toggle()
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isCompleted ? .purple : Color.purple.opacity(0.35))
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .strikethrough(item.isCompleted)
                    .font(.body.weight(.semibold))
                    .foregroundColor(Color.black.opacity(item.isCompleted ? 0.45 : 0.85))

                if let due = item.dueLabel {
                    Text(due)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color.purple.opacity(0.8))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.55)))
                        .overlay(Capsule().stroke(Color.purple.opacity(0.15), lineWidth: 1))
                }

                if !item.notes.isEmpty {
                    Text(item.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(Color.black.opacity(0.18))
                .padding(.top, 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.purple.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
        .padding(.vertical, 6)
    }
}

// MARK: - Preview
struct RemindersView_Previews: PreviewProvider {
    static var previews: some View {
        RemindersView()
    }
}
