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
    
    // Cached filtered books to avoid recalculating on every render
    @State private var filteredBooks: [Book] = []

    var body: some View {
        NavigationStack {
                ZStack(alignment: .trailing) {
                    List {
                        ForEach(filteredBooks) { book in
                            BookRowWithActions(book: book, onDelete: deleteBook)
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollDismissesKeyboard(.immediately)

                    // Floating language filter at bottom
                    VStack {
                        Spacer()

                        LanguageFilterPicker(selectedLanguage: $selectedLanguage)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    .allowsHitTesting(true)
                }
            .navigationTitle("Catalog")
            .searchable(text: $searchText, prompt: "Search books or authors")
            .onAppear {
                updateFilteredBooks()
            }
            .onChange(of: books.count) { _, _ in
                updateFilteredBooks()
            }
            .onChange(of: selectedLanguage) { _, _ in
                updateFilteredBooks()
            }
            .onChange(of: searchText) { _, _ in
                updateFilteredBooks()
            }
        }
    }
    
    private func updateFilteredBooks() {
        let catalogBooks = books.filter { !$0.isWishlistItem }
        
        // Apply language filter
        let languageFilteredBooks = selectedLanguage.filter(catalogBooks)
        
        // Apply search filter
        if searchText.isEmpty {
            filteredBooks = languageFilteredBooks
        } else {
            filteredBooks = languageFilteredBooks.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                (book.author?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }

    private func deleteBook(_ book: Book) {
        modelContext.delete(book)
        try? modelContext.save()
    }
}

#Preview {
    CatalogView()
        .modelContainer(for: [Book.self, CheckoutRecord.self])
}
