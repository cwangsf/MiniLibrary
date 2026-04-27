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
    private static let openLibraryAPIBaseURL = "https://openlibrary.org/api/books"

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

    /// Fetch book info by ISBN.
    /// Tries Open Library first, falls back to Google Books if Open Library fails.
    func fetchBookInfoFromGoogle(isbn: String) async throws -> Book {
        do {
            return try await fetchFromOpenLibrary(isbn: isbn)
        } catch let error as BookAPIError {
            logger.warning("Open Library API failed (\(error.errorDescription ?? "unknown error")), trying Google Books as fallback")
            return try await fetchFromGoogleAPI(isbn: isbn)
        } catch {
            logger.warning("Open Library API failed (\(error.localizedDescription)), trying Google Books as fallback")
            return try await fetchFromGoogleAPI(isbn: isbn)
        }
    }
    
    /// Fetch book info from Google Books API only (no fallback)
    private func fetchFromGoogleAPI(isbn: String) async throws -> Book {
        guard let url = buildISBNSearchURL(isbn) else {
            throw BookAPIError.invalidURL
        }
        logger.info("fetchFromGoogleAPI: (\(url))")

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
    
    /// Fetch book info from Open Library API by ISBN
    /// Returns basic book information from Open Library
    private func fetchFromOpenLibrary(isbn: String) async throws -> Book {
        // Build Open Library API URL: https://openlibrary.org/api/books?bibkeys=ISBN:9780980200447&format=json&jscmd=data
        let cleanedISBN = isbn.replacingOccurrences(of: "-", with: "")
        let urlString = "\(Self.openLibraryAPIBaseURL)?bibkeys=ISBN:\(cleanedISBN)&format=json&jscmd=data"
        
        logger.info("🔍 Attempting Open Library API: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            logger.error("❌ Open Library: Invalid URL")
            throw BookAPIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("❌ Open Library: Invalid response")
            throw BookAPIError.invalidResponse
        }
        
        logger.info("📡 Open Library HTTP Status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            logger.error("❌ Open Library: HTTP error \(httpResponse.statusCode)")
            throw BookAPIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Log raw response for debugging
        if let rawString = String(data: data, encoding: .utf8) {
            logger.debug("📥 Open Library raw response: \(rawString)")
        }
        
        // Parse Open Library response
        let openLibraryResponse = try JSONDecoder().decode([String: OpenLibraryBookData].self, from: data)
        
        logger.info("📦 Open Library response keys: \(openLibraryResponse.keys.joined(separator: ", "))")
        
        guard let bookData = openLibraryResponse["ISBN:\(cleanedISBN)"] else {
            logger.error("❌ Open Library: Book not found for ISBN:\(cleanedISBN)")
            logger.debug("Available keys in response: \(openLibraryResponse.keys.joined(separator: ", "))")
            throw BookAPIError.bookNotFound
        }
        
        logger.info("✅ Open Library: Found book data for ISBN:\(cleanedISBN)")
        return parseOpenLibraryBookData(bookData, isbn: cleanedISBN)
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
        
        let coverURL = makeSecureURL(volumeInfo.imageLinks?.thumbnail)
        if let coverURL = coverURL {
            logger.info("🖼️ Google Books provided cover URL: \(coverURL)")
        } else {
            logger.warning("⚠️ Google Books did NOT provide a cover URL for '\(volumeInfo.fullTitle)'")
        }

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
            coverImageURL: coverURL
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

        // Try to get cover URL - prefer existing coverImageURL from Google Books, fallback to Open Library
        var coverURL: String?
        var source: String = "Unknown"
        
        if let existingURL = book.coverImageURL {
            // Book already has a cover URL from Google Books API
            coverURL = existingURL
            source = "Google Books"
            logger.info("📸 Using existing Google Books cover URL for '\(book.title)'")
        } else if let isbn = book.isbn, let openLibraryCover = getOpenLibraryCoverURL(isbn) {
            // Fallback to Open Library if no existing URL
            coverURL = openLibraryCover
            source = "Open Library"
            logger.info("📚 Using Open Library cover URL for '\(book.title)' (ISBN: \(isbn))")
        }
        
        guard let coverURL = coverURL else {
            let authorInfo = book.author.map { " by \($0)" } ?? ""
            logger.info("⏭️ Skipping cover download for '\(book.title)'\(authorInfo) - No cover URL available")
            return
        }
        
        // Try to download and cache the cover
        let secureURL = coverURL.replacingOccurrences(of: "http://", with: "https://")
        do {
            if let cachedFilename = try await ImageCacheService.shared.cacheImage(
                from: secureURL,
                for: book.id.uuidString
            ) {
                book.coverImageURL = coverURL
                book.cachedCoverImage = cachedFilename
                logger.info("✅ Successfully cached \(source) cover for '\(book.title)' - File: \(cachedFilename)")
            } else {
                // Validation failed - invalid or missing image
                logger.warning("⚠️ No valid cover image for '\(book.title)' - \(source) returned invalid/missing image")
            }
        } catch {
            let authorInfo = book.author.map { " by \($0)" } ?? ""
            logger.error("❌ Failed to download \(source) cover for '\(book.title)'\(authorInfo) - Error: \(error.localizedDescription)")
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

// MARK: - Open Library Response Models
struct OpenLibraryBookData: Codable, Sendable {
    let title: String?
    let subtitle: String?
    let authors: [OpenLibraryAuthor]?
    let publishers: [OpenLibraryPublisher]?
    let publishDate: String?
    let numberOfPages: Int?
    let cover: OpenLibraryCover?
    
    private enum CodingKeys: String, CodingKey {
        case title
        case subtitle
        case authors
        case publishers
        case publishDate = "publish_date"
        case numberOfPages = "number_of_pages"
        case cover
    }
}

struct OpenLibraryAuthor: Codable, Sendable {
    let name: String?
}

struct OpenLibraryPublisher: Codable, Sendable {
    let name: String?
}

struct OpenLibraryCover: Codable, Sendable {
    let large: String?
    let medium: String?
    let small: String?
}

// MARK: - Open Library Parser
extension BookAPIService {
    private func parseOpenLibraryBookData(_ data: OpenLibraryBookData, isbn: String) -> Book {
        let title = data.title ?? "Unknown Title"
        let subtitle = data.subtitle
        
        let fullTitle: String
        if let subtitle = subtitle, !subtitle.isEmpty {
            fullTitle = "\(title): \(subtitle)"
        } else {
            fullTitle = title
        }
        
        let authors = data.authors?.compactMap { $0.name }.joined(separator: ", ")
        let publisher = data.publishers?.first?.name
        
        // Get cover image URL (prefer large, fall back to medium or small)
        let coverURL: String?
        if let large = data.cover?.large {
            coverURL = makeSecureURL(large)
        } else if let medium = data.cover?.medium {
            coverURL = makeSecureURL(medium)
        } else if let small = data.cover?.small {
            coverURL = makeSecureURL(small)
        } else {
            // Use Open Library cover URL as fallback
            coverURL = getOpenLibraryCoverURL(isbn)
        }
        
        logger.debug("📚 Open Library API Response:")
        logger.debug("  Title: '\(fullTitle)'")
        logger.debug("  Authors: \(authors ?? "nil")")
        logger.debug("  Publisher: \(publisher ?? "nil")")
        
        return Book(
            isbn: isbn,
            title: fullTitle,
            author: authors,
            totalCopies: 1,
            availableCopies: 1,
            bookDescription: nil, // Open Library doesn't provide description in this endpoint
            pageCount: data.numberOfPages,
            publishedDate: data.publishDate,
            publisher: publisher,
            languageCode: nil, // Open Library doesn't provide language in this endpoint
            coverImageURL: coverURL
        )
    }
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
