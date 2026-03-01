//
//  HomeView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    
    private let cardSpacing: CGFloat = 16

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
            NavigationStack {
                ScrollView {
                    VStack(spacing: cardSpacing) {
                        // Statistics Cards - First Row
                        HStack(spacing: cardSpacing) {
                            statCardView(for: statCards[0])
                            statCardView(for: statCards[1])
                        }
                        .padding(.horizontal, cardSpacing)

                        // Statistics Cards - Second Row
                        HStack(spacing: cardSpacing) {
                            statCardView(for: statCards[2])
                            statCardView(for: statCards[3])
                        }
                        .padding(.horizontal, cardSpacing)

                        // Action Cards - Third Row
                        HStack(spacing: cardSpacing) {
                            statCardView(for: statCards[4])
                            statCardView(for: statCards[5])
                        }
                        .padding(.horizontal, cardSpacing)
                    }
                    .padding(.top, cardSpacing)
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
