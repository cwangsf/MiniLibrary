//
//  DataSeeder.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import Foundation
import SwiftData
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MiniLibrary", category: "DataSeeder")

class DataSeeder {

    /// Load books from CSV file and insert into SwiftData
    /// Only seeds if the database is completely empty
    static func seedBooksFromCSV(fileName: String, modelContext: ModelContext) throws {
        // Check if any books already exist
        let descriptor = FetchDescriptor<Book>()
        let existingBooks = try modelContext.fetch(descriptor)

        guard existingBooks.isEmpty else {
            logger.info("Books already seeded, skipping...")
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
        logger.info("Successfully seeded \(booksCreated) books")
    }

    /// Load wishlist items from CSV file and insert into SwiftData
    /// Only seeds if no wishlist items exist yet
    /// Uses fast import (no API calls) for instant loading
    static func seedWishlistFromCSV(fileName: String, modelContext: ModelContext) throws {
        // Get CSV file from bundle
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: "csv") else {
            throw DataSeederError.fileNotFound
        }

        // Read CSV content
        let csvContent = try String(contentsOf: fileURL, encoding: .utf8)

        // Use CSVImporter for instant loading
        let itemsCreated = try CSVImporter.importWishlist(from: csvContent, modelContext: modelContext)

        try modelContext.save()
        logger.info("Successfully seeded \(itemsCreated) wishlist items")
    }

    /// Load students from CSV file and insert into SwiftData
    /// Only seeds if no students exist yet
    static func seedStudentsFromCSV(fileName: String, modelContext: ModelContext) throws {
        // Check if any students already exist
        let descriptor = FetchDescriptor<Student>()
        let existingStudents = try modelContext.fetch(descriptor)

        guard existingStudents.isEmpty else {
            logger.info("Students already seeded, skipping...")
            return
        }

        // Get CSV file from bundle
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: "csv") else {
            throw DataSeederError.fileNotFound
        }

        // Read CSV content
        let csvContent = try String(contentsOf: fileURL, encoding: .utf8)

        // Use CSVImporter to import students
        let studentsCreated = try CSVImporter.importStudents(from: csvContent, modelContext: modelContext)

        try modelContext.save()
        logger.info("Successfully seeded \(studentsCreated) students")
    }

    /// Export books to JSON file (for testing or backup)
    static func exportBooksToJSON(books: [Book], to fileURL: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(books)
        try data.write(to: fileURL)
        logger.info("Exported \(books.count) books to \(fileURL.path)")
    }

    // MARK: - Debug Seeding
    /// Seed debug data: clear all data
    static func clearLocalData(modelContext: ModelContext) {
        do {
            // Clear all data
            try modelContext.delete(model: Book.self)
            try modelContext.delete(model: Student.self)
            try modelContext.delete(model: CheckoutRecord.self)
            try modelContext.delete(model: User.self)
            try modelContext.delete(model: Activity.self)
            try modelContext.save()
            logger.debug("Cleared all SwiftData")
        } catch {
            logger.error("Error clearing local data: \(error)")
        }
    }
}

enum DataSeederError: Error {
    case fileNotFound
    case invalidData
}
