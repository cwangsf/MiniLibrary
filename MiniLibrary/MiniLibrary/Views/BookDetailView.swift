//
//  BookDetailView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData

struct BookDetailView: View {
    let book: Book
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingCheckoutSheet = false
    @State private var isEditingNotes = false
    @State private var notesText = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Book Cover - Centered at top
                BookCoverImage(book: book, width: 180, height: 270)
                    .padding(.top, 20)

                // Book Info
                VStack(alignment: .center, spacing: 8) {
                    Text(book.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(book.author)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    if let isbn = book.isbn {
                        Text("ISBN: \(isbn)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let publisher = book.publisher {
                        Text(publisher)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let publishedDate = book.publishedDate {
                        Text("Published: \(publishedDate)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

                // Checkout Button
                if book.availableCopies >= 1 {
                    Button {
                        showingCheckoutSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Check Out Book")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }

                // Return Book Buttons
                if let checkouts = book.checkouts?.filter({ $0.isActive }), !checkouts.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(checkouts) { checkout in
                            Button {
                                returnBook(checkout)
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.uturn.left.circle.fill")
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Return Book")
                                            .fontWeight(.medium)
                                        Text("Student: \(checkout.student?.libraryId ?? "Unknown")")
                                            .font(.caption)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(.green)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Availability
                VStack(alignment: .leading, spacing: 8) {
                    Text("Availability")
                        .font(.headline)

                    HStack {
                        Label("\(book.availableCopies) available", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(book.availableCopies > 0 ? .green : .red)

                        Spacer()

                        Text("of \(book.totalCopies) total")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                // Active Checkouts
                if let checkouts = book.checkouts?.filter({ $0.isActive }), !checkouts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Currently Checked Out By")
                            .font(.headline)

                        ForEach(checkouts) { checkout in
                            HStack {
                                Text(checkout.student?.libraryId ?? "Unknown")
                                    .font(.subheadline)

                                Spacer()

                                Text("Due: \(checkout.dueDate, format: .dateTime.month().day())")
                                    .font(.caption)
                                    .foregroundStyle(checkout.isOverdue ? .red : .secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // Notes Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Notes")
                            .font(.headline)
                        Spacer()
                        Button(isEditingNotes ? "Done" : "Edit") {
                            if isEditingNotes {
                                saveNotes()
                            }
                            isEditingNotes.toggle()
                        }
                        .font(.subheadline)
                    }

                    if isEditingNotes {
                        TextEditor(text: $notesText)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(.background)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.secondary.opacity(0.3), lineWidth: 1)
                            )
                    } else {
                        if let notes = book.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.body)
                                .foregroundStyle(.primary)
                        } else {
                            Text("No notes yet. Tap Edit to add notes.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .italic()
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                Spacer()
            }
        }
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCheckoutSheet) {
            CheckoutBookView(book: book, onCheckoutComplete: {
                // Dismiss the detail view after checkout
                dismiss()
            })
        }
        .onAppear {
            notesText = book.notes ?? ""
        }
    }

    private func returnBook(_ checkout: CheckoutRecord) {
        checkout.returnDate = Date()
        if let book = checkout.book {
            book.availableCopies += 1
        }
    }

    private func saveNotes() {
        book.notes = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
