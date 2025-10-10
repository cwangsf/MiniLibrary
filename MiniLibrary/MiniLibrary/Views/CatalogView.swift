//
//  CatalogView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData

struct CatalogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.title) private var books: [Book]
    @State private var searchText = ""

    var filteredBooks: [Book] {
        if searchText.isEmpty {
            return books
        } else {
            return books.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.author.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredBooks) { book in
                    NavigationLink(destination: BookDetailView(book: book)) {
                        BookRowView(book: book)
                    }
                }
            }
            .navigationTitle("Catalog")
            .searchable(text: $searchText, prompt: "Search books or authors")
        }
    }
}

struct BookRowView: View {
    let book: Book

    var body: some View {
        HStack(spacing: 12) {
            // Book Cover
            BookCoverImage(book: book, width: 60, height: 90)

            // Book Info
            VStack(alignment: .leading, spacing: 6) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    if let isbn = book.isbn {
                        Text("ISBN: \(isbn)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "book.fill")
                            .font(.caption)

                        Text("\(book.availableCopies)/\(book.totalCopies)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(book.availableCopies > 0 ? .green : .red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct BookDetailView: View {
    let book: Book
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingCheckoutSheet = false

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

                Spacer()
            }
        }
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCheckoutSheet) {
            QuickCheckoutView(book: book, onCheckoutComplete: {
                // Dismiss the detail view after checkout
                dismiss()
            })
        }
    }

    private func returnBook(_ checkout: CheckoutRecord) {
        checkout.returnDate = Date()
        if let book = checkout.book {
            book.availableCopies += 1
        }
    }
}

// MARK: - Quick Checkout Sheet
struct QuickCheckoutView: View {
    let book: Book
    let onCheckoutComplete: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Student.libraryId) private var students: [Student]

    @State private var selectedStudent: Student?
    @State private var dueDate = Date().addingTimeInterval(14 * 24 * 60 * 60) // 2 weeks
    @State private var showingConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Book") {
                    Text(book.title)
                        .font(.headline)
                }

                Section("Select Student") {
                    Picker("Student", selection: $selectedStudent) {
                        Text("Select a student").tag(nil as Student?)
                        ForEach(students) { student in
                            Text(student.libraryId).tag(student as Student?)
                        }
                    }
                }

                Section("Due Date") {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }

                Section {
                    Button("Check Out") {
                        showingConfirmation = true
                    }
                    .disabled(selectedStudent == nil)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Check Out Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingConfirmation) {
                if let student = selectedStudent {
                    CheckoutConfirmationView(
                        book: book,
                        student: student,
                        dueDate: dueDate,
                        onConfirm: {
                            checkoutBook()
                        }
                    )
                }
            }
        }
    }

    private func checkoutBook() {
        guard let student = selectedStudent else { return }

        let checkout = CheckoutRecord(
            student: student,
            book: book,
            dueDate: dueDate,
            checkedOutByStaffId: "ADMIN" // TODO: Get actual staff ID
        )

        book.availableCopies -= 1
        modelContext.insert(checkout)
        dismiss()
        onCheckoutComplete()
    }
}

// MARK: - Checkout Confirmation Sheet
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
                    // Book Cover
                    BookCoverImage(book: book, width: 120, height: 180)
                        .padding(.top, 40)

                    // Confirmation Message
                    VStack(spacing: 16) {
                        Text("Confirm Checkout")
                            .font(.title2)
                            .fontWeight(.bold)

                        VStack(spacing: 12) {
                        // Book Info
                        VStack(spacing: 4) {
                            Text("Book")
                                .font(.caption)
                                .foregroundStyle(.secondary)
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
                        VStack(spacing: 4) {
                            Text("Student")
                                .font(.caption)
                                .foregroundStyle(.secondary)
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
                        VStack(spacing: 4) {
                            Text("Due Date")
                                .font(.caption)
                                .foregroundStyle(.secondary)
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

#Preview {
    CatalogView()
        .modelContainer(for: [Book.self, CheckoutRecord.self])
}
