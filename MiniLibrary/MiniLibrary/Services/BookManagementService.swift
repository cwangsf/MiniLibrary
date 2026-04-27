//
//  BookManagementService.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/24/25.
//

import Foundation
import SwiftData

/// Service for managing book operations like checkout and return
@MainActor
struct BookManagementService {

    /// Returns a checked out book and logs the activity
    /// - Parameters:
    ///   - checkout: The checkout record to mark as returned
    ///   - modelContext: The SwiftData model context
    static func returnBook(_ checkout: CheckoutRecord, modelContext: ModelContext) {
        // Update book availability before deleting the record
        if let book = checkout.book {
            book.availableCopies += 1
        }

        modelContext.delete(checkout)
    }
}
