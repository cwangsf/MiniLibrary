//
//  LanguageFilterPicker.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/24/25.
//

import SwiftUI

enum LanguageFilter: String, CaseIterable {
    case all = "All"
    case english = "English"
    case german = "German"

    /// Filter books by language
    /// - Parameter books: Array of books to filter
    /// - Parameter includeUnknown: If true, books without language info are included in all filters (default: false)
    func filter(_ books: [Book], includeUnknown: Bool = false) -> [Book] {
        switch self {
        case .all:
            return books
        case .english:
            return books.filter { book in
                guard let langCode = book.languageCode?.lowercased() else {
                    return includeUnknown  // Include books without language if requested
                }
                return langCode == "en" || langCode == "english" || langCode.contains("english")
            }
        case .german:
            return books.filter { book in
                guard let langCode = book.languageCode?.lowercased() else {
                    return includeUnknown  // Include books without language if requested
                }
                return langCode == "de" || langCode == "german" || langCode.contains("german")
            }
        }
    }
}

struct LanguageFilterPicker: View {
    @Binding var selectedLanguage: LanguageFilter

    var body: some View {
        Picker("Language", selection: $selectedLanguage) {
            ForEach(LanguageFilter.allCases, id: \.self) { language in
                Text(language.rawValue).tag(language)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 0)
        .padding(.vertical, 8)
        .listRowInsets(EdgeInsets())
    }
}

#Preview {
    @Previewable @State var selectedLanguage: LanguageFilter = .all

    List {
        Section {
            EmptyView()
        } header: {
            LanguageFilterPicker(selectedLanguage: $selectedLanguage)
        }
        .listSectionSeparator(.hidden)

        Section {
            Text("Book 1")
            Text("Book 2")
            Text("Book 3")
        }
    }
}
