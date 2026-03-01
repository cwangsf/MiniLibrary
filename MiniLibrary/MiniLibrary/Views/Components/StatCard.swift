//
//  StatCard.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 11/4/25.
//

import SwiftUI

enum StatCardType {
    case totalCopies
    case checkedOut
    case wishlist
    case settings
    case quickCheckout
    case quickReturn

    var title: String {
        switch self {
        case .quickCheckout:
            return String(localized: "Check Out Book")
        case .quickReturn:
            return String(localized: "Return Book")
        case .totalCopies:
            return String(localized: "All Books")
        case .checkedOut:
            return String(localized: "Checked Out Records")
        case .wishlist:
            return String(localized: "Wish List")
        case .settings:
            return String(localized: "Settings")
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
        case .settings:
            return "gearshape.fill"
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
        case .settings:
            return .indigo
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
        case .settings:
            return "settings"
        case .quickCheckout:
            return "quickCheckout"
        case .quickReturn:
            return "quickReturn"
        }
    }
}

struct StatCard: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 50, weight: .bold))
                .foregroundStyle(color)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 140)
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
