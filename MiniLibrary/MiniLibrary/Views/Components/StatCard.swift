//
//  StatCard.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 11/4/25.
//

import SwiftUI

enum StatCardType {
    case totalCopies(Int)
    case checkedOut(Int)
    case wishlist(Int)
    case favorites(Int)
    case quickCheckout
    case quickReturn

    var title: String {
        switch self {
        case .quickCheckout:
            return "Checkout Book"
        case .quickReturn:
            return "Return Book"
        case .totalCopies:
            return "Total Copies"
        case .checkedOut:
            return "Checked Out"
        case .wishlist:
            return "Wish List"
        case .favorites:
            return "Favorites"
        }
    }

    var value: String {
        switch self {
        case .totalCopies(let count),
             .checkedOut(let count),
             .wishlist(let count),
             .favorites(let count):
            return "\(count)"
        case .quickCheckout, .quickReturn:
            return "Scan"
        }
    }

    var icon: String {
        switch self {
        case .totalCopies:
            return "books.vertical.fill"
        case .checkedOut:
            return "book.fill"
        case .wishlist:
            return "list.star"
        case .favorites:
            return "heart.fill"
        case .quickCheckout:
            return "tray.and.arrow.up"
        case .quickReturn:
            return "tray.and.arrow.down"
        }
    }

    var color: Color {
        switch self {
        case .totalCopies:
            return .blue
        case .checkedOut:
            return .orange
        case .wishlist:
            return .green
        case .favorites:
            return .pink
        case .quickCheckout:
            return .purple
        case .quickReturn:
            return .teal
        }
    }

    var destination: String {
        switch self {
        case .totalCopies:
            return "catalog"
        case .checkedOut:
            return "checkedOut"
        case .wishlist:
            return "wishlist"
        case .favorites:
            return "favorites"
        case .quickCheckout:
            return "quickCheckout"
        case .quickReturn:
            return "quickReturn"
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(color)
                .padding()
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    color.opacity(0.25),
                    color.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        
    }
}
