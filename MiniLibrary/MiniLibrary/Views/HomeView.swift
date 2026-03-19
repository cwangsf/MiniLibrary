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
    @State private var showingCheckoutScan = false
    @State private var showingReturnScan = false

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
                .fullScreenCover(isPresented: $showingCheckoutScan) {
                    ScanBookView(scanPurpose: .checkout)
                }
                .fullScreenCover(isPresented: $showingReturnScan) {
                    ScanBookView(scanPurpose: .returnBook)
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
            Button {
                showingCheckoutScan = true
            } label: {
                StatCard(title: cardType.title, icon: cardType.icon, color: cardType.color)
            }
            .buttonStyle(.plain)
        case .quickReturn:
            Button {
                showingReturnScan = true
            } label: {
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
