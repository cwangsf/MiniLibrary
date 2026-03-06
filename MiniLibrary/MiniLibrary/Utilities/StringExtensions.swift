//
//  StringExtensions.swift
//  MiniLibrary
//
//  Created by Claude on 2026-03-06.
//

import Foundation

extension String {
    /// Trims whitespace and returns nil if the result is empty
    /// Use this for optional string fields that should be nil instead of empty
    nonisolated var trimmedOrNil: String? {
        let trimmed = self.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }
    
    /// Trims whitespace from the string
    /// Use this when you need the trimmed value but want to keep empty strings
    nonisolated var trimmed: String {
        self.trimmingCharacters(in: .whitespaces)
    }
}
