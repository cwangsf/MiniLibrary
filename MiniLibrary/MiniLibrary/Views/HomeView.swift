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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
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

    var statCards: [StatCardType] {
        [
            .totalCopies(totalCopies),
            .checkedOut(activeCheckouts.filter { $0.isActive }.count),
            .wishlist(wishlistCount),
            .favorites(favoritesCount)
        ]
    }

    var body: some View {
        if horizontalSizeClass == .regular {
            // iPad Layout
            NavigationStack {
                HStack(spacing: 20) {
                    // Left Column: Statistics Cards in 2x2 grid
                    VStack(spacing: 15) {
                        ForEach(statCards, id: \.destination) { card in
                            statCardView(for: card)
                        }

                        Spacer()
                    }
                    .frame(maxWidth: 300)

                    // Right Column: Recent Activity
                    RecentActivitySection(activities: activities)

                    Spacer()
                }
                .padding()
                .navigationTitle("Home")
            }
        } else {
            // iPhone Layout
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        // Statistics Cards - First Row
                        HStack(spacing: 15) {
                            statCardView(for: statCards[0])
                            statCardView(for: statCards[1])
                        }
                        .padding(.horizontal)

                        // Statistics Cards - Second Row
                        HStack(spacing: 15) {
                            statCardView(for: statCards[2])
                            statCardView(for: statCards[3])
                        }
                        .padding(.horizontal)

                        // Recent Activity Section
                        RecentActivitySection(activities: activities)
                    }
                    .padding(.top)
                }
                .navigationTitle("Home")
            }
        }
    }
}

// MARK: - Helper Methods
extension HomeView {
    @ViewBuilder
    func statCardView(for cardType: StatCardType) -> some View {
        switch cardType {
        case .totalCopies:
            NavigationLink(destination: CatalogView()) {
                StatCard(title: cardType.title, value: cardType.value, icon: cardType.icon, color: cardType.color)
            }
            .buttonStyle(.plain)
        case .checkedOut:
            NavigationLink(destination: CheckedOutBooksListView()) {
                StatCard(title: cardType.title, value: cardType.value, icon: cardType.icon, color: cardType.color)
            }
            .buttonStyle(.plain)
        case .wishlist:
            NavigationLink(destination: WishlistView()) {
                StatCard(title: cardType.title, value: cardType.value, icon: cardType.icon, color: cardType.color)
            }
            .buttonStyle(.plain)
        case .favorites:
            NavigationLink(destination: FavoritesView()) {
                StatCard(title: cardType.title, value: cardType.value, icon: cardType.icon, color: cardType.color)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Book.self, CheckoutRecord.self, Student.self, Activity.self])
}
