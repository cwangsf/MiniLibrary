//
//  ScanBookView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData

struct ScanBookView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allBooks: [Book]

    @State private var viewModel = ScanBookViewModel()
    @State private var showingAddCopyConfirmation = false

    var navigationTitle: String {
        switch viewModel.state {
        case .confirming:
            return "Confirm Book"
        case .editing:
            return "Edit Book Details"
        default:
            return "Scan Book"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                switch viewModel.state {
                case .scanning:
                    scannerView
                case .loading(let isbn):
                    loadingView(isbn: isbn)
                case .confirming(let book):
                    bookConfirmationView(book: book)
                case .editing, .error:
                    bookFormView
                case .existingBook:
                    Color.clear
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    // Don't show toolbar button in confirming state
                    if case .confirming = viewModel.state {
                        EmptyView()
                    } else {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddCopyConfirmation) {
                if let existingBook = viewModel.existingBook {
                    AddCopyConfirmationView(
                        book: existingBook,
                        onConfirm: { copiesToAdd in
                            addCopyToExistingBook(existingBook, copies: copiesToAdd)
                        },
                        onCancel: {
                            viewModel.reset()
                        }
                    )
                }
            }
            .onChange(of: viewModel.state) { _, newState in
                if case .existingBook = newState {
                    showingAddCopyConfirmation = true
                }
            }
        }
    }

    // MARK: - Scanner View
    private var scannerView: some View {
        ZStack {
            BarcodeScannerView(
                scannedCode: Binding(
                    get: { nil },
                    set: { if let code = $0 {
                        let existing = allBooks.first(where: { $0.isbn == code })
                        viewModel.handleScannedCode(code, existingBook: existing)
                    } }
                ),
                isScanning: .constant(true)
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top instructions
                VStack(spacing: 12) {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 60))
                        .foregroundStyle(.white)

                    Text("Point camera at ISBN barcode")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("Usually found on the back cover")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.black.opacity(0.6))

                Spacer()

                // Scanning target frame in the center
                VStack {
                    Text("Position barcode here")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.bottom, 8)

                    // Scanning frame
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green, lineWidth: 3)
                        .frame(width: 280, height: 120)
                        .overlay {
                            // Corner brackets
                            ZStack {
                                // Top-left corner
                                VStack {
                                    HStack {
                                        Rectangle()
                                            .fill(Color.green)
                                            .frame(width: 40, height: 4)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                                VStack {
                                    HStack {
                                        Rectangle()
                                            .fill(Color.green)
                                            .frame(width: 4, height: 40)
                                        Spacer()
                                    }
                                    Spacer()
                                }

                                // Top-right corner
                                VStack {
                                    HStack {
                                        Spacer()
                                        Rectangle()
                                            .fill(Color.green)
                                            .frame(width: 40, height: 4)
                                    }
                                    Spacer()
                                }
                                VStack {
                                    HStack {
                                        Spacer()
                                        Rectangle()
                                            .fill(Color.green)
                                            .frame(width: 4, height: 40)
                                    }
                                    Spacer()
                                }

                                // Bottom-left corner
                                VStack {
                                    Spacer()
                                    HStack {
                                        Rectangle()
                                            .fill(Color.green)
                                            .frame(width: 40, height: 4)
                                        Spacer()
                                    }
                                }
                                VStack {
                                    Spacer()
                                    HStack {
                                        Rectangle()
                                            .fill(Color.green)
                                            .frame(width: 4, height: 40)
                                        Spacer()
                                    }
                                }

                                // Bottom-right corner
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Rectangle()
                                            .fill(Color.green)
                                            .frame(width: 40, height: 4)
                                    }
                                }
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Rectangle()
                                            .fill(Color.green)
                                            .frame(width: 4, height: 40)
                                    }
                                }
                            }
                            .padding(8)
                        }
                }

                Spacer()

                // Bottom button
                Button("Enter ISBN Manually") {
                    viewModel.enterManualMode()
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.black.opacity(0.6))
            }
        }
    }

    // MARK: - Loading View
    private func loadingView(isbn: String) -> some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Fetching book information...")
                .font(.headline)

            Text("ISBN: \(isbn)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Book Confirmation View
    private func bookConfirmationView(book: Book) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Book Cover
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

                // Book Description
                if let description = book.bookDescription, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)

                        Text(description)
                            .font(.body)
                            .foregroundStyle(.primary)
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
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button {
                    addBook()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Confirm & Add Book")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    viewModel.confirmBook()
                } label: {
                    Text("Edit Details")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.gray.opacity(0.2))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    viewModel.reset()
                } label: {
                    Text("Cancel")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(.red)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Book Form View
    private var bookFormView: some View {
        Form {
            if case .error(let message) = viewModel.state {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(message)
                            .font(.caption)
                    }
                }
            }

            Section("Book Information") {
                TextField("Title", text: $viewModel.title)
                TextField("Author", text: $viewModel.author)
                TextField("ISBN", text: $viewModel.isbn)
            }

            Section("Copies") {
                Stepper("Total Copies: \(viewModel.totalCopies)", value: $viewModel.totalCopies, in: 1...99)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                addBook()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Book")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background((viewModel.title.isEmpty || viewModel.author.isEmpty) ? .gray : .blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(viewModel.title.isEmpty || viewModel.author.isEmpty)
            .padding()
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Actions
    private func addBook() {
        // Create a new book with proper values
        let book: Book

        // Check if we're in confirmation mode (direct from scan) or edit mode
        if case .confirming = viewModel.state, let scannedBook = viewModel.scannedBook {
            // In confirmation mode: use the scanned book's data directly
            book = Book(
                isbn: scannedBook.isbn,
                title: scannedBook.title,
                author: scannedBook.author,
                totalCopies: 1,
                availableCopies: 1,
                bookDescription: scannedBook.bookDescription,
                pageCount: scannedBook.pageCount,
                publishedDate: scannedBook.publishedDate,
                publisher: scannedBook.publisher,
                languageCode: scannedBook.languageCode,
                coverImageURL: scannedBook.coverImageURL
            )
        } else if let scannedBook = viewModel.scannedBook {
            // In edit mode: use the edited values from viewModel
            book = Book(
                isbn: viewModel.isbn.isEmpty ? nil : viewModel.isbn,
                title: viewModel.title,
                author: viewModel.author,
                totalCopies: viewModel.totalCopies,
                availableCopies: viewModel.totalCopies,
                bookDescription: scannedBook.bookDescription,
                pageCount: scannedBook.pageCount,
                publishedDate: scannedBook.publishedDate,
                publisher: scannedBook.publisher,
                languageCode: scannedBook.languageCode,
                coverImageURL: scannedBook.coverImageURL
            )
        } else {
            // Manual entry: create book from form fields only
            book = Book(
                isbn: viewModel.isbn.isEmpty ? nil : viewModel.isbn,
                title: viewModel.title,
                author: viewModel.author,
                totalCopies: viewModel.totalCopies,
                availableCopies: viewModel.totalCopies
            )
        }

        modelContext.insert(book)

        // Log activity
        let activity = Activity(
            type: .addBook,
            bookTitle: book.title,
            bookAuthor: book.author,
            additionalInfo: "\(book.totalCopies) \(book.totalCopies == 1 ? "copy" : "copies")"
        )
        modelContext.insert(activity)

        // Dismiss the view to go back to Add tab
        dismiss()
    }

    private func addCopyToExistingBook(_ book: Book, copies: Int) {
        book.totalCopies += copies
        book.availableCopies += copies

        // Log activity
        let activity = Activity(
            type: .addBook,
            bookTitle: book.title,
            bookAuthor: book.author,
            additionalInfo: "Added \(copies) more \(copies == 1 ? "copy" : "copies")"
        )
        modelContext.insert(activity)

        showingAddCopyConfirmation = false
        viewModel.reset()
    }
}

// MARK: - Add Copy Confirmation View
struct AddCopyConfirmationView: View {
    let book: Book
    let onConfirm: (Int) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var copiesToAdd = 1

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Book Cover
                    BookCoverImage(book: book, width: 120, height: 180)
                        .padding(.top, 40)

                    // Message
                    VStack(spacing: 16) {
                        Text("Book Already Exists")
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

                            // Current Inventory
                            VStack(spacing: 4) {
                                Text("Current Inventory")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Image(systemName: "books.vertical.fill")
                                        .foregroundStyle(.blue)
                                    Text("\(book.totalCopies) total copies")
                                        .font(.headline)
                                }
                                Text("\(book.availableCopies) available")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Divider()
                                .padding(.horizontal, 40)

                            // Add Copies
                            VStack(spacing: 8) {
                                Text("Add Copies")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Stepper("Add \(copiesToAdd) \(copiesToAdd == 1 ? "copy" : "copies")", value: $copiesToAdd, in: 1...99)
                                    .font(.headline)
                            }
                            .padding(.horizontal)
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
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button {
                            onCancel()
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
    ScanBookView()
        .modelContainer(for: [Book.self])
}
