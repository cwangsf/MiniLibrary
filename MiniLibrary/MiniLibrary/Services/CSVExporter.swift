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
                escapeCSV(book.author ?? ""),
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

    /// Export students to CSV format
    static func exportStudents(_ students: [Student]) -> String {
        var csv = "First Name,Last Name,Class\n"

        for student in students {
            let classCode = student.classCode ?? ""

            let fields = [
                escapeCSV(student.firstName),
                escapeCSV(student.lastName),
                escapeCSV(classCode)
            ]

            csv += fields.joined(separator: ",") + "\n"
        }

        return csv
    }

    /// Export checkout records to CSV format
    static func exportCheckoutRecords(_ checkouts: [CheckoutRecord]) -> String {
        var csv = "Book Title,Author,ISBN,Student Name,Checkout Date,Due Date,Return Date,Status\n"

        if checkouts.isEmpty {
            // Add a note if there are no checkouts
            csv += "No checkout records available\n"
            return csv
        }

        for checkout in checkouts {
            let bookTitle = checkout.book?.title ?? "Unknown"
            let bookAuthor = checkout.book?.author ?? ""
            let bookISBN = checkout.book?.isbn ?? ""
            let studentName = checkout.student?.fullName ?? "Unknown"
            let checkoutDate = checkout.checkoutDate.formatted(date: .abbreviated, time: .omitted)
            let dueDate = checkout.dueDate.formatted(date: .abbreviated, time: .omitted)
            let returnDate = checkout.returnDate?.formatted(date: .abbreviated, time: .omitted) ?? ""
            let status = checkout.isActive ? "Active" : "Returned"

            let fields = [
                escapeCSV(bookTitle),
                escapeCSV(bookAuthor),
                escapeCSV(bookISBN),
                escapeCSV(studentName),
                checkoutDate,
                dueDate,
                returnDate,
                status
            ]

            csv += fields.joined(separator: ",") + "\n"
        }

        return csv
    }

    /// Save CSV string to temporary file and return URL
    static func saveToTemporaryFile(_ csvContent: String, filename: String) -> URL? {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let fileURL = temporaryDirectoryURL.appendingPathComponent(filename)

        do {
            // Remove existing file if it exists
            try? FileManager.default.removeItem(at: fileURL)

            // Write the CSV content
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)

            // Verify the file was created
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                print("Error: CSV file was not created at \(fileURL.path)")
                return nil
            }

            print("✓ CSV file saved: \(fileURL.lastPathComponent)")
            return fileURL
        } catch {
            print("Error saving CSV file '\(filename)': \(error.localizedDescription)")
            return nil
        }
    }
}
