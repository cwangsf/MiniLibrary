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
    let onConfirm: (Int) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var copiesToAdd = 1
    @State private var showingCheckoutView = false
    @State private var navigationPath = NavigationPath()

    // Get active checkouts for this book
    var activeCheckouts: [CheckoutRecord] {
        book.checkouts?.filter { $0.isActive } ?? []
    }

    var hasActiveCheckouts: Bool {
        !activeCheckouts.isEmpty
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 24) {
                    // Book Cover
                    BookCoverImage(book: book, width: 120, height: 180)
                        .padding(.top, 40)

                    // Message
                    VStack(spacing: 16) {
                        Text("Book Already Exists")
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
                            if scanPurpose == .addBook {
                                VStack(spacing: 8) {
                                    Text("Add Copies")
                                        .labelStyle()
                                    Stepper("Add \(copiesToAdd) \(copiesToAdd == 1 ? "copy" : "copies")", value: $copiesToAdd, in: 1...99)
                                        .valueText()
                                }
                                .padding(.horizontal)
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
                            onConfirm(copiesToAdd)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add \(copiesToAdd) \(copiesToAdd == 1 ? "Copy" : "Copies")")
                            }
                            .prominentButton(color: .blue)
                        }

                        Button {
                            showingCheckoutView = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                Text("Check Out Book")
                            }
                            .prominentButton(color: .green)
                        }
                        .disabled(book.availableCopies == 0)

                        // Return Book Button (only show if there are active checkouts)
                        if hasActiveCheckouts {
                            if activeCheckouts.count == 1, let checkout = activeCheckouts.first {
                                // Single checkout - direct navigation
                                NavigationLink(value: checkout) {
                                    HStack {
                                        Image(systemName: "arrow.uturn.left.circle.fill")
                                        Text("Return Book")
                                    }
                                    .prominentButton(color: .orange)
                                }
                            } else {
                                // Multiple checkouts - navigate to selection list
                                NavigationLink(value: "selectReturn") {
                                    HStack {
                                        Image(systemName: "arrow.uturn.left.circle.fill")
                                        Text("Return Book")
                                    }
                                    .prominentButton(color: .orange)
                                }
                            }
                        }

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
                       scanPurpose: .addBook,
                       onConfirm: { _ in },
                       onCancel: {})
            .modelContainer(for: [Book.self, CheckoutRecord.self, Student.self])
    }
}
