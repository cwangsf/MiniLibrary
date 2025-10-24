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
    @State private var selectedLanguage: LanguageFilter = .all

    // Apply language filter
    // Include books without language info (metadata not yet fetched)
    var filteredWishlistBooks: [Book] {
        selectedLanguage.filter(wishlistBooks, includeUnknown: true)
    }

    // Group books by first letter of title
    var groupedBooks: [String: [Book]] {
        Dictionary(grouping: filteredWishlistBooks) { book in
            let firstChar = book.title.prefix(1).uppercased()
            // Check if it's a letter
            if firstChar.rangeOfCharacter(from: .letters) != nil {
                return firstChar
            } else {
                return "#"
            }
        }
    }

    var sortedSectionTitles: [String] {
        let titles = groupedBooks.keys.sorted()
        // Move "#" to the end if it exists
        if let hashIndex = titles.firstIndex(of: "#") {
            var sorted = titles
            sorted.remove(at: hashIndex)
            sorted.append("#")
            return sorted
        }
        return titles
    }

    var body: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .trailing) {
                List {
                    if wishlistBooks.isEmpty {
                        ContentUnavailableView(
                            "No Wishlist Items",
                            systemImage: "list.star",
                            description: Text("Books you want to add to your library will appear here")
                        )
                    } else {
                        ForEach(sortedSectionTitles, id: \.self) { letter in
                            Section {
                                ForEach(groupedBooks[letter] ?? []) { book in
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
                            } header: {
                                Text(letter)
                            }
                            .id(letter)
                        }
                    }
                }
                .listStyle(.plain)

                // Section Index Titles (A-Z) on the right side
                if !filteredWishlistBooks.isEmpty && !sortedSectionTitles.isEmpty {
                    SectionIndexTitles(titles: sortedSectionTitles) { letter in
                        withAnimation {
                            proxy.scrollTo(letter, anchor: .top)
                        }
                    }
                    .padding(.trailing)
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
        .safeAreaInset(edge: .top, spacing: 0) {
            if !wishlistBooks.isEmpty {
                LanguageFilterPicker(selectedLanguage: $selectedLanguage)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
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
