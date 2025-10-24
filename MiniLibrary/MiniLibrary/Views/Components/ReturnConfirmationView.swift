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
        ScrollView {
            VStack(spacing: 24) {
                // Title
                Text("Confirm Return")
                    .sectionTitle()
                    .padding(.top, 20)

                // Book Cover
                BookCoverImage(book: book, width: 120, height: 180)

                // Confirmation Message
                VStack {
                    VStack {
                        // Book Info
                        VStack(spacing: 4) {
                            Text(book.title)
                                .bookTitle()
                            Text(book.author)
                                .bookAuthor()
                        }

                        Divider()
                            .padding(.horizontal, 40)

                        // Student Info
                        HStack {
                            Text("Student")
                                .labelStyle()
                            Spacer()
                            HStack {
                                Image(systemName: "person.fill")
                                    .personIcon()
                                Text(checkout.student?.libraryId ?? "Unknown")
                                    .valueText()
                            }
                        }

                        Divider()
                            .padding(.horizontal, 40)

                        // Checkout Info
                        HStack {
                            Text("Checked Out")
                                .labelStyle()
                            Spacer()
                            HStack {
                                Image(systemName: "calendar")
                                    .calendarIcon()
                                Text(checkout.checkoutDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline)
                            }
                        }

                        Divider()
                            .padding(.horizontal, 40)

                        // Due Date
                        HStack {
                            Text("Due Date")
                                .labelStyle()
                            Spacer()
                            HStack {
                                Image(systemName: "calendar")
                                    .iconStyle(color: checkout.isOverdue ? .red : .orange)
                                Text(checkout.dueDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline)
                                    .foregroundStyle(checkout.isOverdue ? .red : .primary)
                            }
                            if checkout.isOverdue {
                                Text("OVERDUE")
                                    .badge()
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
    }
}
