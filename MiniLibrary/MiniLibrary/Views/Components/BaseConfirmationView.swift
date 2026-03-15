//
//  BaseConfirmationView.swift
//  MiniLibrary
//
//  Created by Claude on 2026-03-06.
//

import SwiftUI

/// Confirmation screen types with their associated display properties
enum ConfirmationType {
    case checkout
    case returnBook
    case addBook
    
    var title: String {
        switch self {
        case .checkout:
            return "Confirm Checkout"
        case .returnBook:
            return "Confirm Return"
        case .addBook:
            return "Confirm New Book"
        }
    }
    
    var buttonText: String {
        switch self {
        case .checkout:
            return "Confirm Checkout"
        case .returnBook:
            return "Confirm Return"
        case .addBook:
            return "Add Book"
        }
    }
    
    var buttonIcon: String {
        return "checkmark.circle.fill"
    }
    
    var buttonColor: Color {
        switch self {
        case .checkout:
            return .blue
        case .returnBook:
            return .green
        case .addBook:
            return .blue
        }
    }
}

/// Generic base confirmation view with consistent layout and button structure
/// Provides a standardized confirmation UI across the app
struct BaseConfirmationView<Content: View>: View {
    let type: ConfirmationType
    let book: Book
    let onConfirm: () -> Void
    let onCancel: (() -> Void)?
    @ViewBuilder let content: Content
    
    @Environment(\.dismiss) private var dismiss
    
    init(
        type: ConfirmationType,
        book: Book,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.type = type
        self.book = book
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        self.content = content()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text(type.title)
                            .sectionTitle()
                        if let isbn = book.isbn {
                            Text("ISBN: \(isbn)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    content
                        .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            onConfirm()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: type.buttonIcon)
                                Text(type.buttonText)
                            }
                            .prominentButton(color: type.buttonColor)
                        }
                        
                        Button {
                            onCancel?()
                            dismiss()
                        } label: {
                            Text("Cancel")
                                .secondaryButton()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
    }
}
