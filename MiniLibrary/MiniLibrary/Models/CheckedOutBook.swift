//
//  CheckedOutBook.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import Foundation
import SwiftData

@Model
final class CheckedOutBook: Codable {
    @Attribute(.unique) var id: UUID
    var checkoutDate: Date
    var dueDate: Date
    var returnDate: Date?
    var checkedOutByStaffId: String

    @Relationship var student: Student?
    @Relationship var book: Book?

    init(
        id: UUID = UUID(),
        student: Student,
        book: Book,
        checkoutDate: Date = Date(),
        dueDate: Date,
        checkedOutByStaffId: String
    ) {
        self.id = id
        self.student = student
        self.book = book
        self.checkoutDate = checkoutDate
        self.dueDate = dueDate
        self.checkedOutByStaffId = checkedOutByStaffId
    }

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id = "checkout_id"
        case checkoutDate = "checkout_date"
        case dueDate = "due_date"
        case returnDate = "return_date"
        case checkedOutByStaffId = "checked_out_by_staff_id"
        case studentId = "library_id"
        case bookId = "book_id"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.checkoutDate = try container.decode(Date.self, forKey: .checkoutDate)
        self.dueDate = try container.decode(Date.self, forKey: .dueDate)
        self.returnDate = try container.decodeIfPresent(Date.self, forKey: .returnDate)
        self.checkedOutByStaffId = try container.decode(String.self, forKey: .checkedOutByStaffId)
        // Note: student and book relationships will need to be resolved separately
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(checkoutDate, forKey: .checkoutDate)
        try container.encode(dueDate, forKey: .dueDate)
        try container.encodeIfPresent(returnDate, forKey: .returnDate)
        try container.encode(checkedOutByStaffId, forKey: .checkedOutByStaffId)
        try container.encodeIfPresent(student?.libraryId, forKey: .studentId)
        try container.encodeIfPresent(book?.id, forKey: .bookId)
    }

    // MARK: - Helper Properties
    var isOverdue: Bool {
        guard returnDate == nil else { return false }
        return Date() > dueDate
    }

    var isActive: Bool {
        returnDate == nil
    }
}
