//
//  LoginView.swift
//  productivity-app
//
//  Created by Audrey W-M on 1/8/26.
//

import SwiftUI

// MARK: - View
struct LoginView: View {
    @EnvironmentObject private var auth: AuthManager
    
    // MARK: - Email auth modes
    enum EmailAuthMode: String, CaseIterable, Identifiable {
        case signIn = "Sign In"
        case signUp = "Create Account"
        var id: String { rawValue }
    }
    
    @State private var authMode: EmailAuthMode = .signIn
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert: Bool = false
    
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
                        Text("Mel")
                            .font(.system(size: 75, weight: .bold, design: .rounded))
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
                    
                    // Auth Form
                    VStack(spacing: 12) {
                        // Mode toggle
                        Picker("", selection: $authMode) {
                            ForEach(EmailAuthMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 6)
                        .padding(.bottom, 6)
                        
                        VStack(spacing: 10) {
                            // Email
                            HStack(spacing: 10) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(Color(red: 0.39, green: 0.28, blue: 0.60))
                                    .frame(width: 22)
                                
                                TextField("Email", text: $email)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .background(cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            
                            // Password
                            HStack(spacing: 10) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(Color(red: 0.39, green: 0.28, blue: 0.60))
                                    .frame(width: 22)
                                
                                SecureField("Password", text: $password)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .textContentType(.password)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 14)
                            .background(cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            
                            // Confirm password (sign up only)
                            if authMode == .signUp {
                                HStack(spacing: 10) {
                                    Image(systemName: "lock.rotation")
                                        .foregroundColor(Color(red: 0.39, green: 0.28, blue: 0.60))
                                        .frame(width: 22)
                                    
                                    SecureField("Confirm password", text: $confirmPassword)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled(true)
                                        .textContentType(.newPassword)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 14)
                                .background(cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                            
                            // Inline error
                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 2)
                            }
                            
                            // Submit Button
                            Button {
                                submitEmailAuth()
                            } label: {
                                HStack(spacing: 10) {
                                    if isSubmitting {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: authMode == .signUp ? "person.badge.plus" : "person.fill.checkmark")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    
                                    Text(authMode == .signUp ? "Create account" : "Sign in")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(PrimaryPillButtonStyle())
                            .disabled(!canSubmit || isSubmitting)
                            .opacity((!canSubmit || isSubmitting) ? 0.7 : 1.0)
                            
                            // Secondary actions
                            HStack {
                                Button {
                                    errorMessage = "Password reset will be added soon."
                                } label: {
                                    Text("Forgot password?")
                                        .font(.footnote)
                                        .foregroundColor(Color(red: 0.39, green: 0.28, blue: 0.60))
                                }
                                
                                Spacer()
                                
                                Button {
                                    errorMessage = "Apple sign-in will be added soon."
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "applelogo")
                                        Text("Apple")
                                    }
                                    .font(.footnote)
                                    .foregroundColor(Color(red: 0.39, green: 0.28, blue: 0.60))
                                }
                            }
                            .padding(.top, 2)
                        }
                        .padding(18)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.58),
                                    Color.white.opacity(0.42)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.45), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        
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
                .alert("Sign in failed", isPresented: $showErrorAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(errorMessage ?? "Something went wrong.")
                }
            }
        }
    }
    
    // MARK: - Visual Components
    
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
    
    // MARK: - Validation & Networking
    
    private var trimmedEmail: String { email.trimmingCharacters(in: .whitespacesAndNewlines) }
    
    private var isEmailLikelyValid: Bool {
        trimmedEmail.contains("@") && trimmedEmail.contains(".") && trimmedEmail.count >= 5
    }
    
    private var isPasswordLikelyValid: Bool {
        password.count >= 6
    }
    
    private var canSubmit: Bool {
        if authMode == .signUp {
            return isEmailLikelyValid && isPasswordLikelyValid && !confirmPassword.isEmpty && confirmPassword == password
        } else {
            return isEmailLikelyValid && isPasswordLikelyValid
        }
    }
    
    struct AuthResponse: Decodable {
        let access_token: String
        let user: UserDTO
    }
    
    struct UserDTO: Decodable {
        let id: Int
        let email: String
        
        init(id: Int, email: String) {
            self.id = id
            self.email = email
        }
    }
    
    private func submitEmailAuth() {
        errorMessage = nil
        showErrorAlert = false
        
        guard isEmailLikelyValid else {
            errorMessage = "Please enter a valid email."
            showErrorAlert = true
            return
        }
        guard isPasswordLikelyValid else {
            errorMessage = "Password must be at least 6 characters."
            showErrorAlert = true
            return
        }
        if authMode == .signUp, confirmPassword != password {
            errorMessage = "Passwords do not match."
            showErrorAlert = true
            return
        }
        
        isSubmitting = true
        
        Task {
            do {
                defer {
                    Task { @MainActor in
                        isSubmitting = false
                    }
                }
                
                // --- FIX: Using Port 5001 to avoid AirPlay (5000) and Proxy (8080) issues ---
                let endpoint = authMode == .signUp ? "/api/auth/register" : "/api/auth/login"
                guard let url = URL(string: "http://127.0.0.1:5001\(endpoint)") else {
                    throw URLError(.badURL)
                }
                
                var req = URLRequest(url: url)
                req.httpMethod = "POST"
                req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let payload: [String: Any] = [
                    "email": trimmedEmail,
                    "password": password
                ]
                req.httpBody = try JSONSerialization.data(withJSONObject: payload)
                
                let (data, resp) = try await URLSession.shared.data(for: req)
                
                guard let http = resp as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                if !(200..<300).contains(http.statusCode) {
                    let msg = String(data: data, encoding: .utf8) ?? "Request failed"
                    throw NSError(domain: "API", code: http.statusCode,
                                  userInfo: [NSLocalizedDescriptionKey: msg])
                }
                
                // Parse Response
                let decoded: AuthResponse
                do {
                    decoded = try JSONDecoder().decode(AuthResponse.self, from: data)
                } catch {
                    // Fallback for loose JSON structures
                    let obj = try JSONSerialization.jsonObject(with: data)
                    guard let dict = obj as? [String: Any] else { throw error }
                    
                    let token = (dict["access_token"] as? String)
                        ?? (dict["token"] as? String)
                        ?? ""
                    
                    let userDict = dict["user"] as? [String: Any]
                    let emailVal = (userDict?["email"] as? String)
                        ?? (dict["email"] as? String)
                        ?? trimmedEmail
                    
                    let idVal = (userDict?["id"] as? Int) ?? 0
                    
                    decoded = AuthResponse(access_token: token, user: UserDTO(id: idVal, email: emailVal))
                }
                
                guard !decoded.access_token.isEmpty else {
                    throw NSError(domain: "API", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing access token in response."])
                }
                
                // Success: Persist & Sign In
                await MainActor.run {
                    auth.signIn(accessToken: decoded.access_token, email: decoded.user.email)
                    errorMessage = nil
                    showErrorAlert = false
                }
                
            } catch {
                print("Login Error: \(error)")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Updated AuthManager (Handles Persistence)

@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var accessToken: String? = nil
    @Published private(set) var email: String? = nil
    
    init() {
        // 1. Auto-login on app launch
        if let savedToken = UserDefaults.standard.string(forKey: "authToken") {
            self.accessToken = savedToken
            self.email = UserDefaults.standard.string(forKey: "userEmail")
            self.isAuthenticated = true
            print("🔹 AuthManager: Session restored from UserDefaults")
        }
    }
    
    func signIn(accessToken: String, email: String) {
        // 2. Set Memory
        self.accessToken = accessToken
        self.email = email
        self.isAuthenticated = true
        
        // 3. Save to Disk
        UserDefaults.standard.set(accessToken, forKey: "authToken")
        UserDefaults.standard.set(email, forKey: "userEmail")
        print("✅ AuthManager: Token saved.")
    }
    
    func signOut() {
        // 4. Clear Memory
        self.isAuthenticated = false
        self.accessToken = nil
        self.email = nil
        
        // 5. Clear Disk
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        print("🛑 AuthManager: Token removed.")
    }
}

struct AuthenticatedRootView: View {
    @EnvironmentObject private var auth: AuthManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("You’re signed in")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                
                if let email = auth.email {
                    Text(email)
                        .foregroundColor(.secondary)
                }
                
                Button("Sign out") {
                    auth.signOut()
                }
                .buttonStyle(PrimaryPillButtonStyle())
                .padding(.horizontal, 24)
            }
            .padding()
            .navigationTitle("Home")
        }
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
        .environmentObject(AuthManager())
}
