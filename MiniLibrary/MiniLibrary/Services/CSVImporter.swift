//
//  CSVImporter.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/15/25.
//

import Foundation
import SwiftData

struct CSVImporter {
    /// Import books from CSV format
    /// Flexible format using column headers. Supports both standard and custom column names.
    /// Standard: ISBN, Title, Author, Total Copies, Available Copies, Language, Publisher, Published Date, Page Count, Notes
    /// Custom: ISBNs, Title, Primary Author, Copies
    static func importBooks(from csvContent: String, modelContext: ModelContext) throws -> Int {
        let rows = CSVParser.parse(csvString: csvContent)

        guard !rows.isEmpty else {
            throw CSVImportError.emptyFile
        }

        var importedCount = 0

        for (index, row) in rows.enumerated() {
            // Create Book from CSV row
            if let book = createBook(from: row) {
                modelContext.insert(book)
                importedCount += 1
            } else {
                print("Skipping line \(index + 2): invalid data: \n     Book info: \(row)")
            }
        }

        return importedCount
    }

    /// Create a Book instance from CSV row (supports multiple column name formats)
    private static func createBook(from csvRow: [String: String]) -> Book? {
        // Try "Title" column
        guard let title = csvRow["Title"]?.trimmingCharacters(in: .whitespaces),
              !title.isEmpty else {
            return nil
        }

        // Try both "Primary Author" and "Author" columns
        let author: String
        if let primaryAuthor = csvRow["Primary Author"]?.trimmingCharacters(in: .whitespaces),
           !primaryAuthor.isEmpty {
            author = primaryAuthor
        } else if let standardAuthor = csvRow["Author"]?.trimmingCharacters(in: .whitespaces),
                  !standardAuthor.isEmpty {
            author = standardAuthor
        } else {
            return nil
        }

        // Extract first ISBN from "ISBNs" or "ISBN" column
        var isbn: String? = nil
        if let isbns = csvRow["ISBNs"]?.trimmingCharacters(in: .whitespaces),
           !isbns.isEmpty {
            // ISBNs are in format "1406312207, 9781406312201" or "[1406312207]"
            let cleaned = isbns.replacingOccurrences(of: "[", with: "")
                               .replacingOccurrences(of: "]", with: "")
            isbn = cleaned.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces)
        } else if let singleISBN = csvRow["ISBN"]?.trimmingCharacters(in: .whitespaces),
                  !singleISBN.isEmpty {
            isbn = singleISBN
        }

        // Get copies (try both "Copies" and "Total Copies")
        var totalCopies = 1
        if let copiesStr = csvRow["Copies"]?.trimmingCharacters(in: .whitespaces),
           let copies = Int(copiesStr), copies > 0 {
            totalCopies = copies
        } else if let totalStr = csvRow["Total Copies"]?.trimmingCharacters(in: .whitespaces),
                  let copies = Int(totalStr), copies > 0 {
            totalCopies = copies
        }

        // Get available copies (defaults to total if not specified)
        var availableCopies = totalCopies
        if let availStr = csvRow["Available Copies"]?.trimmingCharacters(in: .whitespaces),
           let avail = Int(availStr), avail >= 0 {
            availableCopies = avail
        }

        // Optional fields from CSV
        let language = csvRow["Language"]?.trimmingCharacters(in: .whitespaces)
        let publisher = csvRow["Publisher"]?.trimmingCharacters(in: .whitespaces)
        let publishedDate = csvRow["Published Date"]?.trimmingCharacters(in: .whitespaces)
        let pageCount = csvRow["Page Count"].flatMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        let notes = csvRow["Notes"]?.trimmingCharacters(in: .whitespaces)

        return Book(
            isbn: isbn,
            title: title,
            author: author,
            totalCopies: totalCopies,
            availableCopies: availableCopies,
            bookDescription: nil,
            pageCount: pageCount,
            publishedDate: publishedDate.flatMap { $0.isEmpty ? nil : $0 },
            publisher: publisher.flatMap { $0.isEmpty ? nil : $0 },
            languageCode: language.flatMap { $0.isEmpty ? nil : $0 },
            coverImageURL: nil,
            notes: notes.flatMap { $0.isEmpty ? nil : $0 },
            isWishlistItem: false
        )
    }

    /// Import wishlist books from CSV format
    /// Expected format: ISBN, Title, Author
    /// Title is required, ISBN and Author are optional
    /// Books are created immediately with available data, metadata can be fetched later
    static func importWishlist(from csvContent: String, modelContext: ModelContext) throws -> Int {
        let rows = CSVParser.parse(csvString: csvContent)

        guard !rows.isEmpty else {
            throw CSVImportError.emptyFile
        }

        var importedCount = 0

        for (index, row) in rows.enumerated() {
            // Create wishlist Book from CSV row
            if let book = createWishlistBook(from: row) {
                modelContext.insert(book)
                importedCount += 1
            } else {
                print("Skipping line \(index + 2): invalid wishlist data - Title is required")
            }
        }

        return importedCount
    }

    /// Create a wishlist Book instance from CSV row (no API calls)
    /// Format: ISBN, Title, Author (Title is required, others optional)
    private static func createWishlistBook(from csvRow: [String: String]) -> Book? {
        // Title is required
        guard let title = csvRow["Title"]?.trimmingCharacters(in: .whitespaces),
              !title.isEmpty else {
            return nil
        }

        // Author is optional (try both "Author" and "Primary Author")
        var author = "Unknown Author"
        if let csvAuthor = csvRow["Author"]?.trimmingCharacters(in: .whitespaces),
           !csvAuthor.isEmpty {
            author = csvAuthor
        } else if let primaryAuthor = csvRow["Primary Author"]?.trimmingCharacters(in: .whitespaces),
                  !primaryAuthor.isEmpty {
            author = primaryAuthor
        }

        // ISBN is optional (try both "ISBN" and "ISBNs")
        // Clean ISBN by removing hyphens and other common separators
        var isbn: String? = nil
        if let csvISBN = csvRow["ISBN"]?.trimmingCharacters(in: .whitespaces),
           !csvISBN.isEmpty {
            isbn = cleanISBN(csvISBN)
        } else if let isbns = csvRow["ISBNs"]?.trimmingCharacters(in: .whitespaces),
                  !isbns.isEmpty {
            // Extract first ISBN from comma-separated list
            let cleaned = isbns.replacingOccurrences(of: "[", with: "")
                               .replacingOccurrences(of: "]", with: "")
            if let firstISBN = cleaned.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) {
                isbn = cleanISBN(firstISBN)
            }
        }

        return Book(
            isbn: isbn,
            title: title,
            author: author,
            totalCopies: 0,
            availableCopies: 0,
            isWishlistItem: true
        )
    }

    /// Clean ISBN by removing hyphens, spaces, and keeping only digits and 'X'
    /// Examples: "978-0-123456-78-9" -> "9780123456789", "0-306-40615-X" -> "030640615X"
    private static func cleanISBN(_ isbn: String) -> String {
        let cleaned = isbn.replacingOccurrences(of: "-", with: "")
                          .replacingOccurrences(of: " ", with: "")
                          .trimmingCharacters(in: .whitespaces)

        // Validate it contains only digits and optionally 'X' at the end
        let isValid = cleaned.allSatisfy { $0.isNumber || $0 == "X" || $0 == "x" }

        guard isValid, !cleaned.isEmpty else {
            return isbn // Return original if invalid format
        }

        return cleaned.uppercased() // Ensure 'X' is uppercase
    }

}

enum CSVImportError: LocalizedError {
    case emptyFile
    case invalidFormat
    case fileReadError

    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The CSV file is empty"
        case .invalidFormat:
            return "The CSV file format is invalid"
        case .fileReadError:
            return "Unable to read the CSV file"
        }
    }
}
