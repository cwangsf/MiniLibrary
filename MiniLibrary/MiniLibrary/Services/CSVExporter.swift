//
//  CSVExporter.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import Foundation

enum CSVExporter {
    /// Export books to CSV format
    static func exportBooks(_ books: [Book]) -> String {
        var csv = "ISBN,Title,Author,Total Copies,Available Copies,Language,Publisher,Published Date,Page Count,Notes\n"

        for book in books {
            let fields = [
                escapeCSV(book.isbn ?? ""),
                escapeCSV(book.title),
                escapeCSV(book.author),
                String(book.totalCopies),
                String(book.availableCopies),
                escapeCSV(book.language?.displayName ?? ""),
                escapeCSV(book.publisher ?? ""),
                escapeCSV(book.publishedDate ?? ""),
                book.pageCount != nil ? String(book.pageCount!) : "",
                escapeCSV(book.notes ?? "")
            ]

            csv += fields.joined(separator: ",") + "\n"
        }

        return csv
    }

    /// Escape CSV field (handle quotes and commas)
    private static func escapeCSV(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }

    /// Save CSV string to temporary file and return URL
    static func saveToTemporaryFile(_ csvContent: String, filename: String = "library_catalog.csv") -> URL? {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let fileURL = temporaryDirectoryURL.appendingPathComponent(filename)

        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error saving CSV file: \(error)")
            return nil
        }
    }
}
