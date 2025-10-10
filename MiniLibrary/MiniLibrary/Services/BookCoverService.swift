//
//  BookCoverService.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import Foundation
import SwiftUI

actor BookCoverService {
    static let shared = BookCoverService()

    private let session: URLSession
    private var coverCache: [String: String] = [:] // ISBN -> coverURL

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        self.session = URLSession(configuration: config)
    }

    /// Fetch cover URL for a book by ISBN
    func fetchCoverURL(isbn: String) async throws -> String? {
        // Check cache first
        if let cached = coverCache[isbn] {
            return cached
        }

        // Try Google Books API
        let urlString = "https://www.googleapis.com/books/v1/volumes?q=isbn:\(isbn)"
        guard let url = URL(string: urlString) else {
            return nil
        }

        let (data, _) = try await session.data(from: url)
        let decoder = JSONDecoder()
        let response = try decoder.decode(GoogleBooksResponse.self, from: data)

        let coverURL = response.items?.first?.volumeInfo.imageLinks?.thumbnail

        // Cache the result
        if let coverURL = coverURL {
            coverCache[isbn] = coverURL
        }

        return coverURL
    }

    /// Update book with cover URL if not present
    @MainActor
    func updateBookCover(_ book: Book) async {
        // Skip if already has cover or no ISBN
        guard book.coverImageURL == nil,
              let isbn = book.isbn else {
            return
        }

        do {
            if let coverURL = try await fetchCoverURL(isbn: isbn) {
                book.coverImageURL = coverURL
            }
        } catch {
            print("Failed to fetch cover for ISBN \(isbn): \(error)")
        }
    }
}
