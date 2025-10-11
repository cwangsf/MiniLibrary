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
        .sheet(isPresented: $showingAcquireSheet) {
            if let book = selectedBook {
                AcquireWishlistItemView(book: book)
            }
        }
    }

    private func deleteBooks(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(wishlistBooks[index])
        }
    }
}

// MARK: - Acquire Wishlist Item View
struct AcquireWishlistItemView: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss

    @State private var copiesToAdd = 1

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Book info
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)
                            .padding(.top, 40)

                        Text("Add to Catalog")
                            .font(.title2)
                            .fontWeight(.bold)

                        VStack(spacing: 12) {
                            VStack(spacing: 4) {
                                Text("Book")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(book.title)
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                                Text(book.author)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            if let notes = book.notes, !notes.isEmpty {
                                Divider()
                                    .padding(.horizontal, 40)

                                VStack(spacing: 4) {
                                    Text("Notes")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(notes)
                                        .font(.subheadline)
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Divider()
                                .padding(.horizontal, 40)

                            VStack(spacing: 8) {
                                Text("Copies to Add")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Stepper(value: $copiesToAdd, in: 1...99) {
                                    Text("\(copiesToAdd)")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.blue)
                                }
                                .labelsHidden()
                            }
                        }
                        .padding()
                        .background(.background)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)

                    // Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            acquireBook()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Add \(copiesToAdd) \(copiesToAdd == 1 ? "Copy" : "Copies")")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.gray.opacity(0.2))
                                .foregroundStyle(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    private func acquireBook() {
        book.isWishlistItem = false
        book.totalCopies = copiesToAdd
        book.availableCopies = copiesToAdd
        dismiss()
    }
}

#Preview {
    NavigationStack {
        WishlistView()
            .modelContainer(for: [Book.self])
    }
}
