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
    @State private var shareItem: ShareItem?

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
                    HStack {
                        // Main content - tapping opens Amazon
                        Button {
                            if let url = generateAmazonURL(for: book) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                // Book Cover Image
                                BookCoverImage(book: book, width: 60, height: 90)

                                // Book Info
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
                            }
                        }

                        // Share button
                        Button {
                            if let url = generateAmazonURL(for: book) {
                                shareItem = ShareItem(
                                    title: book.title,
                                    author: book.author,
                                    url: url
                                )
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.blue)
                                .font(.title2)
                                .padding(.leading, 8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteBook(book)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            selectedBook = book
                            showingAcquireSheet = true
                        } label: {
                            Label("Acquire", systemImage: "plus.circle")
                        }
                        .tint(.green)
                    }
                }
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
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.shareText, item.url])
        }
    }

    private func deleteBook(_ book: Book) {
        modelContext.delete(book)
    }

    private func generateAmazonURL(for book: Book) -> URL? {
        if let isbn = book.isbn {
            return URL(string: "https://www.amazon.com/s?k=\(isbn)")
        } else {
            let query = "\(book.title) \(book.author)"
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return URL(string: "https://www.amazon.com/s?k=\(query)")
        }
    }
}

// MARK: - Share Item
struct ShareItem: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let url: URL

    var shareText: String {
        "Check out this book: \"\(title)\" by \(author)"
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

#Preview {
    NavigationStack {
        WishlistView()
            .modelContainer(for: [Book.self])
    }
}
