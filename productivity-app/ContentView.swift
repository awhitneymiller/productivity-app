//
//  ContentView.swift
//  productivity-app
//
//  Created by Audrey W-M on 1/8/26.
//

import SwiftUI

/// Single entry point for the app UI.
/// Simple gating so the simulator runs:
/// - Onboarding (first launch)
/// - Login (placeholder until auth is wired)
/// - Main tabs (Home, Add, Time Blocking, Reminders, Focus)
struct AppRootView: View {
    @AppStorage("didCompleteOnboarding") private var didCompleteOnboarding: Bool = false
    @EnvironmentObject private var auth: AuthManager

    var body: some View {
        ZStack {
            AppBackground()

            if !didCompleteOnboarding {
                OnboardingContainer {
                    didCompleteOnboarding = true
                }
            } else if !auth.isAuthenticated {
                LoginContainer()
            } else {
                MainTabShell(onSignOut: {
                    auth.signOut()
                })
            }
        }
    }
}

// MARK: - Background

struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.93, green: 0.94, blue: 0.99),
                Color(red: 0.90, green: 0.88, blue: 0.98),
                Color(red: 0.92, green: 0.95, blue: 1.00)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(
            ZStack {
                Circle()
                    .fill(Color(red: 0.78, green: 0.78, blue: 0.98).opacity(0.35))
                    .frame(width: 320, height: 320)
                    .blur(radius: 30)
                    .offset(x: -140, y: -220)

                Circle()
                    .fill(Color(red: 0.72, green: 0.86, blue: 0.99).opacity(0.35))
                    .frame(width: 360, height: 360)
                    .blur(radius: 34)
                    .offset(x: 150, y: 240)

                Circle()
                    .fill(Color(red: 0.86, green: 0.78, blue: 0.96).opacity(0.25))
                    .frame(width: 260, height: 260)
                    .blur(radius: 28)
                    .offset(x: 120, y: -10)
            }
        )
    }
}

// MARK: - Onboarding

struct OnboardingContainer: View {
    let onFinish: () -> Void

    var body: some View {
        NavigationStack {
            OnboardingFlowTemplate()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Skip") { onFinish() }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Button(action: onFinish) {
                        Text("Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(red: 0.62, green: 0.65, blue: 0.96))
                            )
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)
                }
        }
    }
}

// MARK: - Login

struct LoginContainer: View {
    var body: some View {
        NavigationStack {
            LoginView()
        }
    }
}

// MARK: - Main Tabs

struct MainTabShell: View {
    let onSignOut: () -> Void

    var body: some View {
        TabView {
            HomePage()
                .tabItem { Label("Home", systemImage: "house.fill") }

            AddTaskPage()
                .tabItem { Label("Add", systemImage: "plus.circle.fill") }

            TimeBlockingView()
                .tabItem { Label("Plan", systemImage: "calendar") }

            RemindersView()
                .tabItem { Label("Reminders", systemImage: "bell.badge.fill") }

            PomodoroTimerView()
                .tabItem { Label("Focus", systemImage: "timer") }
        }
    }
}

struct HomeHubView: View {
    let onSignOut: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your day, in one place")
                        .font(.title2).bold()

                    Text("Quick actions + overview (placeholder)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 12) {
                        NavigationLink { AddTaskPage() } label: {
                            tile("Add Task", "plus")
                        }
                        NavigationLink { TimeBlockingView() } label: {
                            tile("Time Block", "calendar")
                        }
                        NavigationLink { PomodoroTimerView() } label: {
                            tile("Start Focus", "timer")
                        }
                        NavigationLink { RemindersView() } label: {
                            tile("Reminders", "bell")
                        }
                        NavigationLink { WrappedView() } label: {
                            tile("End of Day Wrapped", "sparkles")
                        }
                    }

                    Button("Sign out") { onSignOut() }
                        .padding(.top, 6)
                        .foregroundStyle(.secondary)
                }
                .padding(18)
            }
            .navigationTitle("Today")
        }
    }

    private func tile(_ title: String, _ systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.headline)
            Text(title)
                .font(.headline)
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.55))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.35), lineWidth: 1)
        )
        .foregroundStyle(.primary)
    }
}

// MARK: - Keep ContentView for compatibility

/// If other files still reference ContentView(), keep it as a wrapper.
struct ContentView: View {
    var body: some View {
        AppRootView()
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
