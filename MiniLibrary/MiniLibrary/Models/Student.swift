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
    var classCode: String?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \CheckoutRecord.student)
    var checkouts: [CheckoutRecord]?

    init(libraryId: String, classCode: String? = nil, createdAt: Date = Date()) {
        self.libraryId = libraryId
        self.classCode = classCode
        self.createdAt = createdAt
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case libraryId = "library_id"
        case classCode = "class_code"
        case createdAt = "created_at"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.libraryId = try container.decode(String.self, forKey: .libraryId)
        self.classCode = try container.decodeIfPresent(String.self, forKey: .classCode)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(libraryId, forKey: .libraryId)
        try container.encodeIfPresent(classCode, forKey: .classCode)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
