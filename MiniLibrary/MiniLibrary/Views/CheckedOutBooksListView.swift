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
    
    @State private var searchText = ""
    
    // Filter checkouts based on search text
    private var filteredCheckouts: [CheckoutRecord] {
        if searchText.isEmpty {
            return activeCheckouts
        }
        
        return activeCheckouts.filter { checkout in
            let bookTitle = checkout.book?.title ?? ""
            let studentName = checkout.student?.fullName ?? ""
            
            return bookTitle.localizedCaseInsensitiveContains(searchText) ||
                   studentName.localizedCaseInsensitiveContains(searchText)
        }
    }

    // Group checkouts by student class
    private var groupedCheckouts: [String: [CheckoutRecord]] {
        var grouped: [String: [CheckoutRecord]] = [:]

        for checkout in filteredCheckouts {
            if let classCode = checkout.student?.classCode, !classCode.isEmpty {
                if grouped[classCode] == nil {
                    grouped[classCode] = []
                }
                grouped[classCode]?.append(checkout)
            } else {
                // Group checkouts without class under "No Class"
                if grouped[""] == nil {
                    grouped[""] = []
                }
                grouped[""]?.append(checkout)
            }
        }

        return grouped
    }

    private var sortedSectionTitles: [String] {
        let titles = groupedCheckouts.keys.filter { !$0.isEmpty }.sorted()
        // Add "No Class" at the end if there are checkouts without a class
        if groupedCheckouts[""] != nil && !(groupedCheckouts[""]?.isEmpty ?? true) {
            return titles + [""]
        }
        return titles
    }

    var body: some View {
        List {
            if activeCheckouts.isEmpty {
                ContentUnavailableView(
                    "No Checked Out Books",
                    systemImage: "book.closed",
                    description: Text("All books are currently available")
                )
            } else if filteredCheckouts.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("No checkouts match '\(searchText)'")
                )
            } else {
                ForEach(sortedSectionTitles, id: \.self) { classCode in
                    Section {
                        ForEach(groupedCheckouts[classCode] ?? []) { checkout in
                            CheckoutDetailRow(checkout: checkout)
                        }
                    } header: {
                        Text(classCode.isEmpty ? "No Class" : classCode)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .navigationTitle("Checked Out Books")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search by book or student name")
    }
}

struct CheckoutDetailRow: View {
    let checkout: CheckoutRecord
    @Environment(\.modelContext) private var modelContext
    @State private var checkoutToReturn: CheckoutRecord?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Book Title
            Text(checkout.book?.title ?? "Unknown Book")
                .font(.headline)

            // Student Info
            HStack {
                Image(systemName: "person.fill")
                    .smallIcon(color: .secondary)
                Text(checkout.student?.fullName ?? "Unknown")
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
                    Text("OVERDUE")
                }
                .badge()
            }

            // Return Button
            Button {
                checkoutToReturn = checkout
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
        .sheet(item: $checkoutToReturn) { checkout in
            if let book = checkout.book {
                ReturnConfirmationView(
                    book: book,
                    checkout: checkout,
                    onConfirm: {
                        returnBook(checkout)
                        checkoutToReturn = nil
                    }
                )
            }
        }
    }

    private func returnBook(_ checkout: CheckoutRecord) {
        BookManagementService.returnBook(checkout, modelContext: modelContext)
    }
}

#Preview {
    NavigationStack {
        CheckedOutBooksListView()
            .modelContainer(for: [Book.self, Student.self, CheckoutRecord.self])
    }
}
