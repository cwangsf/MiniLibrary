//
//  DataSeeder.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import Foundation
import SwiftData

class DataSeeder {

    /// Load books from CSV file and insert into SwiftData
    /// Only seeds if the database is completely empty
    static func seedBooksFromCSV(fileName: String, modelContext: ModelContext) throws {
        // Check if any books already exist
        let descriptor = FetchDescriptor<Book>()
        let existingBooks = try modelContext.fetch(descriptor)

        guard existingBooks.isEmpty else {
            print("Books already seeded, skipping...")
            return
        }

        // Get CSV file from bundle
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: "csv") else {
            throw DataSeederError.fileNotFound
        }

        // Read CSV content
        let csvContent = try String(contentsOf: fileURL, encoding: .utf8)

        // Use existing CSVImporter to import books
        let booksCreated = try CSVImporter.importBooks(from: csvContent, modelContext: modelContext)

        try modelContext.save()
        print("Successfully seeded \(booksCreated) books")
    }

    /// Load wishlist items from CSV file and insert into SwiftData
    /// Only seeds if no wishlist items exist yet
    static func seedWishlistFromCSV(fileName: String, modelContext: ModelContext) async throws {
        // Check if any wishlist items already exist
        let descriptor = FetchDescriptor<Book>(
            predicate: #Predicate { $0.isWishlistItem == true }
        )
        let existingWishlist = try modelContext.fetch(descriptor)

        guard existingWishlist.isEmpty else {
            print("Wishlist already seeded, skipping...")
            return
        }

        // Get CSV file from bundle
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: "csv") else {
            throw DataSeederError.fileNotFound
        }

        // Read CSV content
        let csvContent = try String(contentsOf: fileURL, encoding: .utf8)

        // Use existing CSVImporter to import wishlist
        let itemsCreated = try await CSVImporter.importWishlist(from: csvContent, modelContext: modelContext)

        try modelContext.save()
        print("Successfully seeded \(itemsCreated) wishlist items")
    }

    /// Export books to JSON file (for testing or backup)
    static func exportBooksToJSON(books: [Book], to fileURL: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(books)
        try data.write(to: fileURL)
        print("Exported \(books.count) books to \(fileURL.path)")
    }

    // MARK: - Debug Seeding
    /// Seed debug data: clear all data, create sample users and students
    static func seedDebugData(modelContext: ModelContext) {
        do {
            // Clear all data
            try modelContext.delete(model: Book.self)
            try modelContext.delete(model: Student.self)
            try modelContext.delete(model: CheckoutRecord.self)
            try modelContext.delete(model: User.self)
            try modelContext.save()
            print("Debug: Cleared all SwiftData")

            // Create sample students
            for i in 1...6 {
                let student = Student(
                    libraryId: String(format: "Student-%03d", i),
                    gradeLevel: i
                )
                modelContext.insert(student)
            }
            try modelContext.save()
        } catch {
            print("Debug: Error seeding debug data: \(error)")
        }
    }
}

enum DataSeederError: Error {
    case fileNotFound
    case invalidData
}
