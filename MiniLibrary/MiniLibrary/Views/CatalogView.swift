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
    
    // Confirmation dialog state
    @State private var bookToDelete: Book?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if filteredBooks.isEmpty {
                    emptyStateView
                } else {
                    ZStack(alignment: .trailing) {
                        List {
                            ForEach(filteredBooks) { book in
                                BookRowWithActions(book: book, onDelete: requestDeleteBook)
                                    .listRowSeparator(.hidden)
                            }
                        }
                        .listStyle(.plain)
                        .scrollDismissesKeyboard(.immediately)

                        // Floating language filter at bottom
                        VStack {
                            Spacer()

                            LanguageFilterPicker(selectedLanguage: $selectedLanguage)
                                .background(Color(.systemBackground).opacity(0.95))
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                        .allowsHitTesting(true)
                    }
                }
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
            .alert("Delete Book", isPresented: $showingDeleteConfirmation, presenting: bookToDelete) { book in
                Button("Cancel", role: .cancel) {
                    bookToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    deleteBook(book)
                    bookToDelete = nil
                }
            } message: { book in
                Text("Are you sure you want to delete \"\(book.title)\"? This action cannot be undone.")
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Books in Catalog")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add books by scanning ISBN or importing from CSV")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    private func requestDeleteBook(_ book: Book) {
        bookToDelete = book
        showingDeleteConfirmation = true
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
