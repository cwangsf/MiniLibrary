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
    @State private var showingAddWishlistSheet = false
    @State private var shareItem: ShareItem?
    
    // Confirmation dialog state
    @State private var bookToDelete: Book?
    @State private var showingDeleteConfirmation = false
    
    // Total count loaded lazily
    @State private var totalWishlistCount: Int?

    var body: some View {
        NavigationStack {
            Group {
                if wishlistBooks.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(wishlistBooks) { book in
                            WishlistItemView(book: book, shareItem: $shareItem)
                                .padding(.vertical, 4)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        requestDeleteBook(book)
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
                    .listStyle(.plain)
                }
            }
            .navigationTitle(totalWishlistCount != nil ? "Wish List (\(totalWishlistCount!))" : "Wish List")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddWishlistSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                loadTotalCount()
            }
            .onChange(of: wishlistBooks.count) { _, _ in
                loadTotalCount()
            }
        }
        .sheet(item: $selectedBook) { book in
            AcquireWishlistItemView(book: book)
        }
        .sheet(isPresented: $showingAddWishlistSheet) {
            AddWishlistItemView()
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.shareText, item.url])
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
            Text("Are you sure you want to delete \"\(book.title)\" from your wishlist? This action cannot be undone.")
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.star")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Wishlist Items")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Books you want to add to your library will appear here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadTotalCount() {
        // Load count asynchronously to avoid blocking UI
        Task {
            let count = wishlistBooks.count
            await MainActor.run {
                totalWishlistCount = count
            }
        }
    }

    private func requestDeleteBook(_ book: Book) {
        bookToDelete = book
        showingDeleteConfirmation = true
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
