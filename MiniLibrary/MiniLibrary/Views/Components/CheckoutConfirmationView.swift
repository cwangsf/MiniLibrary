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
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Confirm Checkout")
                        .sectionTitle()
                    // Book Cover
                    BookCoverImage(book: book, width: 120, height: 180)
                        .padding(.top, 40)

                    // Confirmation Message
                    VStack(spacing: 16) {
                        VStack{
                            // Book Info
                            VStack {
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
                                    Text(student.libraryId)
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
                    .padding(.horizontal)

                    // Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            onConfirm()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Confirm Checkout")
                            }
                            .prominentButton(color: .blue)
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
}
