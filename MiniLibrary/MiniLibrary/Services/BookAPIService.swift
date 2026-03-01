//
//  BookAPIService.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import Foundation
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MiniLibrary", category: "BookAPIService")

// MARK: - Concurrent Load Limiter
/// Actor to limit concurrent cover image loads to prevent overwhelming older devices
actor CoverLoadLimiter {
    static let shared = CoverLoadLimiter()
    
    private var activeLoads = 0
    private let maxConcurrentLoads = 3 // Only 3 concurrent loads at a time
    
    private init() {}
    
    /// Wait for a slot to become available before loading
    func waitForSlot() async {
        while activeLoads >= maxConcurrentLoads {
            try? await Task.sleep(for: .milliseconds(100))
        }
        activeLoads += 1
    }
    
    /// Release a slot when done loading
    func releaseSlot() {
        activeLoads = max(0, activeLoads - 1)
    }
}

// MARK: - API Service (Stateless)
struct BookAPIService {
    static let shared = BookAPIService()

    private let session: URLSession
    private let decoder: JSONDecoder

    // MARK: - Constants
    private static let baseURL = "https://www.googleapis.com/books/v1/volumes"
    private static let openLibraryBaseURL = "https://covers.openlibrary.org/b/isbn"

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
    
    // MARK: - Open Library Cover Methods
    
    /// Build Open Library cover URL for a given ISBN
    /// Size options: S (small), M (medium), L (large)
    /// Automatically selects size based on device capability
    private func buildOpenLibraryCoverURL(_ isbn: String) -> URL? {
        // Use large images for capable devices, small for low-memory devices
        let size = DeviceCapability.shared.supportsRichMedia ? "L" : "S"
        let urlString = "\(Self.openLibraryBaseURL)/\(isbn)-\(size).jpg"
        return URL(string: urlString)
    }
    
    /// Get Open Library cover URL directly (no validation - let caching handle failures)
    /// Returns the URL string immediately without checking if it exists
    private func getOpenLibraryCoverURL(_ isbn: String) -> String? {
        return buildOpenLibraryCoverURL(isbn)?.absoluteString
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
    
    /// Convert HTTP URLs to HTTPS for App Transport Security
    private func makeSecureURL(_ urlString: String?) -> String? {
        guard let urlString = urlString, !urlString.isEmpty else { return nil }
        
        if urlString.hasPrefix("http://") {
            return urlString.replacingOccurrences(of: "http://", with: "https://")
        }
        
        return urlString
    }
    
    private func parseGoogleBookData(_ item: GoogleBookItem, isbn: String?) -> Book {
        let volumeInfo = item.volumeInfo
        
        logger.debug("📖 Google Books API Response:")
        logger.debug("  Title: '\(volumeInfo.title)'")
        logger.debug("  Subtitle: '\(volumeInfo.subtitle ?? "nil")'")
        logger.debug("  Full Title: '\(volumeInfo.fullTitle)'")
        logger.debug("  Authors: \(volumeInfo.authors?.joined(separator: ", ") ?? "nil")")

        return Book(
            isbn: isbn,
            title: volumeInfo.fullTitle,
            author: volumeInfo.authors?.joined(separator: ", "),
            totalCopies: 1,
            availableCopies: 1,
            bookDescription: volumeInfo.description,
            pageCount: volumeInfo.pageCount,
            publishedDate: volumeInfo.publishedDate,
            publisher: volumeInfo.publisher,
            languageCode: volumeInfo.language,
            coverImageURL: makeSecureURL(volumeInfo.imageLinks?.thumbnail)
        )
    }

    /// Convert GoogleBookItem to Book for wishlist
    func createBookFromSearchResult(_ item: GoogleBookItem, isWishlistItem: Bool = false) -> Book {
        let volumeInfo = item.volumeInfo
        let isbn = volumeInfo.industryIdentifiers?.first(where: { $0.type == "ISBN_13" || $0.type == "ISBN_10" })?.identifier

        return Book(
            isbn: isbn,
            title: volumeInfo.fullTitle,
            author: volumeInfo.authors?.joined(separator: ", "),
            totalCopies: isWishlistItem ? 0 : 1,
            availableCopies: isWishlistItem ? 0 : 1,
            bookDescription: volumeInfo.description,
            pageCount: volumeInfo.pageCount,
            publishedDate: volumeInfo.publishedDate,
            publisher: volumeInfo.publisher,
            languageCode: volumeInfo.language,
            coverImageURL: makeSecureURL(volumeInfo.imageLinks?.thumbnail),
            isWishlistItem: isWishlistItem
        )
    }

    // MARK: - Cover Image Methods

    /// Update book with cover image and metadata if not present
    /// Downloads and caches the cover image locally
    /// Works with ISBN or title/author search
    func updateBookCover(_ book: Book) async {
        // Skip cover fetching for wishlist items (performance optimization)
        guard !book.isWishlistItem else {
            logger.info("⏭️ Skipping cover fetch for wishlist item: '\(book.title)'")
            return
        }
        
        // Skip if already has cached cover
        guard book.cachedCoverImage == nil else {
            return
        }
        
        // Wait for an available slot to prevent overwhelming the device
        await CoverLoadLimiter.shared.waitForSlot()
        defer {
            Task {
                await CoverLoadLimiter.shared.releaseSlot()
            }
        }

        // Only use Open Library for cover images (no rate limits, reliable)
        if let isbn = book.isbn, let openLibraryCover = getOpenLibraryCoverURL(isbn) {
            // Try to download and cache immediately
            let secureURL = openLibraryCover.replacingOccurrences(of: "http://", with: "https://")
            do {
                if let cachedFilename = try await ImageCacheService.shared.cacheImage(
                    from: secureURL,
                    for: book.id.uuidString
                ) {
                    book.coverImageURL = openLibraryCover
                    book.cachedCoverImage = cachedFilename
                    logger.info("✅ Successfully cached cover for '\(book.title)' (ISBN: \(isbn)) - File: \(cachedFilename)")
                } else {
                    // Validation failed - invalid or missing image
                    logger.warning("⚠️ No valid cover image for '\(book.title)' (ISBN: \(isbn)) - Open Library returned invalid/missing image")
                }
            } catch {
                let authorInfo = book.author.map { " by \($0)" } ?? ""
                logger.error("❌ Failed to download cover for '\(book.title)'\(authorInfo) (ISBN: \(isbn)) - Error: \(error.localizedDescription)")
            }
        } else {
            // No ISBN available
            let authorInfo = book.author.map { " by \($0)" } ?? ""
            logger.info("⏭️ Skipping cover download for '\(book.title)'\(authorInfo) - No ISBN available")
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
    let subtitle: String?
    let authors: [String]?
    let description: String?
    let pageCount: Int?
    let publishedDate: String?
    let publisher: String?
    let language: String?
    let imageLinks: ImageLinks?
    let industryIdentifiers: [IndustryIdentifier]?
    
    /// Combined title with subtitle if available
    var fullTitle: String {
        if let subtitle = subtitle, !subtitle.isEmpty {
            return "\(title): \(subtitle)"
        }
        return title
    }
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
