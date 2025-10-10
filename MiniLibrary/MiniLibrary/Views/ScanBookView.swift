//
//  ScanBookView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData
import Observation

@Observable
class ScanBookViewModel {
    enum ScanState {
        case scanning
        case loading(isbn: String)
        case editing(book: Book?)
        case error(message: String)
    }

    var state: ScanState = .scanning
    var scannedBook: Book?

    var title = ""
    var author = ""
    var isbn = ""
    var totalCopies = 1

    func handleScannedCode(_ code: String) {
        isbn = code
        state = .loading(isbn: code)
        Task {
            await fetchBookInfo(isbn: code)
        }
    }

    @MainActor
    func fetchBookInfo(isbn: String) async {
        do {
            // Try Google Books API first (more reliable)
            let book = try await BookAPIService.shared.fetchBookInfoFromGoogle(isbn: isbn)
            scannedBook = book
            title = book.title
            author = book.author
            self.isbn = book.isbn ?? isbn

            print("Debug: Fetched book - Title: \(book.title), Author: \(book.author), ISBN: \(book.isbn ?? "nil")")
            print("Debug: ViewModel - Title: \(title), Author: \(author), ISBN: \(self.isbn)")

            state = .editing(book: book)
        } catch {
            let errorMsg = "Could not fetch book info: \(error.localizedDescription)"
            print("Debug: API Error - \(error)")
            state = .error(message: errorMsg)
        }
    }

    func reset() {
        state = .scanning
        scannedBook = nil
        title = ""
        author = ""
        isbn = ""
        totalCopies = 1
    }

    func enterManualMode() {
        state = .editing(book: nil)
    }
}

struct ScanBookView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = ScanBookViewModel()

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
        }
    }

    // MARK: - Scanner View
    private var scannerView: some View {
        ZStack {
            BarcodeScannerView(
                scannedCode: Binding(
                    get: { nil },
                    set: { if let code = $0 { viewModel.handleScannedCode(code) } }
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
}

#Preview {
    ScanBookView()
        .modelContainer(for: [Book.self])
}
