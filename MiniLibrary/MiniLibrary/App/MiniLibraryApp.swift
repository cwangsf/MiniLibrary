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
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            let context = ModelContext(container)

            #if DEBUG
            // Seed debug data on every launch
            DataSeeder.seedDebugData(modelContext: context)
            #endif

            // Seed books from CSV
            do {
                try DataSeeder.seedBooksFromCSV(fileName: "sample_books", modelContext: context)
            } catch {
                print("Error seeding books: \(error)")
            }

            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
