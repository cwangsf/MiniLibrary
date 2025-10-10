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

    @Relationship(deleteRule: .nullify, inverse: \CheckoutRecord.book)
    var checkouts: [CheckoutRecord]?

    init(
        id: UUID = UUID(),
        isbn: String? = nil,
        title: String,
        author: String,
        totalCopies: Int,
        availableCopies: Int? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.isbn = isbn
        self.title = title
        self.author = author
        self.totalCopies = totalCopies
        self.availableCopies = availableCopies ?? totalCopies
        self.createdAt = createdAt
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
    }
}
