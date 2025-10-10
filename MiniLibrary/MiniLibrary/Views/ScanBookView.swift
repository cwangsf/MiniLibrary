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
    var scannedISBN: String?
    var isScanning = true
    var bookInfo: BookInfo?
    var isLoading = false
    var errorMessage: String?

    var title = ""
    var author = ""
    var isbn = ""
    var totalCopies = 1

    func handleScannedCode(_ code: String) {
        scannedISBN = code
        isbn = code
        Task {
            await fetchBookInfo(isbn: code)
        }
    }

    @MainActor
    func fetchBookInfo(isbn: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Try Google Books API first (more reliable)
            let info = try await BookAPIService.shared.fetchBookInfoFromGoogle(isbn: isbn)
            bookInfo = info
            title = info.title
            author = info.author
            self.isbn = info.isbn ?? isbn
        } catch {
            // Fallback to manual entry
            errorMessage = "Could not fetch book info: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func reset() {
        scannedISBN = nil
        isScanning = true
        bookInfo = nil
        isLoading = false
        errorMessage = nil
        title = ""
        author = ""
        isbn = ""
        totalCopies = 1
    }
}

struct ScanBookView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = ScanBookViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isScanning {
                    scannerView
                } else if viewModel.isLoading {
                    loadingView
                } else {
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
                scannedCode: Bindable(viewModel).scannedISBN,
                isScanning: Bindable(viewModel).isScanning
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
                    viewModel.isScanning = false
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .onChange(of: viewModel.scannedISBN) { _, newValue in
            if let isbn = newValue {
                viewModel.handleScannedCode(isbn)
            }
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Fetching book information...")
                .font(.headline)

            if let isbn = viewModel.scannedISBN {
                Text("ISBN: \(isbn)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Book Form View
    private var bookFormView: some View {
        Form {
            if let error = viewModel.errorMessage {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
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
        let book = Book(
            isbn: viewModel.isbn.isEmpty ? nil : viewModel.isbn,
            title: viewModel.title,
            author: viewModel.author,
            totalCopies: viewModel.totalCopies,
            availableCopies: viewModel.totalCopies
        )

        modelContext.insert(book)

        // Show success and reset for next book
        viewModel.reset()
    }
}

#Preview {
    ScanBookView()
        .modelContainer(for: [Book.self])
}
