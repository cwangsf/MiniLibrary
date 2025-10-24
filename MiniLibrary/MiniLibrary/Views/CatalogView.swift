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
        let languageFilteredBooks = selectedLanguage.filter(catalogBooks)

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
    private var alphabeticalGrouping: AlphabeticalGrouping<Book> {
        AlphabeticalGrouper.group(filteredBooks, by: \.title)
    }

    private var groupedBooks: [String: [Book]] {
        alphabeticalGrouping.grouped
    }

    private var sortedSectionTitles: [String] {
        alphabeticalGrouping.sortedSectionTitles
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ZStack(alignment: .trailing) {
                    List {
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
                    }
                }
            }
            .navigationTitle("Catalog")
            .searchable(text: $searchText, prompt: "Search books or authors")
            .safeAreaInset(edge: .bottom) {
                LanguageFilterPicker(selectedLanguage: $selectedLanguage)
                    .padding(.horizontal)
                    .background(.ultraThinMaterial)
            }
        }
    }
}

#Preview {
    CatalogView()
        .modelContainer(for: [Book.self, CheckoutRecord.self])
}
