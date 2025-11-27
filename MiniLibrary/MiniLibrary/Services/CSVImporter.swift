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
        // Fix encoding issues: replace smart quotes and other problematic characters
        let cleanedContent = csvContent
            .replacingOccurrences(of: "â€™", with: "'")  // Smart quote encoding issue
            .replacingOccurrences(of: "\u{201C}", with: "\"") // Left double quotation mark
            .replacingOccurrences(of: "\u{201D}", with: "\"") // Right double quotation mark
            .replacingOccurrences(of: "\u{2018}", with: "'")  // Left single quotation mark
            .replacingOccurrences(of: "\u{2019}", with: "'")  // Right single quotation mark
            .replacingOccurrences(of: "\u{2013}", with: "-")  // En dash
            .replacingOccurrences(of: "\u{2014}", with: "-")  // Em dash

        let rows = CSVParser.parse(csvString: cleanedContent)

        guard !rows.isEmpty else {
            throw CSVImportError.emptyFile
        }

        var importedCount = 0
        var skippedLines: [(lineNumber: Int, reason: String, row: [String: String])] = []
        var seenBooks: Set<String> = [] // Track unique books by their identity key

        // Fetch existing books to check for duplicates
        let descriptor = FetchDescriptor<Book>()
        let existingBooks = try modelContext.fetch(descriptor)

        for (index, row) in rows.enumerated() {
            let lineNumber = index + 2 // CSV line numbers start at 2 (after header)

            // Create Book from CSV row
            let result = createBook(from: row)
            if let book = result.book {
                // Create a unique key for this book (ISBN if available, otherwise title + author)
                let bookKey: String
                if let isbn = book.isbn, !isbn.isEmpty {
                    bookKey = "isbn:\(isbn)"
                } else {
                    bookKey = "title:\(book.title)|author:\(book.author ?? "")"
                }

                // Check if we've already seen this book in the CSV
                if seenBooks.contains(bookKey) {
                    let reason = "Duplicate in CSV (same as earlier line): \(book.title) by \(book.author ?? "Unknown")"
                    skippedLines.append((lineNumber: lineNumber, reason: reason, row: row))
                    print("Skipping line \(lineNumber): \(reason)")
                    continue
                }

                // Check if a book with the same ISBN already exists in database
                if let isbn = book.isbn,
                   existingBooks.contains(where: { $0.isbn == isbn }) {
                    skippedLines.append((lineNumber: lineNumber, reason: "Duplicate ISBN in database: \(isbn)", row: row))
                    print("Skipping line \(lineNumber): Duplicate ISBN in database: \(isbn)")
                    continue
                }

                // Check if a book with same title and author already exists in database
                if book.isbn == nil,
                   existingBooks.contains(where: {
                       $0.title == book.title && $0.author == book.author
                   }) {
                    let reason = "Duplicate in database: \(book.title) by \(book.author ?? "Unknown")"
                    skippedLines.append((lineNumber: lineNumber, reason: reason, row: row))
                    print("Skipping line \(lineNumber): \(reason)")
                    continue
                }

                // Mark this book as seen and import it
                seenBooks.insert(bookKey)
                modelContext.insert(book)
                importedCount += 1
            } else {
                skippedLines.append((lineNumber: lineNumber, reason: result.reason, row: row))
                print("Skipping line \(lineNumber): \(result.reason)\n     Book info: \(row)")
            }
        }

        // Save skipped lines to a new CSV file
        if !skippedLines.isEmpty {
            saveSkippedLines(skippedLines, fileName: "skipped_books.csv")
        }

        return importedCount
    }

    /// Create a Book instance from CSV row (supports multiple column name formats)
    /// Returns a tuple of (book, reason) where book is nil if creation failed
    private static func createBook(from csvRow: [String: String]) -> (book: Book?, reason: String) {
        // Try "Title" column
        guard let title = csvRow["Title"]?.trimmingCharacters(in: .whitespaces),
              !title.isEmpty else {
            return (nil, "Missing or empty Title")
        }

        // Try both "Primary Author" and "Author" columns (author is optional)
        var author: String? = nil
        if let primaryAuthor = csvRow["Primary Author"]?.trimmingCharacters(in: .whitespaces),
           !primaryAuthor.isEmpty {
            author = primaryAuthor
        } else if let standardAuthor = csvRow["Author"]?.trimmingCharacters(in: .whitespaces),
                  !standardAuthor.isEmpty {
            author = standardAuthor
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
        // Try both "Languages" (plural) and "Language" (singular)
        let language: String?
        if let languages = csvRow["Languages"]?.trimmingCharacters(in: .whitespaces), !languages.isEmpty {
            language = languages
        } else {
            language = csvRow["Language"]?.trimmingCharacters(in: .whitespaces)
        }

        let publisher = csvRow["Publisher"]?.trimmingCharacters(in: .whitespaces)
        let publishedDate = csvRow["Published Date"]?.trimmingCharacters(in: .whitespaces)
        let pageCount = csvRow["Page Count"].flatMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        let notes = csvRow["Notes"]?.trimmingCharacters(in: .whitespaces)

        let book = Book(
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
        return (book, "")
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

    /// Save skipped lines to a CSV file in the Documents directory
    private static func saveSkippedLines(_ skippedLines: [(lineNumber: Int, reason: String, row: [String: String])], fileName: String) {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to access Documents directory")
            return
        }

        let fileURL = documentsURL.appendingPathComponent(fileName)

        // Get all unique column headers from skipped lines
        var allHeaders = Set<String>()
        for (_, _, row) in skippedLines {
            allHeaders.formUnion(row.keys)
        }
        let sortedHeaders = Array(allHeaders).sorted()

        // Build CSV content
        var csvContent = "Line Number,Reason," + sortedHeaders.joined(separator: ",") + "\n"

        for (lineNumber, reason, row) in skippedLines {
            var values = [String(lineNumber)]

            // Add reason with proper CSV escaping
            let escapedReason = reason.contains(",") || reason.contains("\"") || reason.contains("\n") ?
                "\"\(reason.replacingOccurrences(of: "\"", with: "\"\""))\"" : reason
            values.append(escapedReason)

            for header in sortedHeaders {
                let value = row[header] ?? ""
                // Escape quotes and wrap in quotes if contains comma
                let escapedValue = value.contains(",") || value.contains("\"") || value.contains("\n") ?
                    "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\"" : value
                values.append(escapedValue)
            }
            csvContent += values.joined(separator: ",") + "\n"
        }

        // Write to file
        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Skipped lines saved to: \(fileURL.path)")
        } catch {
            print("Error saving skipped lines: \(error.localizedDescription)")
        }
    }

    /// Import students from CSV format
    /// Expected format: First Name, Last Name, Class (optional)
    /// First Name and Last Name are required, Class is optional
    static func importStudents(from csvContent: String, modelContext: ModelContext) throws -> Int {
        let rows = CSVParser.parse(csvString: csvContent)

        guard !rows.isEmpty else {
            throw CSVImportError.emptyFile
        }

        var importedCount = 0

        for (index, row) in rows.enumerated() {
            // Create Student from CSV row
            if let student = createStudent(from: row) {
                modelContext.insert(student)
                importedCount += 1
            } else {
                print("Skipping line \(index + 2): invalid student data - First Name and Last Name are required")
            }
        }

        return importedCount
    }

    /// Create a Student instance from CSV row
    /// Format: First Name, Last Name, Class (optional)
    private static func createStudent(from csvRow: [String: String]) -> Student? {
        // First Name and Last Name are required
        guard let firstName = csvRow["First Name"]?.trimmingCharacters(in: .whitespaces),
              !firstName.isEmpty else {
            return nil
        }

        guard let lastName = csvRow["Last Name"]?.trimmingCharacters(in: .whitespaces),
              !lastName.isEmpty else {
            return nil
        }

        // Class is optional
        let classCode = csvRow["Class"]?.trimmingCharacters(in: .whitespaces).isEmpty == false ?
            csvRow["Class"]?.trimmingCharacters(in: .whitespaces) : nil

        return Student(firstName: firstName, lastName: lastName, classCode: classCode)
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
