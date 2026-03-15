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

    var body: some View {
        BaseConfirmationView(
            type: .returnBook,
            book: book,
            onConfirm: onConfirm
        ) {
            // Book Cover
            BookCoverImage(book: book, width: 120, height: 180)

            // Confirmation Details
            VStack {
                VStack {
                    // Book Info
                    VStack(spacing: 4) {
                        Text(book.title)
                            .bookTitle()
                        if let author = book.author {
                            Text(author)
                                .bookAuthor()
                        }
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
                            Text(checkout.student?.fullName ?? "Unknown")
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
        }
    }
}
