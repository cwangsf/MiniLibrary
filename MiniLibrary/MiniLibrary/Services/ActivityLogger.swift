//
//  ActivityLogger.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/24/25.
//

import Foundation
import SwiftData

/// Service for logging user activities in the library system
@MainActor
struct ActivityLogger {

    // MARK: - Book Activities

    /// Logs when a book is added to the catalog
    /// - Parameters:
    ///   - book: The book that was added
    ///   - copies: Number of copies added
    ///   - modelContext: The SwiftData model context
    static func logBookAdded(_ book: Book, copies: Int, modelContext: ModelContext) {
        let activity = Activity(
            type: .addBook,
            bookTitle: book.title,
            bookAuthor: book.author,
            additionalInfo: "\(copies) \(copies == 1 ? "copy" : "copies")"
        )
        modelContext.insert(activity)
    }

    /// Logs when additional copies are added to an existing book
    /// - Parameters:
    ///   - book: The book that received additional copies
    ///   - copies: Number of copies added
    ///   - modelContext: The SwiftData model context
    static func logCopiesAdded(_ book: Book, copies: Int, modelContext: ModelContext) {
        let activity = Activity(
            type: .addBook,
            bookTitle: book.title,
            bookAuthor: book.author,
            additionalInfo: "Added \(copies) more \(copies == 1 ? "copy" : "copies")"
        )
        modelContext.insert(activity)
    }

    // MARK: - Checkout Activities

    /// Logs when a book is checked out
    /// - Parameters:
    ///   - book: The book being checked out
    ///   - student: The student checking out the book
    ///   - dueDate: The due date for the checkout
    ///   - modelContext: The SwiftData model context
    static func logCheckout(_ book: Book, student: Student, dueDate: Date, modelContext: ModelContext) {
        let activity = Activity(
            type: .checkout,
            bookTitle: book.title,
            bookAuthor: book.author,
            studentLibraryId: student.libraryId,
            additionalInfo: "Due \(dueDate.formatted(date: .abbreviated, time: .omitted))"
        )
        modelContext.insert(activity)
    }

    /// Logs when a book is returned
    /// - Parameters:
    ///   - book: The book being returned
    ///   - studentLibraryId: The library ID of the student returning the book (optional)
    ///   - modelContext: The SwiftData model context
    static func logReturn(_ book: Book, studentLibraryId: String?, modelContext: ModelContext) {
        let activity = Activity(
            type: .return,
            bookTitle: book.title,
            bookAuthor: book.author,
            studentLibraryId: studentLibraryId,
            additionalInfo: nil
        )
        modelContext.insert(activity)
    }

    // MARK: - Wishlist Activities

    /// Logs when a book is added to the wishlist
    /// - Parameters:
    ///   - book: The book added to the wishlist
    ///   - modelContext: The SwiftData model context
    static func logWishlistAdded(_ book: Book, modelContext: ModelContext) {
        let activity = Activity(
            type: .addWishlist,
            bookTitle: book.title,
            bookAuthor: book.author,
            additionalInfo: nil
        )
        modelContext.insert(activity)
    }

    /// Logs when a book is added to the wishlist manually (without API data)
    /// - Parameters:
    ///   - book: The book added to the wishlist
    ///   - modelContext: The SwiftData model context
    static func logWishlistAddedManually(_ book: Book, modelContext: ModelContext) {
        let activity = Activity(
            type: .addWishlist,
            bookTitle: book.title,
            bookAuthor: book.author,
            additionalInfo: "Added manually"
        )
        modelContext.insert(activity)
    }

    /// Logs when multiple books are added to the wishlist in bulk
    /// - Parameters:
    ///   - count: Number of books added
    ///   - modelContext: The SwiftData model context
    static func logWishlistBulkAdd(count: Int, modelContext: ModelContext) {
        let activity = Activity(
            type: .addWishlist,
            bookTitle: "Bulk Add",
            bookAuthor: "Google Books Search",
            additionalInfo: "\(count) book\(count == 1 ? "" : "s") added"
        )
        modelContext.insert(activity)
    }

    /// Logs when a wishlist item is acquired (moved to catalog)
    /// - Parameters:
    ///   - book: The book being acquired
    ///   - copies: Number of copies acquired
    ///   - modelContext: The SwiftData model context
    static func logWishlistFulfilled(_ book: Book, copies: Int, modelContext: ModelContext) {
        let activity = Activity(
            type: .fulfillWishlist,
            bookTitle: book.title,
            bookAuthor: book.author,
            additionalInfo: "\(copies) \(copies == 1 ? "copy" : "copies")"
        )
        modelContext.insert(activity)
    }

    // MARK: - CSV Import Activities

    /// Logs when books are imported from CSV to the catalog
    /// - Parameters:
    ///   - count: Number of books imported
    ///   - modelContext: The SwiftData model context
    static func logCatalogCSVImport(count: Int, modelContext: ModelContext) {
        let activity = Activity(
            type: .addBook,
            bookTitle: "Import",
            bookAuthor: "CSV Import",
            additionalInfo: "\(count) book\(count == 1 ? "" : "s") imported"
        )
        modelContext.insert(activity)
    }

    /// Logs when books are imported from CSV to the wishlist
    /// - Parameters:
    ///   - count: Number of books imported
    ///   - modelContext: The SwiftData model context
    static func logWishlistCSVImport(count: Int, modelContext: ModelContext) {
        let activity = Activity(
            type: .addWishlist,
            bookTitle: "Import",
            bookAuthor: "CSV Import",
            additionalInfo: "\(count) book\(count == 1 ? "" : "s") imported"
        )
        modelContext.insert(activity)
    }
}
