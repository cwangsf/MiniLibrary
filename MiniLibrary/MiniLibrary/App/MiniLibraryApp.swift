//
//  MiniLibraryApp.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData
import UserNotifications
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MiniLibrary", category: "MiniLibraryApp")

@main
struct MiniLibraryApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Book.self,
            Student.self,
            CheckoutRecord.self,
            User.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    setupNotifications()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func setupNotifications() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                Task { @MainActor in
                    NotificationService.requestAuthorization()
                }
            case .authorized, .provisional:
                Task { @MainActor in
                    NotificationService.scheduleWeeklyExportReminder()
                }
            default:
                break
            }
        }
    }
}
