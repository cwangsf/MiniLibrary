//
//  AcquireWishlistItemView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData

struct AcquireWishlistItemView: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var copiesToAdd = 1

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Book info
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .largeIcon(color: .green)
                            .padding(.top, 40)

                        Text("Add to Catalog")
                            .sectionTitle()

                        VStack(spacing: 12) {
                            VStack(spacing: 4) {
                                Text(book.title)
                                    .bookTitle()
                                Text(book.author)
                                    .bookAuthor()
                            }

                            if let notes = book.notes, !notes.isEmpty {
                                Divider()
                                    .padding(.horizontal, 40)

                                VStack(spacing: 4) {
                                    Text("Notes")
                                        .labelStyle()
                                    Text(notes)
                                        .font(.subheadline)
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Divider()
                                .padding(.horizontal, 40)

                            VStack(spacing: 8) {
                                Text("Copies to Add")
                                    .labelStyle()

                                Stepper(value: $copiesToAdd, in: 1...99) {
                                    Text("\(copiesToAdd)")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.blue)
                                }
                                .labelsHidden()
                            }
                        }
                        .padding()
                        .background(.background)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)

                    // Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            acquireBook()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Add \(copiesToAdd) \(copiesToAdd == 1 ? "Copy" : "Copies")")
                            }
                            .prominentButton(color: .green)
                        }

                        Button {
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
        .presentationDetents([.medium, .large])
    }

    private func acquireBook() {
        book.isWishlistItem = false
        book.totalCopies = copiesToAdd
        book.availableCopies = copiesToAdd

        // Log activity
        let activity = Activity(
            type: .fulfillWishlist,
            bookTitle: book.title,
            bookAuthor: book.author,
            additionalInfo: "\(copiesToAdd) \(copiesToAdd == 1 ? "copy" : "copies")"
        )
        modelContext.insert(activity)

        dismiss()
    }
}
