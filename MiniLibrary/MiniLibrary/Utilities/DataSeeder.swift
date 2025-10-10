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

        // Parse CSV
        let rows = try CSVParser.parse(fileURL: fileURL)

        var booksCreated = 0
        for row in rows {
            // Create Book from CSV row
            if let book = createBook(from: row) {
                modelContext.insert(book)
                booksCreated += 1
            }
        }

        try modelContext.save()
        print("Successfully seeded \(booksCreated) books")
    }

    /// Create a Book instance from CSV row
    private static func createBook(from csvRow: [String: String]) -> Book? {
        guard let title = csvRow["Title"]?.trimmingCharacters(in: .whitespaces),
              let author = csvRow["Primary Author"]?.trimmingCharacters(in: .whitespaces),
              !title.isEmpty,
              !author.isEmpty else {
            return nil
        }

        // Extract first ISBN from ISBNs column
        var isbn: String? = nil
        if let isbns = csvRow["ISBNs"]?.trimmingCharacters(in: .whitespaces),
           !isbns.isEmpty {
            // ISBNs are in format "1406312207, 9781406312201" or "[1406312207]"
            let cleaned = isbns.replacingOccurrences(of: "[", with: "")
                               .replacingOccurrences(of: "]", with: "")
            isbn = cleaned.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces)
        }

        // Get copies, default to 1
        var totalCopies = 1
        if let copiesStr = csvRow["Copies"]?.trimmingCharacters(in: .whitespaces),
           let copies = Int(copiesStr), copies > 0 {
            totalCopies = copies
        }

        return Book(
            isbn: isbn,
            title: title,
            author: author,
            totalCopies: totalCopies,
            availableCopies: totalCopies
        )
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
}

enum DataSeederError: Error {
    case fileNotFound
    case invalidData
}
