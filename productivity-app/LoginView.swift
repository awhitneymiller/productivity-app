//
//  LoginView.swift
//  productivity-app
//
//  Created by Audrey W-M on 1/8/26.
//

import SwiftUI

struct LoginView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
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

                // Soft accent blobs
                accentBlobs(in: geo.size)
                    .ignoresSafeArea()

                VStack(spacing: 18) {
                    Spacer()

                    // Title block
                    VStack(spacing: 10) {
                        Text("Smart Schedule")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.39, green: 0.28, blue: 0.60),
                                        Color(red: 0.76, green: 0.34, blue: 0.60)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("An AI-powered productivity app built for how real people live")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 26)
                    }
                    .padding(.top, 20)

                    // Feature bullets
                    VStack(alignment: .leading, spacing: 10) {
                        bulletRow(icon: "square.grid.2x2.fill", text: "All-in-one: tasks, calendar, reminders, notes")
                        bulletRow(icon: "arrow.2.squarepath", text: "Flexible scheduling that adapts when things run late")
                        bulletRow(icon: "brain.head.profile", text: "AI learns your timing and suggests better timeframes")
                        bulletRow(icon: "bell.badge.fill", text: "Smart reminders for real-world moments")
                    }
                    .padding(18)
                    .background(cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.45), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .padding(.horizontal, 18)

                    // Auth buttons
                    VStack(spacing: 12) {
                        Button {
                            // Placeholder: wire Sign in with Apple later
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "applelogo")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Continue with Apple")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(PrimaryPillButtonStyle())

                        Button {
                            // Placeholder: wire other options later
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Other options")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(SecondaryPillButtonStyle())

                        Text("By continuing, you agree to our Terms and Privacy Policy")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 18)
                            .padding(.top, 6)
                    }
                    .padding(.horizontal, 18)

                    Spacer(minLength: 26)
                }
                .frame(width: geo.size.width)
            }
        }
    }

    // MARK: - Pieces

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

    private func bulletRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(Color(red: 0.39, green: 0.28, blue: 0.60))
                .frame(width: 22)
                .padding(.top, 1)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }

    private var cardBackground: some ShapeStyle {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.70),
                Color.white.opacity(0.52)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Button Styles
struct PrimaryPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
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

struct SecondaryPillButtonStyle: ButtonStyle {
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
    LoginView()
}
