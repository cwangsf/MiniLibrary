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

    var totalCopies: Int {
        books.filter { !$0.isWishlistItem }.reduce(0) { $0 + $1.totalCopies }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Statistics Cards
                    HStack(spacing: 15) {
                        NavigationLink(destination: CatalogView()) {
                            StatCard(
                                title: "Total Copies",
                                value: "\(totalCopies)",
                                icon: "books.vertical.fill",
                                color: .blue
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(destination: CheckedOutBooksListView()) {
                            StatCard(
                                title: "Checked Out",
                                value: "\(activeCheckouts.filter { $0.isActive }.count)",
                                icon: "book.fill",
                                color: .orange
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)

                    // Wishlist Card
                    HStack(spacing: 15) {
                        NavigationLink(destination: WishlistView()) {
                            StatCard(
                                title: "Wish List",
                                value: "\(wishlistCount)",
                                icon: "list.star",
                                color: .pink
                            )
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.horizontal)

                    // Recent Activity Section
                    if !activities.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent Activity")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(activities.prefix(10)) { activity in
                                ActivityRowView(activity: activity)
                            }
                        }
                    } else {
                        ContentUnavailableView(
                            "No Recent Activity",
                            systemImage: "clock",
                            description: Text("Activity will appear here as you use the library")
                        )
                    }

                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Home")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(color)

                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Book.self, CheckoutRecord.self, Student.self, Activity.self])
}
