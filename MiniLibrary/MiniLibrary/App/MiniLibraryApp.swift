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
    @AppStorage("hasSeededBooks") private var hasSeededBooks = false
    @AppStorage("hasSeededWishlist") private var hasSeededWishlist = false
    @AppStorage("hasCleared") private var hasCleared = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Book.self,
            Student.self,
            CheckoutRecord.self,
            User.self,
            Activity.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            let context = ModelContext(container)

            // Seed students from CSV
            do {
                try DataSeeder.seedStudentsFromCSV(fileName: "sample_students", modelContext: context)
            } catch {
                logger.error("Error seeding students: \(error)")
            }

            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    clearDataIfNeeded()
                    seedBooksIfNeeded()
                    seedWishlistIfNeeded()
                    setupNotifications()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func setupNotifications() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                NotificationService.requestAuthorization()
            case .authorized, .provisional:
                NotificationService.scheduleWeeklyExportReminder()
            default:
                break
            }
        }
    }

    private func clearDataIfNeeded() {
        guard !hasCleared else { return }

        let context = ModelContext(sharedModelContainer)
        DataSeeder.clearLocalData(modelContext: context)
        hasCleared = true
        logger.info("Local data cleared on first install")
    }

    private func seedBooksIfNeeded() {
        guard !hasSeededBooks else { return }

        let context = ModelContext(sharedModelContainer)
        do {
            try DataSeeder.seedBooksFromCSV(fileName: "sample_books", modelContext: context)
            hasSeededBooks = true
            logger.info("Books seeded successfully on first install")
        } catch {
            logger.error("Error seeding books: \(error)")
        }
    }

    private func seedWishlistIfNeeded() {
        guard !hasSeededWishlist else { return }

        let context = ModelContext(sharedModelContainer)
        do {
            try DataSeeder.seedWishlistFromCSV(fileName: "sample_wish_list", modelContext: context)
            hasSeededWishlist = true
            logger.info("Wishlist seeded successfully on first install")
        } catch {
            logger.error("Error seeding wishlist: \(error)")
        }
    }
}
