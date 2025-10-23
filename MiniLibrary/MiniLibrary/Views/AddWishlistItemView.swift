//
//  AddWishlistItemView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/23/25.
//

import SwiftUI
import SwiftData

// MARK: - Add Wishlist Item View
struct AddWishlistItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var author = ""
    @State private var publisher = ""
    @State private var isbn = ""
    @State private var searchResults: [GoogleBookItem] = []
    @State private var selectedItems: Set<Int> = [] // Track selected items by index
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var hasSearched = false
    @State private var showManualAddConfirmation = false
    
    var canSearch: Bool {
        !isbn.isEmpty || !title.isEmpty || !author.isEmpty || !publisher.isEmpty
    }
    
    var body: some View {
        Form {
            Section("Book Information") {
                TextField("ISBN (optional)", text: $isbn)
                    .keyboardType(.numberPad)
                TextField("Title (optional)", text: $title)
                TextField("Author (optional)", text: $author)
                TextField("Publisher (optional)", text: $publisher)
            }
            
            Section {
                Button {
                    Task {
                        await searchGoogle()
                    }
                } label: {
                    HStack {
                        if isSearching {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Image(systemName: "magnifyingglass")
                        Text(isSearching ? "Searching..." : "Search Google Books")
                    }
                }
                .disabled(!canSearch || isSearching)
                
                Button {
                    showManualAddConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add to Wishlist Manually")
                    }
                }
                .disabled(!canSearch)
            } footer: {
                Text("Search Google Books to get complete information, or add manually with the details you have.")
                    .font(.caption)
            }
            
            if let error = searchError {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            
            if !searchResults.isEmpty {
                Section {
                    ForEach(Array(searchResults.enumerated()), id: \.offset) { index, item in
                        Button {
                            toggleSelection(index)
                        } label: {
                            HStack {
                                BookSearchResultRow(item: item)
                                
                                Spacer()
                                
                                // Checkmark for selected items
                                if selectedItems.contains(index) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                        .font(.title3)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.gray)
                                        .font(.title3)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    HStack {
                        Text("Search Results - Select Books")
                        Spacer()
                        if !selectedItems.isEmpty {
                            Text("\(selectedItems.count) selected")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else if hasSearched && !isSearching {
                Section {
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "magnifyingglass",
                        description: Text("Try searching with different keywords or add manually")
                    )
                }
            }
        }
        .navigationTitle("Add to Wishlist")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Add to Wishlist?", isPresented: $showManualAddConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Add") {
                addManually()
            }
        } message: {
            let parts = [
                title.isEmpty ? nil : "Title: \(title)",
                author.isEmpty ? nil : "Author: \(author)",
                publisher.isEmpty ? nil : "Publisher: \(publisher)",
                isbn.isEmpty ? nil : "ISBN: \(isbn)"
            ].compactMap { $0 }
            
            let message = parts.isEmpty ? "Add this book to your wishlist?" : parts.joined(separator: "\n")
            return Text(message)
        }
        .safeAreaInset(edge: .bottom) {
            if !selectedItems.isEmpty {
                Button {
                    addSelectedBooks()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add \(selectedItems.count) Book\(selectedItems.count == 1 ? "" : "s") to Wishlist")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }
    
    private func toggleSelection(_ index: Int) {
        if selectedItems.contains(index) {
            selectedItems.remove(index)
        } else {
            selectedItems.insert(index)
        }
    }
    
    private func addSelectedBooks() {
        var addedCount = 0
        
        for index in selectedItems.sorted() {
            guard index < searchResults.count else { continue }
            let item = searchResults[index]
            let book = BookAPIService.shared.createBookFromSearchResult(item, isWishlistItem: true)
            modelContext.insert(book)
            addedCount += 1
        }
        
        // Log activity
        let activity = Activity(
            type: .addWishlist,
            bookTitle: "Bulk Add",
            bookAuthor: "Google Books Search",
            additionalInfo: "\(addedCount) book\(addedCount == 1 ? "" : "s") added"
        )
        modelContext.insert(activity)
        
        dismiss()
    }
    
    private func searchGoogle() async {
        isSearching = true
        searchError = nil
        hasSearched = false
        selectedItems.removeAll() // Clear previous selections
        
        do {
            var results: [GoogleBookItem] = []
            
            // If ISBN is provided, search by ISBN first
            if !isbn.isEmpty {
                do {
                    results = try await BookAPIService.shared.searchBooksByISBN(isbn)
                } catch {
                    // ISBN search failed, fall back to title/author search if title is provided
                    print("ISBN search failed, falling back to title/author search: \(error.localizedDescription)")
                    if !title.isEmpty || !author.isEmpty {
                        results = try await BookAPIService.shared.searchBooksByTitleAndAuthor(
                            title: title,
                            author: author
                        )
                    } else {
                        throw error
                    }
                }
            } else {
                // No ISBN, search by title and author
                results = try await BookAPIService.shared.searchBooksByTitleAndAuthor(
                    title: title,
                    author: author
                )
            }
            
            searchResults = results
            hasSearched = true
        } catch {
            searchError = error.localizedDescription
            searchResults = []
        }
        
        isSearching = false
    }
    
    private func addManually() {
        // Use provided info or defaults
        let bookTitle = title.isEmpty ? "Untitled Book" : title
        let bookAuthor = author.isEmpty ? "Unknown Author" : author
        let bookISBN = isbn.isEmpty ? nil : isbn
        let bookPublisher = publisher.isEmpty ? nil : publisher
        
        let book = Book(
            isbn: bookISBN,
            title: bookTitle,
            author: bookAuthor,
            totalCopies: 0,
            availableCopies: 0,
            publisher: bookPublisher,
            isWishlistItem: true
        )
        
        modelContext.insert(book)
        
        // Log activity
        let activity = Activity(
            type: .addWishlist,
            bookTitle: book.title,
            bookAuthor: book.author,
            additionalInfo: "Added manually"
        )
        modelContext.insert(activity)
        
        dismiss()
    }
}
