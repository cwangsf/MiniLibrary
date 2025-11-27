//
//  ScanResultView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData

struct ScanResultView: View {
    let book: Book
    let scanPurpose: ScanBookViewModel.ScanPurpose
    let isExistingBook: Bool  // true if book already exists in system, false if newly confirmed
    let onConfirm: (Int) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var copiesToAdd = 1
    @State private var showingCheckoutView = false
    @State private var showingReturnView = false
    @State private var navigationPath = NavigationPath()

    // Get active checkouts for this book
    var activeCheckouts: [CheckoutRecord] {
        book.checkouts?.filter { $0.isActive } ?? []
    }

    var hasActiveCheckouts: Bool {
        !activeCheckouts.isEmpty
    }

    var headerTitle: String {
        switch scanPurpose {
        case .addBook:
            return "Book Already Exists"
        case .checkout:
            return "Ready to Checkout"
        case .returnBook:
            return "Ready to Return"
        }
    }

    @ViewBuilder
    var actionButtons: some View {
        switch scanPurpose {
        case .addBook:
            // Always show "Add" option to allow adding more copies
            Button {
                onConfirm(copiesToAdd)
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add \(copiesToAdd) \(copiesToAdd == 1 ? "Copy" : "Copies")")
                }
                .prominentButton(color: .blue)
            }

//            Button {
//                book.isWishlistItem = true
//                onConfirm(copiesToAdd)
//                dismiss()
//            } label: {
//                HStack {
//                    Image(systemName: "list.star.fill")
//                    Text("Add to Wishlist")
//                }
//                .prominentButton(color: .purple)
//            }

        case .checkout:
            if book.availableCopies > 0 {
                Button {
                    showingCheckoutView = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Proceed to Checkout")
                    }
                    .prominentButton(color: .green)
                }
            } else {
                Text("No copies available")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

        case .returnBook:
            if hasActiveCheckouts {
                if activeCheckouts.count == 1, let checkout = activeCheckouts.first {
                    // Single checkout - direct navigation
                    NavigationLink(value: checkout) {
                        HStack {
                            Image(systemName: "arrow.uturn.backward.circle.fill")
                            Text("Proceed to Return")
                        }
                        .prominentButton(color: .orange)
                    }
                } else {
                    // Multiple checkouts - navigate to selection list
                    NavigationLink(value: "selectReturn") {
                        HStack {
                            Image(systemName: "arrow.uturn.backward.circle.fill")
                            Text("Select Copy to Return")
                        }
                        .prominentButton(color: .orange)
                    }
                }
            } else {
                Text("Currently no checkout for this book")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 24) {
                    // Book Cover
                    BookCoverImage(book: book, width: 120, height: 180)
                        .padding(.top, 40)

                    // Message and Book Info
                    VStack(spacing: 16) {
                        Text(headerTitle)
                            .sectionTitle()

                        VStack(spacing: 12) {
                            // Book Info
                            VStack(spacing: 4) {
                                Text("Book")
                                    .labelStyle()
                                Text(book.title)
                                    .bookTitle()
                                if let author = book.author {
                                    Text(author)
                                        .bookAuthor()
                                }
                            }

                            // Show relevant information based on scanPurpose
                            switch scanPurpose {
                            case .addBook:
                                Divider()
                                    .padding(.horizontal, 40)

                                // Current Inventory
                                VStack(spacing: 4) {
                                    Text("Current Inventory")
                                        .labelStyle()
                                    HStack {
                                        Image(systemName: "books.vertical.fill")
                                            .iconStyle(color: .blue)
                                        Text("\(book.totalCopies) total copies")
                                            .valueText()
                                    }
                                    Text("\(book.availableCopies) available")
                                        .bookAuthor()
                                }

                                // Active Checkouts (if any)
                                if hasActiveCheckouts {
                                    Divider()
                                        .padding(.horizontal, 40)

                                    VStack(spacing: 4) {
                                        Text("Currently Checked Out")
                                            .labelStyle()
                                        VStack(spacing: 4) {
                                            ForEach(activeCheckouts) { checkout in
                                                HStack {
                                                    Image(systemName: "person.fill")
                                                        .smallIcon(color: .orange)
                                                    Text(checkout.student?.fullName ?? "Unknown")
                                                        .font(.subheadline)
                                                }
                                            }
                                        }
                                    }
                                }

                                Divider()
                                    .padding(.horizontal, 40)

                                // Add Copies
                                VStack(spacing: 8) {
                                    Text("Add Copies")
                                        .labelStyle()
                                    Stepper("Add \(copiesToAdd) \(copiesToAdd == 1 ? "copy" : "copies")", value: $copiesToAdd, in: 1...99)
                                        .valueText()
                                }
                                .padding(.horizontal)

                            case .checkout:
                                Divider()
                                    .padding(.horizontal, 40)

                                // Available copies info
                                VStack(spacing: 4) {
                                    Text("Availability")
                                        .labelStyle()
                                    HStack {
                                        Image(systemName: "books.vertical.fill")
                                            .iconStyle(color: book.availableCopies > 0 ? .green : .red)
                                        Text("\(book.availableCopies) available")
                                            .valueText()
                                    }
                                }

                            case .returnBook:
                                Divider()
                                    .padding(.horizontal, 40)

                                // Active checkouts for this book
                                if hasActiveCheckouts {
                                    VStack(spacing: 4) {
                                        Text("Checked Out Copies")
                                            .labelStyle()
                                        Text("\(activeCheckouts.count) \(activeCheckouts.count == 1 ? "copy" : "copies") checked out")
                                            .valueText()
                                    }
                                } else {
                                    VStack(spacing: 4) {
                                        Text("Status")
                                            .labelStyle()
                                        Text("No active checkouts")
                                            .valueText()
                                    }
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
                        actionButtons

                        Button {
                            onCancel()
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
            .navigationDestination(for: String.self) { destination in
                if destination == "selectReturn" {
                    // Show selection list for multiple checkouts
                    List(activeCheckouts) { checkout in
                        NavigationLink(value: checkout) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(checkout.student?.fullName ?? "Unknown Student")
                                    .font(.headline)
                                Text("Due: \(checkout.dueDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if checkout.isOverdue {
                                    Text("OVERDUE")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }
                    .navigationTitle("Select Student")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            .navigationDestination(for: CheckoutRecord.self) { checkout in
                // Show return confirmation
                ScrollView {
                    VStack(spacing: 24) {
                        // Title
                        Text("Confirm Return")
                            .sectionTitle()
                            .padding(.top, 20)

                        // Book Cover
                        BookCoverImage(book: book, width: 120, height: 180)

                        // Confirmation details
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
                        .padding(.horizontal)

                        // Action Buttons
                        VStack(spacing: 12) {
                            Button {
                                returnBook(checkout)
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Confirm Return")
                                }
                                .prominentButton(color: .green)
                            }

                            Button {
                                navigationPath.removeLast()
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
                .navigationTitle("Return Book")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .presentationDetents([.medium, .large])
        .sheet(isPresented: $showingCheckoutView) {
            CheckoutBookView(book: book) {
                // After checkout completes, dismiss the confirmation view
                dismiss()
                onCancel()
            }
        }
        .sheet(isPresented: $showingReturnView) {
            ReturnBookView(book: book) {
                // After return completes, dismiss the confirmation view
                dismiss()
                onCancel()
            }
        }
    }

    private func returnBook(_ checkout: CheckoutRecord) {
        BookManagementService.returnBook(checkout, modelContext: modelContext)

        // Pop back to root and dismiss the sheet
        navigationPath = NavigationPath()
        dismiss()
        onCancel()
    }
}

#Preview {
    NavigationStack {
        ScanResultView(book: Book(title: ".Test Book",
                                  totalCopies: 1),
                       scanPurpose: .addBook, isExistingBook: false,
                       onConfirm: { _ in },
                       onCancel: {})
            .modelContainer(for: [Book.self, CheckoutRecord.self, Student.self])
    }
}
