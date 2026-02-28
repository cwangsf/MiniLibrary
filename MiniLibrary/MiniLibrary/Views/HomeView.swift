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

    var statCards: [StatCardType] {
        [
            .quickCheckout,
            .quickReturn,
            .totalCopies,
            .checkedOut,
            .wishlist,
            .settings,
        ]
    }

    var body: some View {

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

                        // Action Cards - Third Row
                        HStack(spacing: 15) {
                            statCardView(for: statCards[4])
                            statCardView(for: statCards[5])
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
                .navigationTitle("Home")
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
                StatCard(title: cardType.title, icon: cardType.icon, color: cardType.color)
            }
            .buttonStyle(.plain)
        case .checkedOut:
            NavigationLink(destination: CheckedOutBooksListView()) {
                StatCard(title: cardType.title, icon: cardType.icon, color: cardType.color)
            }
            .buttonStyle(.plain)
        case .wishlist:
            NavigationLink(destination: WishlistView()) {
                StatCard(title: cardType.title, icon: cardType.icon, color: cardType.color)
            }
            .buttonStyle(.plain)
        case .settings:
            NavigationLink(destination: SettingsView()) {
                StatCard(title: cardType.title, icon: cardType.icon, color: cardType.color)
            }
            .buttonStyle(.plain)
        case .quickCheckout:
            NavigationLink(destination: ScanBookView(scanPurpose: .checkout)) {
                StatCard(title: cardType.title, icon: cardType.icon, color: cardType.color)
            }
            .buttonStyle(.plain)
        case .quickReturn:
            NavigationLink(destination: ScanBookView(scanPurpose: .returnBook)) {
                StatCard(title: cardType.title, icon: cardType.icon, color: cardType.color)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Book.self, CheckoutRecord.self, Student.self])
}
