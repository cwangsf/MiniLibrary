//
//  CatalogView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MiniLibrary", category: "CatalogView")

struct CatalogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.title) private var books: [Book]
    @State private var searchText = ""
    
    // Cached filtered books to avoid recalculating on every render
    @State private var filteredBooks: [Book] = []
    
    // Confirmation dialog state
    @State private var bookToDelete: Book?
    @State private var showingDeleteConfirmation = false
    
    // Total count loaded lazily
    @State private var totalBooksCount: Int?

    var body: some View {
        NavigationStack {
            Group {
                if filteredBooks.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(filteredBooks) { book in
                            BookRowWithActions(book: book, onDelete: requestDeleteBook)
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollDismissesKeyboard(.immediately)
                }
            }
            .navigationTitle(totalBooksCount != nil ? "Catalog (\(totalBooksCount!))" : "Catalog")
            .searchable(text: $searchText, prompt: "Search books or authors")
            .onAppear {
                updateFilteredBooks()
                loadTotalCount()
            }
            .onChange(of: books.count) { _, _ in
                updateFilteredBooks()
                loadTotalCount()
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
        
        // Apply search filter
        if searchText.isEmpty {
            filteredBooks = catalogBooks
        } else {
            filteredBooks = catalogBooks.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                (book.author?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    private func loadTotalCount() {
        // Load count asynchronously to avoid blocking UI
        Task {
            let count = books.filter { !$0.isWishlistItem }.count
            await MainActor.run {
                totalBooksCount = count
            }
        }
    }

    private func requestDeleteBook(_ book: Book) {
        bookToDelete = book
        showingDeleteConfirmation = true
    }
    
    private func deleteBook(_ book: Book) {
        guard !book.isDeleted else {
            logger.warning("Attempted to delete an already deleted book")
            return
        }
        
        modelContext.delete(book)
        
        do {
            try modelContext.save()
            logger.info("Successfully deleted book: '\(book.title)'")
        } catch {
            logger.error("Failed to delete book '\(book.title)': \(error.localizedDescription)")
        }
    }
}

#Preview {
    CatalogView()
        .modelContainer(for: [Book.self, CheckoutRecord.self])
}
