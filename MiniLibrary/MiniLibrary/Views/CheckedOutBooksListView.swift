//
//  CheckedOutBooksListView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData

struct CheckedOutBooksListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<CheckoutRecord> { $0.returnDate == nil },
           sort: \CheckoutRecord.dueDate)
    private var activeCheckouts: [CheckoutRecord]

    var body: some View {
        List {
            if activeCheckouts.isEmpty {
                ContentUnavailableView(
                    "No Checked Out Books",
                    systemImage: "book.closed",
                    description: Text("All books are currently available")
                )
            } else {
                ForEach(activeCheckouts) { checkout in
                    CheckoutDetailRow(checkout: checkout)
                }
            }
        }
        .navigationTitle("Checked Out Books")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CheckoutDetailRow: View {
    let checkout: CheckoutRecord
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Book Title
            Text(checkout.book?.title ?? "Unknown Book")
                .font(.headline)

            // Student Info
            HStack {
                Image(systemName: "person.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(checkout.student?.libraryId ?? "Unknown")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Dates Info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Checked Out")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(checkout.checkoutDate, format: .dateTime.month().day().year())
                        .font(.caption)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Due Date")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(checkout.dueDate, format: .dateTime.month().day().year())
                        .font(.caption)
                        .foregroundStyle(checkout.isOverdue ? .red : .primary)
                }
            }

            // Overdue Badge
            if checkout.isOverdue {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text("OVERDUE")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.red)
                .clipShape(Capsule())
            }

            // Return Button
            Button {
                returnBook(checkout)
            } label: {
                HStack {
                    Image(systemName: "arrow.uturn.left.circle.fill")
                    Text("Return Book")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding(.vertical, 8)
    }

    private func returnBook(_ checkout: CheckoutRecord) {
        checkout.returnDate = Date()
        if let book = checkout.book {
            book.availableCopies += 1
        }
    }
}

#Preview {
    NavigationStack {
        CheckedOutBooksListView()
            .modelContainer(for: [Book.self, Student.self, CheckoutRecord.self])
    }
}
