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
    /// Expected format: ISBN,Title,Author,Total Copies,Available Copies,Language,Publisher,Published Date,Page Count,Notes
    static func importBooks(from csvContent: String, modelContext: ModelContext) async throws -> Int {
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

                // Validate minimum required fields (ISBN, Title, Author, Total Copies, Available Copies)
                guard fields.count >= 5 else {
                    print("Skipping line \(index + 1): insufficient fields")
                    continue
                }

                let isbn = fields[0].isEmpty ? nil : fields[0]
                let title = fields[1]
                let author = fields[2]

                // Skip if title or author is empty
                guard !title.isEmpty && !author.isEmpty else {
                    print("Skipping line \(index + 1): missing title or author")
                    continue
                }

                let totalCopies = Int(fields[3]) ?? 1
                let availableCopies = Int(fields[4]) ?? totalCopies

                // Optional fields
                let language = fields.count > 5 && !fields[5].isEmpty ? fields[5] : nil
                let publisher = fields.count > 6 && !fields[6].isEmpty ? fields[6] : nil
                let publishedDate = fields.count > 7 && !fields[7].isEmpty ? fields[7] : nil
                let pageCount = fields.count > 8 ? Int(fields[8]) : nil
                let notes = fields.count > 9 && !fields[9].isEmpty ? fields[9] : nil

                // Try to fetch book metadata from Google Books if we have ISBN
                var bookDescription: String? = nil
                var coverImageURL: String? = nil
                var fetchedPageCount: Int? = pageCount
                var fetchedPublishedDate: String? = publishedDate
                var fetchedPublisher: String? = publisher
                var languageCode: String? = nil

                if let isbn = isbn {
                    do {
                        let fetchedBook = try await BookAPIService.shared.fetchBookInfoFromGoogle(isbn: isbn)
                        bookDescription = fetchedBook.bookDescription
                        coverImageURL = fetchedBook.coverImageURL
                        if fetchedPageCount == nil {
                            fetchedPageCount = fetchedBook.pageCount
                        }
                        if fetchedPublishedDate == nil {
                            fetchedPublishedDate = fetchedBook.publishedDate
                        }
                        if fetchedPublisher == nil {
                            fetchedPublisher = fetchedBook.publisher
                        }
                        languageCode = fetchedBook.languageCode
                    } catch {
                        print("Could not fetch metadata for ISBN \(isbn): \(error.localizedDescription)")
                        // Continue with CSV data only
                    }
                }

                // Create book
                let book = Book(
                    isbn: isbn,
                    title: title,
                    author: author,
                    totalCopies: totalCopies,
                    availableCopies: availableCopies,
                    bookDescription: bookDescription,
                    pageCount: fetchedPageCount,
                    publishedDate: fetchedPublishedDate,
                    publisher: fetchedPublisher,
                    languageCode: languageCode,
                    coverImageURL: coverImageURL,
                    notes: notes,
                    isWishlistItem: false
                )

                modelContext.insert(book)
                importedCount += 1

            } catch {
                print("Error parsing line \(index + 1): \(error)")
                continue
            }
        }

        return importedCount
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
                    print("Error searching for book on line \(index + 1): \(error)")
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
