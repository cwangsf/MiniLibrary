//
//  CatalogView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData

struct CatalogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.title) private var books: [Book]
    @State private var searchText = ""
    @State private var selectedLanguage: LanguageFilter = .all

    var filteredBooks: [Book] {
        let catalogBooks = books.filter { !$0.isWishlistItem }

        // Apply language filter
        let languageFilteredBooks: [Book]
        switch selectedLanguage {
        case .all:
            languageFilteredBooks = catalogBooks
        case .english:
            languageFilteredBooks = catalogBooks.filter { book in
                guard let langCode = book.languageCode?.lowercased() else { return false }
                return langCode == "en" || langCode == "english" || langCode.contains("english")
            }
        case .german:
            languageFilteredBooks = catalogBooks.filter { book in
                guard let langCode = book.languageCode?.lowercased() else { return false }
                return langCode == "de" || langCode == "german" || langCode.contains("german")
            }
        }

        // Apply search filter
        if searchText.isEmpty {
            return languageFilteredBooks
        } else {
            return languageFilteredBooks.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.author.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    // Group books by first letter of title
    var groupedBooks: [String: [Book]] {
        let catalogBooks = filteredBooks
        return Dictionary(grouping: catalogBooks) { book in
            let firstChar = book.title.prefix(1).uppercased()
            // Check if it's a letter
            if firstChar.rangeOfCharacter(from: .letters) != nil {
                return firstChar
            } else {
                return "#"
            }
        }
    }

    var sortedSectionTitles: [String] {
        let titles = groupedBooks.keys.sorted()
        // Move "#" to the end if it exists
        if let hashIndex = titles.firstIndex(of: "#") {
            var sorted = titles
            sorted.remove(at: hashIndex)
            sorted.append("#")
            return sorted
        }
        return titles
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ZStack(alignment: .trailing) {
                    List {
                        // Language filter segmented control as list header
                        Section {
                            EmptyView()
                        } header: {
                            LanguageFilterPicker(selectedLanguage: $selectedLanguage)
                        }
                        .listSectionSeparator(.hidden)

                        if searchText.isEmpty {
                            // Grouped view with section index when not searching
                            ForEach(sortedSectionTitles, id: \.self) { letter in
                                Section {
                                    ForEach(groupedBooks[letter] ?? []) { book in
                                        NavigationLink(destination: BookDetailView(book: book)) {
                                            BookRowView(book: book)
                                        }
                                    }
                                } header: {
                                    Text(letter)
                                }
                                .id(letter)
                            }
                        } else {
                            // Flat list when searching
                            ForEach(filteredBooks) { book in
                                NavigationLink(destination: BookDetailView(book: book)) {
                                    BookRowView(book: book)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)

                    // Section Index Titles (A-Z) on the right side
                    if searchText.isEmpty && !sortedSectionTitles.isEmpty {
                        SectionIndexTitles(titles: sortedSectionTitles) { letter in
                            withAnimation {
                                proxy.scrollTo(letter, anchor: .top)
                            }
                        }
                        .padding(.trailing)
                    }
                }
            }
            .navigationTitle("Catalog")
            .searchable(text: $searchText, prompt: "Search books or authors")
        }
    }
}

#Preview {
    CatalogView()
        .modelContainer(for: [Book.self, CheckoutRecord.self])
}
