//
//  ReturnConfirmationView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI

struct ReturnConfirmationView: View {
    let book: Book
    let checkout: CheckoutRecord
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Book Cover
                    BookCoverImage(book: book, width: 120, height: 180)
                        .padding(.top, 40)

                    // Confirmation Message
                    VStack(spacing: 16) {
                        Text("Confirm Return")
                            .font(.title2)
                            .fontWeight(.bold)

                        VStack(spacing: 12) {
                            // Book Info
                            VStack(spacing: 4) {
                                Text("Book")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(book.title)
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                                Text(book.author)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Divider()
                                .padding(.horizontal, 40)

                            // Student Info
                            VStack(spacing: 4) {
                                Text("Student")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(.blue)
                                    Text(checkout.student?.libraryId ?? "Unknown")
                                        .font(.headline)
                                }
                            }

                            Divider()
                                .padding(.horizontal, 40)

                            // Checkout Info
                            VStack(spacing: 4) {
                                Text("Checked Out")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundStyle(.blue)
                                    Text(checkout.checkoutDate.formatted(date: .abbreviated, time: .omitted))
                                        .font(.subheadline)
                                }
                            }

                            Divider()
                                .padding(.horizontal, 40)

                            // Due Date
                            VStack(spacing: 4) {
                                Text("Due Date")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundStyle(checkout.isOverdue ? .red : .orange)
                                    Text(checkout.dueDate.formatted(date: .abbreviated, time: .omitted))
                                        .font(.subheadline)
                                        .foregroundStyle(checkout.isOverdue ? .red : .primary)
                                }
                                if checkout.isOverdue {
                                    Text("OVERDUE")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(.red)
                                        .clipShape(Capsule())
                                }
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
                            onConfirm()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Confirm Return")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.gray.opacity(0.2))
                                .foregroundStyle(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
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
}
