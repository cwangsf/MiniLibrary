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
            // Clear all data on debug launches for testing
            do {
                try context.delete(model: Book.self)
                try context.delete(model: Student.self)
                try context.delete(model: CheckoutRecord.self)
                try context.delete(model: User.self)
                try context.save()
                print("Debug: Cleared all SwiftData")
            } catch {
                print("Debug: Error clearing data: \(error)")
            }
            #endif

            // Seed data on first launch
            do {
                try DataSeeder.seedBooksFromCSV(fileName: "sample_books", modelContext: context)
            } catch {
                print("Error seeding data: \(error)")
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
