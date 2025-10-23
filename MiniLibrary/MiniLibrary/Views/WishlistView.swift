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
                    
                    WishlistItemView(book: book, shareItem: $shareItem)
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
