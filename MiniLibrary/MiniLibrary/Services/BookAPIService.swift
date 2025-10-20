//
//  BookAPIService.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import Foundation

// MARK: - API Service Actor (Thread-safe)
actor BookAPIService {
    static let shared = BookAPIService()

    private let session: URLSession
    private nonisolated let decoder: JSONDecoder

    // MARK: - Constants
    private static let baseURL = "https://www.googleapis.com/books/v1/volumes"

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: config)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    // MARK: - URL Builders
    private func buildISBNSearchURL(_ isbn: String) -> URL? {
        let urlString = "\(Self.baseURL)?q=isbn:\(isbn)"
        return URL(string: urlString)
    }

    private func buildTitleAuthorSearchURL(title: String, author: String) -> URL? {
        var queryComponents: [String] = []

        if !title.isEmpty {
            let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title
            queryComponents.append("intitle:\(encodedTitle)")
        }

        if !author.isEmpty {
            let encodedAuthor = author.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? author
            queryComponents.append("inauthor:\(encodedAuthor)")
        }

        guard !queryComponents.isEmpty else {
            return nil
        }

        let query = queryComponents.joined(separator: "+")
        let urlString = "\(Self.baseURL)?q=\(query)&maxResults=5"
        return URL(string: urlString)
    }

    /// Fetch book info from Google Books API by ISBN
    func fetchBookInfoFromGoogle(isbn: String) async throws -> Book {
        guard let url = buildISBNSearchURL(isbn) else {
            throw BookAPIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BookAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw BookAPIError.httpError(statusCode: httpResponse.statusCode)
        }

        let googleResponse = try decoder.decode(GoogleBooksResponse.self, from: data)

        guard let firstItem = googleResponse.items?.first else {
            throw BookAPIError.bookNotFound
        }

        return parseGoogleBookData(firstItem, isbn: isbn)
    }

    /// Search for books by ISBN
    func searchBooksByISBN(_ isbn: String) async throws -> [GoogleBookItem] {
        guard let url = buildISBNSearchURL(isbn) else {
            throw BookAPIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BookAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw BookAPIError.httpError(statusCode: httpResponse.statusCode)
        }

        let googleResponse = try decoder.decode(GoogleBooksResponse.self, from: data)

        guard let items = googleResponse.items, !items.isEmpty else {
            throw BookAPIError.bookNotFound
        }

        return items
    }

    /// Search for books by title and author
    func searchBooksByTitleAndAuthor(title: String, author: String) async throws -> [GoogleBookItem] {
        guard let url = buildTitleAuthorSearchURL(title: title, author: author) else {
            throw BookAPIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BookAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw BookAPIError.httpError(statusCode: httpResponse.statusCode)
        }

        let googleResponse = try decoder.decode(GoogleBooksResponse.self, from: data)

        guard let items = googleResponse.items, !items.isEmpty else {
            throw BookAPIError.bookNotFound
        }

        return items
    }

    // MARK: - Private Helpers
    private func parseGoogleBookData(_ item: GoogleBookItem, isbn: String?) -> Book {
        let volumeInfo = item.volumeInfo

        return Book(
            isbn: isbn,
            title: volumeInfo.title,
            author: volumeInfo.authors?.joined(separator: ", ") ?? "Unknown Author",
            totalCopies: 1,
            availableCopies: 1,
            bookDescription: volumeInfo.description,
            pageCount: volumeInfo.pageCount,
            publishedDate: volumeInfo.publishedDate,
            publisher: volumeInfo.publisher,
            languageCode: volumeInfo.language,
            coverImageURL: volumeInfo.imageLinks?.thumbnail
        )
    }

    /// Convert GoogleBookItem to Book for wishlist
    nonisolated func createBookFromSearchResult(_ item: GoogleBookItem, isWishlistItem: Bool = false) -> Book {
        let volumeInfo = item.volumeInfo
        let isbn = volumeInfo.industryIdentifiers?.first(where: { $0.type == "ISBN_13" || $0.type == "ISBN_10" })?.identifier

        return Book(
            isbn: isbn,
            title: volumeInfo.title,
            author: volumeInfo.authors?.joined(separator: ", ") ?? "Unknown Author",
            totalCopies: isWishlistItem ? 0 : 1,
            availableCopies: isWishlistItem ? 0 : 1,
            bookDescription: volumeInfo.description,
            pageCount: volumeInfo.pageCount,
            publishedDate: volumeInfo.publishedDate,
            publisher: volumeInfo.publisher,
            languageCode: volumeInfo.language,
            coverImageURL: volumeInfo.imageLinks?.thumbnail,
            isWishlistItem: isWishlistItem
        )
    }

    // MARK: - Cover Image Methods

    /// Update book with cover image and metadata if not present
    /// Downloads and caches the cover image locally
    /// Works with ISBN or title/author search
    @MainActor
    func updateBookCover(_ book: Book) async {
        // Skip if already has cached cover
        guard book.cachedCoverImage == nil else {
            return
        }

        do {
            var coverURL: String?
            var updatedMetadata: GoogleBookItem?

            // Try ISBN search first if available
            if let isbn = book.isbn {
                let items = try await searchBooksByISBN(isbn)
                if let firstItem = items.first {
                    coverURL = firstItem.volumeInfo.imageLinks?.thumbnail
                    updatedMetadata = firstItem
                }
            }

            // Fall back to title/author search if no ISBN or ISBN search failed
            if coverURL == nil {
                // Don't include "Unknown Author" in search - it won't find results
                let searchAuthor = (book.author == "Unknown Author") ? "" : book.author

                let items = try await searchBooksByTitleAndAuthor(
                    title: book.title,
                    author: searchAuthor
                )
                if let firstItem = items.first {
                    coverURL = firstItem.volumeInfo.imageLinks?.thumbnail
                    updatedMetadata = firstItem
                }
            }

            // Download and cache the cover image
            if let coverURL = coverURL {
                // Store the remote URL for reference
                book.coverImageURL = coverURL

                // Convert HTTP to HTTPS for ATS compliance
                let secureURL = coverURL.replacingOccurrences(of: "http://", with: "https://")

                // Download and cache the image
                if let cachedFilename = try await ImageCacheService.shared.cacheImage(
                    from: secureURL,
                    for: book.id.uuidString
                ) {
                    book.cachedCoverImage = cachedFilename
                    print("✓ Cached cover for: \(book.title)")
                }
            }

            // Also update other metadata if book doesn't have it (useful for wishlist items)
            if let metadata = updatedMetadata {
                let volumeInfo = metadata.volumeInfo

                if book.isbn == nil,
                   let isbn = volumeInfo.industryIdentifiers?.first(where: { $0.type == "ISBN_13" || $0.type == "ISBN_10" })?.identifier {
                    book.isbn = isbn
                }

                if book.bookDescription == nil {
                    book.bookDescription = volumeInfo.description
                }

                if book.pageCount == nil {
                    book.pageCount = volumeInfo.pageCount
                }

                if book.publishedDate == nil {
                    book.publishedDate = volumeInfo.publishedDate
                }

                if book.publisher == nil {
                    book.publisher = volumeInfo.publisher
                }

                if book.languageCode == nil {
                    book.languageCode = volumeInfo.language
                }

                // Update author if it was "Unknown Author"
                if book.author == "Unknown Author",
                   let authors = volumeInfo.authors,
                   !authors.isEmpty {
                    book.author = authors.joined(separator: ", ")
                }
            }
        } catch {
            print("Failed to fetch/cache cover for '\(book.title)' by \(book.author): \(error)")
        }
    }
}

// MARK: - Google Books Response Models
struct GoogleBooksResponse: Codable, Sendable {
    let items: [GoogleBookItem]?
}

struct GoogleBookItem: Codable, Sendable {
    let volumeInfo: VolumeInfo
}

struct VolumeInfo: Codable, Sendable {
    let title: String
    let authors: [String]?
    let description: String?
    let pageCount: Int?
    let publishedDate: String?
    let publisher: String?
    let language: String?
    let imageLinks: ImageLinks?
    let industryIdentifiers: [IndustryIdentifier]?
}

struct IndustryIdentifier: Codable, Sendable {
    let type: String
    let identifier: String
}

struct ImageLinks: Codable, Sendable {
    let thumbnail: String?
}

// MARK: - Errors
enum BookAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidData
    case bookNotFound
    case httpError(statusCode: Int)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .invalidData:
            return "Could not parse book data"
        case .bookNotFound:
            return "Book not found"
        case .httpError(let statusCode):
            return "Server error: \(statusCode)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
