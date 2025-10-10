//
//  BookAPIService.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import Foundation

// MARK: - Book Info Response Models
struct BookInfo: Codable {
    let title: String
    let author: String
    let isbn: String?
    let description: String?
    let pageCount: Int?
    let publishedDate: String?
    let publisher: String?
    let coverImageURL: String?
}

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

    /// Fetch book information by ISBN from Open Library API
    func fetchBookInfo(isbn: String) async throws -> BookInfo {
        let urlString = "https://openlibrary.org/api/books?bibkeys=ISBN:\(isbn)&format=json&jscmd=data"

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

        // Parse Open Library response
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let bookData = json?["ISBN:\(isbn)"] as? [String: Any] else {
            throw BookAPIError.bookNotFound
        }

        return try parseOpenLibraryData(bookData, isbn: isbn)
    }

    /// Alternative: Fetch from Google Books API
    func fetchBookInfoFromGoogle(isbn: String) async throws -> BookInfo {
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
    private func parseOpenLibraryData(_ data: [String: Any], isbn: String) throws -> BookInfo {
        guard let title = data["title"] as? String else {
            throw BookAPIError.invalidData
        }

        let authors = data["authors"] as? [[String: Any]]
        let author = authors?.first?["name"] as? String ?? "Unknown Author"

        let description = data["notes"] as? String

        let pageCount = data["number_of_pages"] as? Int

        let publishedDate = data["publish_date"] as? String

        let publishers = data["publishers"] as? [[String: String]]
        let publisher = publishers?.first?["name"]

        let cover = data["cover"] as? [String: String]
        let coverImageURL = cover?["large"] ?? cover?["medium"] ?? cover?["small"]

        return BookInfo(
            title: title,
            author: author,
            isbn: isbn,
            description: description,
            pageCount: pageCount,
            publishedDate: publishedDate,
            publisher: publisher,
            coverImageURL: coverImageURL
        )
    }

    private func parseGoogleBookData(_ item: GoogleBookItem, isbn: String) -> BookInfo {
        let volumeInfo = item.volumeInfo

        return BookInfo(
            title: volumeInfo.title,
            author: volumeInfo.authors?.joined(separator: ", ") ?? "Unknown Author",
            isbn: isbn,
            description: volumeInfo.description,
            pageCount: volumeInfo.pageCount,
            publishedDate: volumeInfo.publishedDate,
            publisher: volumeInfo.publisher,
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
