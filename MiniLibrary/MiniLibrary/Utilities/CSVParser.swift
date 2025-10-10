//
//  CSVParser.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import Foundation

struct CSVParser {
    /// Parse CSV file and return array of dictionaries (column name -> value)
    static func parse(fileURL: URL) throws -> [[String: String]] {
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        return parse(csvString: content)
    }

    /// Parse CSV string and return array of dictionaries (column name -> value)
    static func parse(csvString: String) -> [[String: String]] {
        var rows: [[String: String]] = []
        let lines = csvString.components(separatedBy: .newlines)

        guard let headerLine = lines.first else {
            return []
        }

        let headers = parseCSVLine(headerLine)

        for line in lines.dropFirst() {
            // Skip empty lines
            guard !line.trimmingCharacters(in: .whitespaces).isEmpty else {
                continue
            }

            let values = parseCSVLine(line)
            var row: [String: String] = [:]

            for (index, header) in headers.enumerated() {
                if index < values.count {
                    row[header] = values[index]
                }
            }

            rows.append(row)
        }

        return rows
    }

    /// Parse a single CSV line, handling quoted values with commas
    private static func parseCSVLine(_ line: String) -> [String] {
        var values: [String] = []
        var currentValue = ""
        var insideQuotes = false

        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                values.append(currentValue.trimmingCharacters(in: .whitespaces))
                currentValue = ""
            } else {
                currentValue.append(char)
            }
        }

        // Add the last value
        values.append(currentValue.trimmingCharacters(in: .whitespaces))

        return values
    }
}
