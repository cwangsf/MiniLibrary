//
//  Activity.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import Foundation
import SwiftData

@Model
final class Activity {
    @Attribute(.unique) var id: UUID
    var type: ActivityType
    var timestamp: Date
    var bookTitle: String?
    var bookAuthor: String?
    var studentLibraryId: String?
    var additionalInfo: String?

    init(
        id: UUID = UUID(),
        type: ActivityType,
        timestamp: Date = Date(),
        bookTitle: String? = nil,
        bookAuthor: String? = nil,
        studentLibraryId: String? = nil,
        additionalInfo: String? = nil
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.bookTitle = bookTitle
        self.bookAuthor = bookAuthor
        self.studentLibraryId = studentLibraryId
        self.additionalInfo = additionalInfo
    }
}

enum ActivityType: String, Codable {
    case checkout = "checkout"
    case `return` = "return_book"
    case addBook = "add_book"
    case addWishlist = "add_wishlist"
    case fulfillWishlist = "fulfill_wishlist"

    var icon: String {
        switch self {
        case .checkout:
            return "arrow.right.circle.fill"
        case .return:
            return "arrow.uturn.left.circle.fill"
        case .addBook:
            return "plus.circle.fill"
        case .addWishlist:
            return "list.star"
        case .fulfillWishlist:
            return "checkmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .checkout:
            return "blue"
        case .return:
            return "green"
        case .addBook:
            return "purple"
        case .addWishlist:
            return "pink"
        case .fulfillWishlist:
            return "green"
        }
    }

    var description: String {
        switch self {
        case .checkout:
            return "Checked out"
        case .return:
            return "Returned"
        case .addBook:
            return "Added to catalog"
        case .addWishlist:
            return "Added to wishlist"
        case .fulfillWishlist:
            return "Fulfilled wishlist item"
        }
    }
}
