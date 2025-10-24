//
//  AlphabeticalGrouping.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/24/25.
//

import Foundation

/// Result of alphabetical grouping operation
struct AlphabeticalGrouping<T> {
    /// Dictionary mapping section titles (letters or "#") to items
    let grouped: [String: [T]]

    /// Sorted section titles with "#" at the end (if present)
    let sortedSectionTitles: [String]
}

/// Utility for grouping items alphabetically by a string property
struct AlphabeticalGrouper {

    /// Groups items alphabetically by the first letter of a string property
    /// - Parameters:
    ///   - items: The items to group
    ///   - keyPath: KeyPath to the string property to use for grouping (e.g., \.title)
    /// - Returns: AlphabeticalGrouping containing grouped dictionary and sorted section titles
    static func group<T>(_ items: [T], by keyPath: KeyPath<T, String>) -> AlphabeticalGrouping<T> {
        // Group items by first letter
        let grouped = Dictionary(grouping: items) { item in
            let value = item[keyPath: keyPath]
            let firstChar = value.prefix(1).uppercased()

            // Check if it's a letter
            if firstChar.rangeOfCharacter(from: .letters) != nil {
                return firstChar
            } else {
                return "#"
            }
        }

        // Sort section titles and move "#" to the end
        var titles = grouped.keys.sorted()
        if let hashIndex = titles.firstIndex(of: "#") {
            titles.remove(at: hashIndex)
            titles.append("#")
        }

        return AlphabeticalGrouping(grouped: grouped, sortedSectionTitles: titles)
    }
}
