//
//  MiniLibraryApp.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData

@main
struct MiniLibraryApp: App {
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

            DataSeeder.seedDebugData(modelContext: context)

            // Seed books from CSV
            do {
                try DataSeeder.seedBooksFromCSV(fileName: "sample_books", modelContext: context)
            } catch {
                print("Error seeding books: \(error)")
            }

            // Seed wishlist from CSV (fast - no API calls)
            do {
                try DataSeeder.seedWishlistFromCSV(fileName: "wish_list", modelContext: context)
            } catch {
                print("Error seeding wishlist: \(error)")
            }

            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
