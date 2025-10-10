//
//  User.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import Foundation
import SwiftData

enum UserRole: String, Codable {
    case admin
    case librarian
}

@Model
final class User: Codable {
    @Attribute(.unique) var id: UUID
    var email: String
    var role: UserRole
    var createdAt: Date

    init(
        id: UUID = UUID(),
        email: String,
        role: UserRole,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.role = role
        self.createdAt = createdAt
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case email
        case role
        case createdAt = "created_at"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.email = try container.decode(String.self, forKey: .email)
        self.role = try container.decode(UserRole.self, forKey: .role)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(role, forKey: .role)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
