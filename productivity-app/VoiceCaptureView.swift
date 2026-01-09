//
//  VoiceCaptureView.swift
//  productivity-app
//
//  Created by Audrey W-M on 1/9/26.
//


//
//  VoiceCaptureView.swift
//  productivity-app
//
//  Created by Audrey W-M on 1/9/26.
//

import SwiftUI

struct VoiceCaptureView: View {
    // MARK: - Voice Transcription
    @StateObject private var transcriber = VoiceTranscriber()

    // MARK: - UI State
    @State private var showParsed: Bool = false

    // Parsed preview placeholders
    @State private var parsedTitle: String = "Meeting with Maya"
    @State private var parsedWhen: String = "Tomorrow • 3:00 PM"
    @State private var parsedReminder: String = "Remind 30 min before"
    @State private var parsedNotes: String = "Bring my charger"

    var body: some View {
        ZStack {
            PastelBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    header

                    statusPill

                    transcriptCard

                    if showParsed {
                        parsedPreviewCard
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .navigationTitle("Voice Input")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Speak naturally")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.88))

            Text("Say something like: \"Meeting with Maya tomorrow at 3, remind me 30 minutes before, bring my charger.\"")
                .font(.subheadline)
                .foregroundStyle(Color.black.opacity(0.62))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Status
    private var statusPill: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(transcriber.isRecording ? Color(red: 1.0, green: 0.42, blue: 0.62) : Color.black.opacity(0.18))
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(Color.black.opacity(0.10), lineWidth: 1)
                )

            Text(transcriber.isRecording ? "Listening…" : "Ready")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.78))

            Spacer()

            Text(transcriber.status)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.45))

            if !transcriber.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("\(transcriber.transcript.count) chars")
                    .font(.caption)
                    .foregroundStyle(Color.black.opacity(0.40))
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.70))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Transcript
    private var transcriptCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Transcript")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.black.opacity(0.80))

                Spacer()

                Button {
                    transcriber.transcript = ""
                    showParsed = false
                } label: {
                    Text("Clear")
                        .font(.footnote.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.black.opacity(0.55))
                .disabled(transcriber.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(transcriber.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.35 : 1)
            }

            ZStack(alignment: .topLeading) {
                if transcriber.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Your words will appear here…")
                        .font(.subheadline)
                        .foregroundStyle(Color.black.opacity(0.35))
                        .padding(.top, 6)
                }

                TextEditor(text: $transcriber.transcript)
                    .scrollContentBackground(.hidden)
                    .font(.subheadline)
                    .foregroundStyle(Color.black.opacity(0.78))
                    .frame(minHeight: 140, maxHeight: 260)
            }
            .padding(12)
            .background(Color.white.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )

            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.footnote)
                    .foregroundStyle(Color.black.opacity(0.35))

                Text("We’ll turn this into tasks, reminders, notes, and time blocks.")
                    .font(.footnote)
                    .foregroundStyle(Color.black.opacity(0.45))

                Spacer()
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.10), radius: 18, x: 0, y: 10)
    }

    // MARK: - Parsed Preview
    private var parsedPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Parsed Preview")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.black.opacity(0.80))

                Spacer()

                Text("Preview")
                    .font(.caption.weight(.semibold))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.white.opacity(0.75))
                    .clipShape(Capsule())
                    .foregroundStyle(Color.black.opacity(0.45))
            }

            previewRow(icon: "checklist", title: "Title", value: parsedTitle)
            previewRow(icon: "calendar", title: "When", value: parsedWhen)
            previewRow(icon: "bell", title: "Reminder", value: parsedReminder)
            previewRow(icon: "note.text", title: "Notes", value: parsedNotes)

            Divider().overlay(Color.black.opacity(0.08))

            Text("You’ll be able to edit before saving.")
                .font(.footnote)
                .foregroundStyle(Color.black.opacity(0.45))
        }
        .padding(14)
        .background(Color.white.opacity(0.70))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.10), radius: 18, x: 0, y: 10)
    }

    private func previewRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.black.opacity(0.40))
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.black.opacity(0.45))

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.black.opacity(0.80))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button {
                    if transcriber.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // seed an example so the UI feels alive
                        transcriber.transcript = "Meeting with Maya tomorrow at 3, remind me 30 minutes before, bring my charger"
                    }
                    showParsed = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "wand.and.stars")
                        Text("Parse")
                            .font(.headline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .tint(Color.white.opacity(0.12))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )

                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                        transcriber.toggle()
                    }

                    // Hide parsed preview when starting a new recording session
                    if transcriber.isRecording {
                        showParsed = false
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: transcriber.isRecording ? "stop.fill" : "mic.fill")
                        Text(transcriber.isRecording ? "Stop" : "Record")
                            .font(.headline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.62, green: 0.60, blue: 0.98))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.16), radius: 16, x: 0, y: 10)
            }

            Text("Free version: tap Record, then Parse. Later, voice + AI will auto-create everything.")
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.55))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.20)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

// MARK: - Background
private struct PastelBackground: View {
    @State private var drift: Bool = false

    var body: some View {
        ZStack {
            // soft base gradient (pastel, light but more color)
            LinearGradient(
                colors: [
                    Color(red: 0.92, green: 0.95, blue: 1.00),   // airy pale blue
                    Color(red: 0.93, green: 0.90, blue: 1.00),   // pale lavender
                    Color(red: 0.90, green: 0.95, blue: 0.98)    // soft minty blue
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height

                // soft blobs
                Blob()
                    .fill(Color(red: 0.62, green: 0.60, blue: 0.98).opacity(0.40))
                    .frame(width: w * 3.85, height: w * 0.70)
                    .blur(radius: 0.5)
                    .offset(x: drift ? -w * 0.18 : -w * 0.08, y: drift ? -h * 0.36 : -h * 0.30)
                    .rotationEffect(.degrees(drift ? -8 : -14))

                Blob()
                    .fill(Color(red: 0.52, green: 0.68, blue: 0.98).opacity(0.28))
                    .frame(width: w * 0.78, height: w * 0.90)
                    .blur(radius: 0.8)
                    .offset(x: drift ? w * 0.18 : w * 0.26, y: drift ? -h * 0.06 : -h * 0.12)
                    .rotationEffect(.degrees(drift ? 18 : 10))

                Blob()
                    .fill(Color(red: 0.94, green: 0.86, blue: 0.55).opacity(0.10))
                    .frame(width: w * 0.70, height: w * 0.55)
                    .blur(radius: 1.2)
                    .offset(x: drift ? w * 0.15 : -w * 0.22, y: drift ? h * 0.30 : h * 0.36)
                    .rotationEffect(.degrees(drift ? -10 : -2))
            }
            .allowsHitTesting(false)

            // subtle vignette
            RadialGradient(
                colors: [
                    Color.black.opacity(0.00),
                    Color.black.opacity(0.18)
                ],
                center: .center,
                startRadius: 120,
                endRadius: 520
            )
            .blendMode(.multiply)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                drift.toggle()
            }
        }
    }
}

private struct Blob: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height

        p.move(to: CGPoint(x: 0.55 * w, y: 0.05 * h))
        p.addCurve(
            to: CGPoint(x: 0.95 * w, y: 0.35 * h),
            control1: CGPoint(x: 0.78 * w, y: 0.02 * h),
            control2: CGPoint(x: 0.98 * w, y: 0.16 * h)
        )
        p.addCurve(
            to: CGPoint(x: 0.76 * w, y: 0.90 * h),
            control1: CGPoint(x: 0.98 * w, y: 0.62 * h),
            control2: CGPoint(x: 0.90 * w, y: 0.88 * h)
        )
        p.addCurve(
            to: CGPoint(x: 0.18 * w, y: 0.78 * h),
            control1: CGPoint(x: 0.62 * w, y: 0.92 * h),
            control2: CGPoint(x: 0.34 * w, y: 0.98 * h)
        )
        p.addCurve(
            to: CGPoint(x: 0.10 * w, y: 0.28 * h),
            control1: CGPoint(x: 0.02 * w, y: 0.58 * h),
            control2: CGPoint(x: 0.02 * w, y: 0.36 * h)
        )
        p.addCurve(
            to: CGPoint(x: 0.55 * w, y: 0.05 * h),
            control1: CGPoint(x: 0.18 * w, y: 0.16 * h),
            control2: CGPoint(x: 0.35 * w, y: 0.08 * h)
        )

        p.closeSubpath()
        return p
    }
}

#Preview {
    NavigationStack {
        VoiceCaptureView()
    }
}
