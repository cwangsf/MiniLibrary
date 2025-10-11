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
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    /// Alternative: Fetch from Google Books API
    func fetchBookInfoFromGoogle(isbn: String) async throws -> Book {
        let urlString = "https://www.googleapis.com/books/v1/volumes?q=isbn:\(isbn)"

        guard let url = URL(string: urlString) else {
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

    // MARK: - Private Helpers
    private func parseGoogleBookData(_ item: GoogleBookItem, isbn: String) -> Book {
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
}

// MARK: - Google Books Response Models
struct GoogleBooksResponse: Codable {
    let items: [GoogleBookItem]?
}

struct GoogleBookItem: Codable {
    let volumeInfo: VolumeInfo
}

struct VolumeInfo: Codable {
    let title: String
    let authors: [String]?
    let description: String?
    let pageCount: Int?
    let publishedDate: String?
    let publisher: String?
    let language: String?
    let imageLinks: ImageLinks?
}

struct ImageLinks: Codable {
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
