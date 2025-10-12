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

    var body: some View {
        NavigationStack {
            ZStack {
                switch viewModel.state {
                case .scanning:
                    scannerView
                case .loading(let isbn):
                    loadingView(isbn: isbn)
                case .editing, .error:
                    bookFormView
                case .existingBook:
                    Color.clear
                }
            }
            .navigationTitle("Scan Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
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

            VStack {
                Spacer()

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
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding()

                Spacer()

                Button("Enter ISBN Manually") {
                    viewModel.enterManualMode()
                }
                .buttonStyle(.borderedProminent)
                .padding()
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

            Section {
                Button("Add Book") {
                    addBook()
                }
                .disabled(viewModel.title.isEmpty || viewModel.author.isEmpty)

                Button("Scan Another Book") {
                    viewModel.reset()
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Actions
    private func addBook() {
        // If we have scanned book with metadata, use it; otherwise create new
        let book: Book
        if let scannedBook = viewModel.scannedBook {
            // Update copies from form
            scannedBook.totalCopies = viewModel.totalCopies
            scannedBook.availableCopies = viewModel.totalCopies
            // Update in case user edited the fields
            scannedBook.title = viewModel.title
            scannedBook.author = viewModel.author
            scannedBook.isbn = viewModel.isbn.isEmpty ? nil : viewModel.isbn
            book = scannedBook
        } else {
            // Manual entry
            book = Book(
                isbn: viewModel.isbn.isEmpty ? nil : viewModel.isbn,
                title: viewModel.title,
                author: viewModel.author,
                totalCopies: viewModel.totalCopies,
                availableCopies: viewModel.totalCopies
            )
        }

        modelContext.insert(book)

        // Show success and reset for next book
        viewModel.reset()
    }

    private func addCopyToExistingBook(_ book: Book, copies: Int) {
        book.totalCopies += copies
        book.availableCopies += copies
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
