//
//  ScanBookViewModel.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import Foundation
import Observation

@Observable
class ScanBookViewModel {
    enum ScanState: Equatable {
        case scanning
        case loading(isbn: String)
        case confirming(book: Book)
        case editing(book: Book?)
        case existingBook(book: Book)
        case error(message: String)

        static func == (lhs: ScanState, rhs: ScanState) -> Bool {
            switch (lhs, rhs) {
            case (.scanning, .scanning):
                return true
            case (.loading(let lhsISBN), .loading(let rhsISBN)):
                return lhsISBN == rhsISBN
            case (.confirming(let lhsBook), .confirming(let rhsBook)):
                return lhsBook.id == rhsBook.id
            case (.editing(let lhsBook), .editing(let rhsBook)):
                return lhsBook?.id == rhsBook?.id
            case (.existingBook(let lhsBook), .existingBook(let rhsBook)):
                return lhsBook.id == rhsBook.id
            case (.error(let lhsMessage), .error(let rhsMessage)):
                return lhsMessage == rhsMessage
            default:
                return false
            }
        }
    }

    var state: ScanState = .scanning
    var scannedBook: Book?
    var existingBook: Book?

    var title = ""
    var author = ""
    var isbn = ""
    var totalCopies = 1

    func handleScannedCode(_ code: String, existingBook: Book?) {
        isbn = code

        // Check if book already exists in catalog
        if let existing = existingBook {
            self.existingBook = existing
            state = .existingBook(book: existing)
            return
        }

        state = .loading(isbn: code)
        Task {
            await fetchBookInfo(isbn: code)
        }
    }

    @MainActor
    func fetchBookInfo(isbn: String) async {
        do {
            // Try Google Books API first (more reliable)
            let book = try await BookAPIService.shared.fetchBookInfoFromGoogle(isbn: isbn)
            scannedBook = book
            title = book.title
            author = book.author
            self.isbn = book.isbn ?? isbn

            print("Debug: Fetched book - Title: \(book.title), Author: \(book.author), ISBN: \(book.isbn ?? "nil")")
            print("Debug: ViewModel - Title: \(title), Author: \(author), ISBN: \(self.isbn)")

            state = .confirming(book: book)
        } catch {
            let errorMsg = "Could not fetch book info: \(error.localizedDescription)"
            print("Debug: API Error - \(error)")
            state = .error(message: errorMsg)
        }
    }

    func confirmBook() {
        if let book = scannedBook {
            state = .editing(book: book)
        }
    }

    func reset() {
        state = .scanning
        scannedBook = nil
        title = ""
        author = ""
        isbn = ""
        totalCopies = 1
    }

    func enterManualMode() {
        state = .editing(book: nil)
    }
}
