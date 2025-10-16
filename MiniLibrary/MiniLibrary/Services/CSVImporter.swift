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
    /// Expected format: Title,Author,ISBN
    /// Only Title is required, Author and ISBN are optional
    static func importWishlist(from csvContent: String, modelContext: ModelContext) async throws -> Int {
        let lines = csvContent.components(separatedBy: .newlines)

        // Skip header and empty lines
        guard lines.count > 1 else {
            throw CSVImportError.emptyFile
        }

        var importedCount = 0

        // Start from line 1 (skip header at line 0)
        for (index, line) in lines.enumerated() where index > 0 {
            // Skip empty lines
            guard !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                continue
            }

            do {
                let fields = try parseCSVLine(line)

                // Validate minimum required fields (Title)
                guard fields.count >= 1 else {
                    print("Skipping line \(index + 1): insufficient fields")
                    continue
                }

                let title = fields[0]

                // Skip if title is empty
                guard !title.isEmpty else {
                    print("Skipping line \(index + 1): missing title")
                    continue
                }

                let author = fields.count > 1 && !fields[1].isEmpty ? fields[1] : ""
                let isbn = fields.count > 2 && !fields[2].isEmpty ? fields[2] : nil

                // Search for book on Google Books
                do {
                    let items: [GoogleBookItem]

                    if let isbn = isbn {
                        // Try ISBN search first
                        items = try await BookAPIService.shared.searchBooksByISBN(isbn)
                    } else {
                        // Search by title and author
                        items = try await BookAPIService.shared.searchBooksByTitleAndAuthor(
                            title: title,
                            author: author
                        )
                    }

                    // Use first result
                    if let firstItem = items.first {
                        let book = await BookAPIService.shared.createBookFromSearchResult(firstItem, isWishlistItem: true)
                        modelContext.insert(book)
                        importedCount += 1
                    } else {
                        let searchInfo = author.isEmpty ? title : "\(title) by \(author)"
                        print("Skipping line \(index + 1): no results found for \(searchInfo)")
                    }
                } catch {
                    print("Error searching for book on line \(index + 1): \(error). \n      line: \(line)")
                    continue
                }

            } catch {
                print("Error parsing line \(index + 1): \(error)")
                continue
            }
        }

        return importedCount
    }

    /// Parse a CSV line handling quoted fields
    private static func parseCSVLine(_ line: String) throws -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false
        var previousChar: Character?

        for char in line {
            if char == "\"" {
                if insideQuotes && previousChar == "\"" {
                    // Escaped quote
                    currentField.append(char)
                    previousChar = nil
                    continue
                } else {
                    insideQuotes.toggle()
                }
            } else if char == "," && !insideQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }

            previousChar = char
        }

        // Add last field
        fields.append(currentField)

        return fields
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
