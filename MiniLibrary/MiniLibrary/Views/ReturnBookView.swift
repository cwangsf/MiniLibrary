//
//  ReturnBookView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData

struct ReturnBookView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var checkouts: [CheckoutRecord]

    @State private var showingReturnConfirmation = false
    @State private var checkoutToReturn: CheckoutRecord?

    var activeCheckouts: [CheckoutRecord] {
        checkouts.filter { $0.isActive }
    }

    var body: some View {
        List {
            if activeCheckouts.isEmpty {
                ContentUnavailableView(
                    "No Active Checkouts",
                    systemImage: "book.closed",
                    description: Text("There are no books currently checked out")
                )
            } else {
                ForEach(activeCheckouts) { checkout in
                    Button {
                        checkoutToReturn = checkout
                        showingReturnConfirmation = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(checkout.book?.title ?? "Unknown")
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text("Student: \(checkout.student?.libraryId ?? "Unknown")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "arrow.uturn.left.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
        }
        .navigationTitle("Return Book")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingReturnConfirmation) {
            if let checkout = checkoutToReturn, let book = checkout.book {
                ReturnConfirmationView(
                    book: book,
                    checkout: checkout,
                    onConfirm: {
                        returnBook(checkout)
                    }
                )
            }
        }
    }

    private func returnBook(_ checkout: CheckoutRecord) {
        checkout.returnDate = Date()
        if let book = checkout.book {
            book.availableCopies += 1

            // Log activity
            let activity = Activity(
                type: .return,
                bookTitle: book.title,
                bookAuthor: book.author,
                studentLibraryId: checkout.student?.libraryId,
                additionalInfo: nil
            )
            modelContext.insert(activity)
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ReturnBookView()
            .modelContainer(for: [CheckoutRecord.self, Book.self, Student.self, Activity.self])
    }
}
