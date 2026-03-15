//
//  CheckoutConfirmationView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI

struct CheckoutConfirmationView: View {
    let book: Book
    let student: Student
    let dueDate: Date
    let onConfirm: () -> Void
    var onCancel: (() -> Void)? = nil

    var body: some View {
        BaseConfirmationView(
            type: .checkout,
            book: book,
            onConfirm: onConfirm,
            onCancel: onCancel
        ) {
            // Book Cover
            BookCoverImage(book: book, width: 120, height: 180)
                .padding(.top, 40)

            // Confirmation Details
            VStack(spacing: 16) {
                VStack {
                    // Book Info
                    VStack {
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
                            Text(student.fullName)
                                .valueText()
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
                                .warningIcon()
                            Text(dueDate.formatted(date: .long, time: .omitted))
                                .valueText()
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
