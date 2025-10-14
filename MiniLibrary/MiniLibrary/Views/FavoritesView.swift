//
//  FavoritesView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/14/25.
//

import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Query(filter: #Predicate<Book> { $0.isFavorite == true }, sort: \Book.title)
    private var favoriteBooks: [Book]

    var body: some View {
        NavigationStack {
            List {
                if favoriteBooks.isEmpty {
                    ContentUnavailableView(
                        "No Favorite Books",
                        systemImage: "heart",
                        description: Text("Books you mark as favorites will appear here")
                    )
                } else {
                    ForEach(favoriteBooks) { book in
                        NavigationLink(destination: BookDetailView(book: book)) {
                            BookRowView(book: book)
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    FavoritesView()
        .modelContainer(for: [Book.self])
}
