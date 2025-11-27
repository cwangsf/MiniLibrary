//
//  ReturnBookView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData

struct ReturnBookView: View {
    let book: Book?
    var onReturnComplete: (() -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var checkouts: [CheckoutRecord]

    @State private var showingReturnConfirmation = false
    @State private var checkoutToReturn: CheckoutRecord?

    var activeCheckouts: [CheckoutRecord] {
        if let book = book {
            return checkouts.filter { $0.isActive && $0.book?.id == book.id }
        }
        return checkouts.filter { $0.isActive }
    }

    init(book: Book? = nil, onReturnComplete: (() -> Void)? = nil) {
        self.book = book
        self.onReturnComplete = onReturnComplete
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

                                Text("Student: \(checkout.student?.fullName ?? "Unknown")")
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
                NavigationStack {
                    ReturnConfirmationView(
                        book: book,
                        checkout: checkout,
                        onConfirm: {
                            returnBook(checkout)
                        }
                    )
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingReturnConfirmation = false
                            }
                        }
                    }
                    .navigationTitle("Return Book")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    private func returnBook(_ checkout: CheckoutRecord) {
        BookManagementService.returnBook(checkout, modelContext: modelContext)
        onReturnComplete?()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ReturnBookView()
            .modelContainer(for: [CheckoutRecord.self, Book.self, Student.self, Activity.self])
    }
}
