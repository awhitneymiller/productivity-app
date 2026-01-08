//
//  OnboardingPage.swift
//  productivity-app
//
//  Created by Audrey W-M on 1/8/26.
//

import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let image: String
    let title: String
    let description: String
}

struct OnboardingFlowTemplate: View {
    @State private var currentPage = 0
    @State private var isOnboardingComplete = false

    // Aligned to the app goals: all-in-one, flexible scheduling, AI time learning, smart reminders, easy input.
    private let onboardingPages = [
        OnboardingPage(
            image: "square.grid.2x2.fill",
            title: "Everything in one place",
            description: "To-dos, calendar, time blocks, reminders, alarms, and notes—so you’re not juggling apps all day."
        ),
        OnboardingPage(
            image: "arrow.triangle.2.circlepath",
            title: "Plans that flex with your day",
            description: "When something runs late, your schedule shifts with it so one delay doesn’t ruin everything."
        ),
        OnboardingPage(
            image: "brain.head.profile",
            title: "Smarter timing over time",
            description: "AI learns how long things actually take you and suggests more realistic time blocks."
        ),
        OnboardingPage(
            image: "bell.badge.fill",
            title: "Reminders that help you follow through",
            description: "Get prompts at the right moment—like “grab your charger” or “start getting ready now”—so details don’t slip."
        ),
        OnboardingPage(
            image: "mic.fill",
            title: "Just say it or type it",
            description: "Tell it what’s going on (“meeting tomorrow at 3, bring laptop”) and it turns it into tasks, reminders, and notes."
        )
    ]

    var body: some View {
        Group {
            if isOnboardingComplete {
                ContentPlaceholderView()
            } else {
                onboardingView
            }
        }
    }

    private var onboardingView: some View {
        ZStack {
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

            accentBlobs
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            isOnboardingComplete = true
                        }
                    }) {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.39, green: 0.28, blue: 0.60))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 999, style: .continuous)
                                    .fill(Color.white.opacity(0.65))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 999, style: .continuous)
                                            .stroke(Color.white.opacity(0.55), lineWidth: 1)
                                    )
                            )
                            .padding()
                    }
                }

                TabView(selection: $currentPage) {
                    ForEach(onboardingPages.indices, id: \.self) { index in
                        VStack(spacing: 20) {
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

                                Image(systemName: onboardingPages[index].image)
                                    .font(.system(size: 64, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 160, height: 160)
                            .padding(.top, 8)

                            VStack(spacing: 10) {
                                Text(onboardingPages[index].title)
                                    .font(.system(size: 26, weight: .bold, design: .rounded))
                                    .multilineTextAlignment(.center)

                                Text(onboardingPages[index].description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 14)
                            }
                            .padding(18)
                            .background(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.70),
                                                Color.white.opacity(0.52)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                                            .stroke(Color.white.opacity(0.45), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 18)

                            Spacer(minLength: 0)
                        }
                        .padding(.bottom, 10)
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                VStack(spacing: 18) {
                    HStack(spacing: 8) {
                        ForEach(0..<onboardingPages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color(red: 0.76, green: 0.70, blue: 0.95) : Color.white.opacity(0.55))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == currentPage ? 1.2 : 1.0)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    .padding(.top, 6)

                    Button(action: {
                        withAnimation {
                            if currentPage < onboardingPages.count - 1 {
                                currentPage += 1
                            } else {
                                isOnboardingComplete = true
                            }
                        }
                    }) {
                        Text(currentPage < onboardingPages.count - 1 ? "Continue" : "Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(OnboardingPrimaryPillButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
    }

    private var accentBlobs: some View {
        GeometryReader { proxy in
            let size = proxy.size
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
    }
}

struct ContentPlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("You’re all set!")
                .font(.title)
                .fontWeight(.bold)

            Text("Let’s plan your day in one place.")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}


struct OnboardingPrimaryPillButtonStyle: ButtonStyle {
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

#Preview {
    OnboardingFlowTemplate()
}
