//
//  HomeView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var books: [Book]
    @Query private var activeCheckouts: [CheckoutRecord]
    @Query(sort: \Activity.timestamp, order: .reverse) private var activities: [Activity]

    var wishlistCount: Int {
        books.filter { $0.isWishlistItem }.count
    }

    var favoritesCount: Int {
        books.filter { $0.isFavorite && !$0.isWishlistItem }.count
    }

    var totalCopies: Int {
        books.filter { !$0.isWishlistItem }.reduce(0) { $0 + $1.totalCopies }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    // Statistics Cards
                    VStack(spacing: 15) {
                        HStack(spacing: 15) {
                            StatCard(
                                title: "Total Copies",
                                value: "\(totalCopies)",
                                icon: "books.vertical.fill",
                                color: .blue
                            )
                            .background(
                                NavigationLink("", destination: CatalogView())
                                    .opacity(0)
                            )

                            StatCard(
                                title: "Checked Out",
                                value: "\(activeCheckouts.filter { $0.isActive }.count)",
                                icon: "book.fill",
                                color: .orange
                            )
                            .background(NavigationLink("", destination: CheckedOutBooksListView()).opacity(0))
                        }

                        // Second Row
                        HStack(spacing: 15) {
                            StatCard(
                                title: "Wish List",
                                value: "\(wishlistCount)",
                                icon: "list.star",
                                color: .green
                            )
                            .background(NavigationLink("", destination: WishlistView()).opacity(0))

                            StatCard(
                                title: "Favorites",
                                value: "\(favoritesCount)",
                                icon: "heart.fill",
                                color: .pink
                            )
                            .background(NavigationLink("", destination: FavoritesView()).opacity(0))
                        }
                    }
                }
                //.buttonStyle(.plain)
                .listRowSeparator(.hidden)

                RecentActivitySection(activities: activities)
            }
            .listStyle(.plain)
            .navigationTitle("Home")
        }
    }
}



#Preview {
    HomeView()
        .modelContainer(for: [Book.self, CheckoutRecord.self, Student.self, Activity.self])
}
