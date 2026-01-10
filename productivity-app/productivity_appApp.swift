//
//  productivity_appApp.swift
//  productivity-app
//
//  Created by Audrey W-M on 1/8/26.
//

import SwiftUI

@main
struct productivity_appApp: App {
    @StateObject private var auth = AuthManager()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(auth)
        }
    }
}
