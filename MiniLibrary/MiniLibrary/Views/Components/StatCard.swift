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

    var title: String {
        switch self {
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
