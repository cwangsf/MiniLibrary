//
//  BaseConfirmationView.swift
//  MiniLibrary
//
//  Created by Claude on 2026-03-06.
//

import SwiftUI

/// Generic base confirmation view with consistent layout and button structure
/// Provides a standardized confirmation UI across the app
struct BaseConfirmationView<Content: View>: View {
    let title: String
    let confirmButtonText: String
    let confirmButtonIcon: String
    let confirmButtonColor: Color
    let onConfirm: () -> Void
    let onCancel: (() -> Void)?
    @ViewBuilder let content: Content
    
    @Environment(\.dismiss) private var dismiss
    
    init(
        title: String,
        confirmButtonText: String,
        confirmButtonIcon: String = "checkmark.circle.fill",
        confirmButtonColor: Color = .blue,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.confirmButtonText = confirmButtonText
        self.confirmButtonIcon = confirmButtonIcon
        self.confirmButtonColor = confirmButtonColor
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        self.content = content()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text(title)
                        .sectionTitle()
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
                                Image(systemName: confirmButtonIcon)
                                Text(confirmButtonText)
                            }
                            .prominentButton(color: confirmButtonColor)
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
