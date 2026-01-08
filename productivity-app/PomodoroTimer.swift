//
//  PomodoroTimer.swift
//  productivity-app
//
//  Created by Audrey W-M on 1/8/26.
//

import SwiftUI

// MARK: - Pomodoro (Focus) Timer
// UI + local timer only (no notifications or persistence yet)

struct PomodoroTimerView: View {
    // MARK: Timer config
    @State private var focusMinutes: Int = 25
    @State private var breakMinutes: Int = 5

    // MARK: State
    @State private var phase: PomodoroPhase = .focus
    @State private var isRunning: Bool = false
    @State private var secondsRemaining: Int = 25 * 60
    @State private var completedFocusSessions: Int = 0

    @State private var showConfigSheet: Bool = false

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            PastelBGView()

            VStack(spacing: 14) {
                header

                ring

                controls

                footer

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 18)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Pomodoro")
                    .font(.headline)
                    .foregroundStyle(Palette.textPrimary)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showConfigSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
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
                .accessibilityLabel("Pomodoro settings")
            }
        }
        .onReceive(ticker) { _ in
            guard isRunning else { return }
            tick()
        }
        .onAppear {
            // Keep seconds aligned with current config on first load
            secondsRemaining = phase == .focus ? focusMinutes * 60 : breakMinutes * 60
        }
        .sheet(isPresented: $showConfigSheet) {
            PomodoroConfigSheet(
                focusMinutes: $focusMinutes,
                breakMinutes: $breakMinutes,
                onApply: {
                    applyConfig()
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - UI sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(phase.title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Palette.textPrimary)

            HStack(spacing: 10) {
                Image(systemName: phase.icon)
                    .foregroundStyle(phase.accent)

                Text(phase.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(2)

                Spacer()

                Text("\(completedFocusSessions) done")
                    .font(.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Palette.chip)
                    .clipShape(Capsule())
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

    private var ring: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Palette.strokeSoft, lineWidth: 14)
                    .opacity(0.75)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        phase.accent,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 6) {
                    Text(timeString(secondsRemaining))
                        .font(.system(size: 44, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.textPrimary)

                    Text(isRunning ? "Running" : "Paused")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.textSecondary)
                }
            }
            .frame(width: 260, height: 260)

            HStack(spacing: 10) {
                Text("Focus: \(focusMinutes)m")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Palette.chip)
                    .clipShape(Capsule())

                Text("Break: \(breakMinutes)m")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Palette.chip)
                    .clipShape(Capsule())
            }
        }
        .padding(.top, 6)
    }

    private var controls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    toggle()
                } label: {
                    HStack {
                        Spacer()
                        Label(isRunning ? "Pause" : "Start", systemImage: isRunning ? "pause.fill" : "play.fill")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 12)
                    .background(phase.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button {
                    skipPhase()
                } label: {
                    HStack {
                        Spacer()
                        Label("Skip", systemImage: "forward.fill")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                    }
                    .foregroundStyle(Palette.textPrimary)
                    .padding(.vertical, 12)
                    .background(Palette.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Palette.stroke, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }

            Button {
                reset()
            } label: {
                HStack {
                    Spacer()
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                }
                .foregroundStyle(Palette.textPrimary)
                .padding(.vertical, 12)
                .background(Palette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Palette.stroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Palette.accent)

                Text("Soon: AI will adjust your schedule if a focus block runs long.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(2)
            }

            HStack(spacing: 10) {
                Image(systemName: "bell.badge")
                    .foregroundStyle(Palette.mutedYellow)

                Text("Later we can add notifications + Live Activity.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(Palette.card)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Palette.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Logic

    private var totalSecondsForPhase: Int {
        phase == .focus ? focusMinutes * 60 : breakMinutes * 60
    }

    private var progress: CGFloat {
        let total = max(1, totalSecondsForPhase)
        let done = total - max(0, secondsRemaining)
        return CGFloat(done) / CGFloat(total)
    }

    private func toggle() {
        if secondsRemaining <= 0 {
            // If someone hits start at 0, advance first
            advancePhase()
        }
        isRunning.toggle()
    }

    private func reset() {
        isRunning = false
        secondsRemaining = totalSecondsForPhase
    }

    private func skipPhase() {
        isRunning = false
        advancePhase()
    }

    private func tick() {
        if secondsRemaining > 0 {
            secondsRemaining -= 1
        } else {
            isRunning = false
            advancePhase()
        }
    }

    private func advancePhase() {
        if phase == .focus {
            completedFocusSessions += 1
            phase = .breakTime
            secondsRemaining = breakMinutes * 60
        } else {
            phase = .focus
            secondsRemaining = focusMinutes * 60
        }
    }

    private func applyConfig() {
        // Keep it simple for now: apply immediately and reset the current phase clock.
        isRunning = false
        secondsRemaining = totalSecondsForPhase
    }

    private func timeString(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let m = s / 60
        let r = s % 60
        return String(format: "%02d:%02d", m, r)
    }
}

// MARK: - Config Sheet

private struct PomodoroConfigSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var focusMinutes: Int
    @Binding var breakMinutes: Int

    let onApply: () -> Void

    var body: some View {
        ZStack {
            PastelBGView()

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Timer settings")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Palette.textPrimary)

                    Spacer()

                    Button("Done") {
                        onApply()
                        dismiss()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.accent)
                }

                Text("Set your focus + break lengths. We'll add custom cycles later.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.textSecondary)

                VStack(spacing: 10) {
                    stepRow(title: "Focus", value: $focusMinutes, range: 5...90, step: 5, tint: Palette.lavender)
                    stepRow(title: "Break", value: $breakMinutes, range: 3...30, step: 1, tint: Palette.periwinkle)
                }

                Spacer(minLength: 0)

                Text("(No notifications yet — just in-app)")
                    .font(.caption)
                    .foregroundStyle(Palette.textTertiary)
            }
            .padding(16)
        }
    }

    private func stepRow(title: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int, tint: Color) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(tint)
                .frame(width: 10, height: 10)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.textPrimary)

            Spacer()

            Stepper("", value: value, in: range, step: step)
                .labelsHidden()

            Text("\(value.wrappedValue)m")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.textPrimary)
                .frame(width: 54, alignment: .trailing)
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

// MARK: - Models

private enum PomodoroPhase {
    case focus
    case breakTime

    var title: String {
        switch self {
        case .focus: return "Focus time"
        case .breakTime: return "Break time"
        }
    }

    var subtitle: String {
        switch self {
        case .focus: return "Phone down. One task. You’ve got this."
        case .breakTime: return "Reset your brain. Water, stretch, breathe."
        }
    }

    var icon: String {
        switch self {
        case .focus: return "target"
        case .breakTime: return "leaf.fill"
        }
    }

    var accent: Color {
        switch self {
        case .focus: return Palette.accent
        case .breakTime: return Palette.mutedYellow
        }
    }
}

// MARK: - Background + palette (same vibe as your other pages)

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
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PomodoroTimerView()
    }
}
