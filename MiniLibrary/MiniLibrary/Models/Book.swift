//
//  Book.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import Foundation
import SwiftData

@Model
final class Book: Codable {
    @Attribute(.unique) var id: UUID
    var isbn: String?
    var title: String
    var author: String
    var totalCopies: Int
    var availableCopies: Int
    var createdAt: Date

    // Optional metadata from API
    var bookDescription: String?
    var pageCount: Int?
    var publishedDate: String?
    var publisher: String?
    var coverImageURL: String?

    @Relationship(deleteRule: .nullify, inverse: \CheckoutRecord.book)
    var checkouts: [CheckoutRecord]?

    init(
        id: UUID = UUID(),
        isbn: String? = nil,
        title: String,
        author: String,
        totalCopies: Int,
        availableCopies: Int? = nil,
        createdAt: Date = Date(),
        bookDescription: String? = nil,
        pageCount: Int? = nil,
        publishedDate: String? = nil,
        publisher: String? = nil,
        coverImageURL: String? = nil
    ) {
        self.id = id
        self.isbn = isbn
        self.title = title
        self.author = author
        self.totalCopies = totalCopies
        self.availableCopies = availableCopies ?? totalCopies
        self.createdAt = createdAt
        self.bookDescription = bookDescription
        self.pageCount = pageCount
        self.publishedDate = publishedDate
        self.publisher = publisher
        self.coverImageURL = coverImageURL
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id = "book_id"
        case isbn
        case title
        case author
        case totalCopies = "total_copies"
        case availableCopies = "available_copies"
        case createdAt = "created_at"
        case bookDescription = "description"
        case pageCount = "page_count"
        case publishedDate = "published_date"
        case publisher
        case coverImageURL = "cover_image_url"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.isbn = try container.decodeIfPresent(String.self, forKey: .isbn)
        self.title = try container.decode(String.self, forKey: .title)
        self.author = try container.decode(String.self, forKey: .author)
        self.totalCopies = try container.decode(Int.self, forKey: .totalCopies)
        self.availableCopies = try container.decode(Int.self, forKey: .availableCopies)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.bookDescription = try container.decodeIfPresent(String.self, forKey: .bookDescription)
        self.pageCount = try container.decodeIfPresent(Int.self, forKey: .pageCount)
        self.publishedDate = try container.decodeIfPresent(String.self, forKey: .publishedDate)
        self.publisher = try container.decodeIfPresent(String.self, forKey: .publisher)
        self.coverImageURL = try container.decodeIfPresent(String.self, forKey: .coverImageURL)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(isbn, forKey: .isbn)
        try container.encode(title, forKey: .title)
        try container.encode(author, forKey: .author)
        try container.encode(totalCopies, forKey: .totalCopies)
        try container.encode(availableCopies, forKey: .availableCopies)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(bookDescription, forKey: .bookDescription)
        try container.encodeIfPresent(pageCount, forKey: .pageCount)
        try container.encodeIfPresent(publishedDate, forKey: .publishedDate)
        try container.encodeIfPresent(publisher, forKey: .publisher)
        try container.encodeIfPresent(coverImageURL, forKey: .coverImageURL)
    }
}
