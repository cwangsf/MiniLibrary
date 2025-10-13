//
//  WishlistView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData

struct WishlistView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Book> { $0.isWishlistItem == true }, sort: \Book.title)
    private var wishlistBooks: [Book]

    @State private var selectedBook: Book?
    @State private var showingAcquireSheet = false
    @State private var showingAddWishlistSheet = false

    var body: some View {
        List {
            if wishlistBooks.isEmpty {
                ContentUnavailableView(
                    "No Wishlist Items",
                    systemImage: "heart",
                    description: Text("Books you want to add to your library will appear here")
                )
            } else {
                ForEach(wishlistBooks) { book in
                    Button {
                        selectedBook = book
                        showingAcquireSheet = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(book.title)
                                    .font(.headline)
                                    .lineLimit(2)
                                    .foregroundStyle(.primary)

                                Text(book.author)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                if let notes = book.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }

                            Spacer()

                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                                .font(.title2)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: deleteBooks)
            }
        }
        .navigationTitle("Wish List")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddWishlistSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAcquireSheet) {
            if let book = selectedBook {
                AcquireWishlistItemView(book: book)
            }
        }
        .sheet(isPresented: $showingAddWishlistSheet) {
            AddWishlistItemView()
        }
    }

    private func deleteBooks(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(wishlistBooks[index])
        }
    }
}

#Preview {
    NavigationStack {
        WishlistView()
            .modelContainer(for: [Book.self])
    }
}
