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
    @AppStorage("hasSeededBooks") private var hasSeededBooks = false
    @AppStorage("hasSeededWishlist") private var hasSeededWishlist = false

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

            #if DEBUG
            DataSeeder.clearLocalData(modelContext: context)
            #endif

            #if DEBUG
            // Seed students from CSV
            do {
                try DataSeeder.seedStudentsFromCSV(fileName: "sample_students", modelContext: context)
            } catch {
                print("Error seeding students: \(error)")
            }
            #endif

            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    seedBooksIfNeeded()
                    seedWishlistIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func seedBooksIfNeeded() {
        guard !hasSeededBooks else { return }

        let context = ModelContext(sharedModelContainer)
        do {
            try DataSeeder.seedBooksFromCSV(fileName: "sample_books", modelContext: context)
            hasSeededBooks = true
            print("Books seeded successfully on first install")
        } catch {
            print("Error seeding books: \(error)")
        }
    }

    private func seedWishlistIfNeeded() {
        guard !hasSeededWishlist else { return }

        let context = ModelContext(sharedModelContainer)
        do {
            try DataSeeder.seedWishlistFromCSV(fileName: "wish_list", modelContext: context)
            hasSeededWishlist = true
            print("Wishlist seeded successfully on first install")
        } catch {
            print("Error seeding wishlist: \(error)")
        }
    }
}
