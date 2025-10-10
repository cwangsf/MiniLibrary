//
//  Student.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import Foundation
import SwiftData

@Model
final class Student: Codable {
    @Attribute(.unique) var libraryId: String
    var gradeLevel: Int?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \CheckedOutBook.student)
    var checkouts: [CheckedOutBook]?

    init(libraryId: String, gradeLevel: Int? = nil, createdAt: Date = Date()) {
        self.libraryId = libraryId
        self.gradeLevel = gradeLevel
        self.createdAt = createdAt
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case libraryId = "library_id"
        case gradeLevel = "grade_level"
        case createdAt = "created_at"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.libraryId = try container.decode(String.self, forKey: .libraryId)
        self.gradeLevel = try container.decodeIfPresent(Int.self, forKey: .gradeLevel)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(libraryId, forKey: .libraryId)
        try container.encodeIfPresent(gradeLevel, forKey: .gradeLevel)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
