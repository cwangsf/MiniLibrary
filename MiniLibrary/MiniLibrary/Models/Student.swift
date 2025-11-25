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
    var firstName: String
    var lastName: String
    var classCode: String?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \CheckoutRecord.student)
    var checkouts: [CheckoutRecord]?

    var fullName: String {
        "\(firstName) \(lastName)"
    }

    init(firstName: String, lastName: String, classCode: String? = nil, createdAt: Date = Date()) {
        self.firstName = firstName
        self.lastName = lastName
        self.classCode = classCode
        self.createdAt = createdAt
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case classCode = "class_code"
        case createdAt = "created_at"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.firstName = try container.decode(String.self, forKey: .firstName)
        self.lastName = try container.decode(String.self, forKey: .lastName)
        self.classCode = try container.decodeIfPresent(String.self, forKey: .classCode)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encodeIfPresent(classCode, forKey: .classCode)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
