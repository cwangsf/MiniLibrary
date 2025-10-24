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
                        .font(.title2)
                        .fontWeight(.bold)
                    // Book Cover
                    BookCoverImage(book: book, width: 120, height: 180)
                        .padding(.top, 40)

                    // Confirmation Message
                    VStack(spacing: 16) {
                        VStack{
                            // Book Info
                            VStack {
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
                            HStack {
                                Text("Student")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(.blue)
                                    Text(student.libraryId)
                                        .font(.headline)
                                }
                            }

                            Divider()
                                .padding(.horizontal, 40)

                            // Due Date
                            HStack {
                                Text("Due Date")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundStyle(.orange)
                                    Text(dueDate.formatted(date: .long, time: .omitted))
                                        .font(.headline)
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
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
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
