//
//  AddView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData
internal import UniformTypeIdentifiers

struct AddView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.title) private var books: [Book]
    @Query private var students: [Student]
    @Query private var checkouts: [CheckoutRecord]
    @Query private var activities: [Activity]
    @State private var exportFileURL: URL?
    @State private var isExporting = false
    @State private var exportWishlistFileURL: URL?
    @State private var isExportingWishlist = false
    @State private var showingDeleteConfirmation = false
    @State private var showingImportPicker = false
    @State private var importResult: ImportResult?
    @State private var showingImportResult = false
    @State private var importType: ImportType?

    var body: some View {
        NavigationStack {
            List {
                // Quick Scan - Prominent Section
                Section {
                    NavigationLink(destination: ScanBookView()) {
                        HStack(spacing: 16) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 32))
                                .foregroundStyle(.blue)
                                .frame(width: 50)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Scan Book Barcode")
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text("Add to Catalog/Wishlist, check out, or return books instantly")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Quick Actions")
                }

                // Manual Entry Options
                Section("Add Items") {
                    NavigationLink(destination: AddBookView()) {
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundStyle(.gray)
                            Text("Add New Book Manually")
                                .foregroundStyle(.tint)
                        }
                    }

                    NavigationLink(destination: AddWishlistItemView()) {
                        HStack {
                            Image(systemName: "list.star")
                                .foregroundStyle(.green)
                            Text("Add to Wishlist")
                                .foregroundStyle(.tint)
                        }
                    }

                    NavigationLink(destination: AddStudentView()) {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.orange)
                            Text("Add New Student")
                                .foregroundStyle(.tint)
                        }
                    }
                }

                Section("Manage Checkouts") {
                    NavigationLink(destination: CheckoutBookView()) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Check Out Book")
                                .foregroundStyle(.tint)
                        }
                    }

                    NavigationLink(destination: ReturnBookView()) {
                        HStack {
                            Image(systemName: "arrow.left.circle.fill")
                                .foregroundStyle(.green)
                            Text("Return Book")
                                .foregroundStyle(.tint)
                        }
                    }
                }

                Section("Export") {
                    // Export Catalog
                    ExportCatalogRow(
                        isExporting: isExporting,
                        exportFileURL: exportFileURL,
                        onExport: {
                            Task {
                                await exportCatalog()
                            }
                        }
                    )

                    // Export Wishlist
                    ExportWishlistRow(
                        isExporting: isExportingWishlist,
                        exportFileURL: exportWishlistFileURL,
                        onExport: {
                            Task {
                                await exportWishlist()
                            }
                        }
                    )

                    // Import Catalog
                    ImportCatalogRow {
                        importType = .catalog
                        showingImportPicker = true
                    }

                    // Import Wishlist
                    ImportWishlistRow {
                        importType = .wishlist
                        showingImportPicker = true
                    }

                    // Delete All Data
                    Button {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundStyle(.red)
                            Text("Delete All Data")
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }
            .navigationTitle("Add")
            .alert("Delete All Data?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This will permanently delete all books, students, checkouts, and activities. This action cannot be undone.")
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.commaSeparatedText, .text],
                allowsMultipleSelection: false
            ) { result in
                if importType == .catalog {
                    handleImportResult(result)
                } else if importType == .wishlist {
                    handleImportWishlistResult(result)
                }
            }
            .alert(importResult?.title ?? "Import Result", isPresented: $showingImportResult) {
                Button("OK", role: .cancel) { }
            } message: {
                if let result = importResult {
                    Text(result.message)
                }
            }
            .task {
                // Pre-generate the export files in background
                await exportCatalog()
                await exportWishlist()
            }
        }
    }

    private func exportCatalog() async {
        isExporting = true

        // Capture books array to avoid cross-context issues
        let catalogBooks = books.filter { !$0.isWishlistItem }

        // Run export in background
        let url = await Task.detached {
            let csvContent = CSVExporter.exportBooks(catalogBooks)
            return CSVExporter.saveToTemporaryFile(csvContent, filename: "library_catalog.csv")
        }.value

        await MainActor.run {
            exportFileURL = url
            isExporting = false
        }
    }

    private func exportWishlist() async {
        isExportingWishlist = true

        // Capture wishlist books to avoid cross-context issues
        let wishlistBooks = books.filter { $0.isWishlistItem }

        // Run export in background
        let url = await Task.detached {
            let csvContent = CSVExporter.exportBooks(wishlistBooks)
            return CSVExporter.saveToTemporaryFile(csvContent, filename: "library_wishlist.csv")
        }.value

        await MainActor.run {
            exportWishlistFileURL = url
            isExportingWishlist = false
        }
    }

    private func deleteAllData() {
        // Delete all activities
        for activity in activities {
            modelContext.delete(activity)
        }

        // Delete all checkout records
        for checkout in checkouts {
            modelContext.delete(checkout)
        }

        // Delete all books (catalog and wishlist)
        for book in books {
            modelContext.delete(book)
        }

        // Delete all students
        for student in students {
            modelContext.delete(student)
        }

        // Reset export URLs
        exportFileURL = nil
        exportWishlistFileURL = nil
    }

    private func fetchCoverImagesForImportedBooks() async {
        // Find all books with ISBN but no cover image
        let booksNeedingCovers = books.filter { book in
            book.isbn != nil && book.coverImageURL == nil && !book.isWishlistItem
        }

        print("Fetching cover images for \(booksNeedingCovers.count) books in background...")

        // Fetch covers for each book
        for book in booksNeedingCovers {
            guard let isbn = book.isbn else { continue }

            do {
                let fetchedBook = try await BookAPIService.shared.fetchBookInfoFromGoogle(isbn: isbn)

                // Update the book with fetched metadata on main actor
                await MainActor.run {
                    if book.coverImageURL == nil {
                        book.coverImageURL = fetchedBook.coverImageURL
                    }
                    if book.bookDescription == nil {
                        book.bookDescription = fetchedBook.bookDescription
                    }
                    if book.pageCount == nil {
                        book.pageCount = fetchedBook.pageCount
                    }
                    if book.publishedDate == nil {
                        book.publishedDate = fetchedBook.publishedDate
                    }
                    if book.publisher == nil {
                        book.publisher = fetchedBook.publisher
                    }
                    if book.languageCode == nil {
                        book.languageCode = fetchedBook.languageCode
                    }
                }

                print("✓ Fetched cover for: \(book.title)")
            } catch {
                print("✗ Failed to fetch cover for \(book.title): \(error.localizedDescription)")
            }
        }

        print("Finished fetching cover images")
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let fileURL = urls.first else {
                importResult = ImportResult(
                    title: "Import Failed",
                    message: "No file selected",
                    isSuccess: false
                )
                showingImportResult = true
                return
            }

            // Start accessing security-scoped resource
            guard fileURL.startAccessingSecurityScopedResource() else {
                importResult = ImportResult(
                    title: "Import Failed",
                    message: "Unable to access the selected file",
                    isSuccess: false
                )
                showingImportResult = true
                return
            }

            do {
                let csvContent = try String(contentsOf: fileURL, encoding: .utf8)
                let importedCount = try CSVImporter.importBooks(from: csvContent, modelContext: modelContext)

                importResult = ImportResult(
                    title: "Import Successful",
                    message: "Successfully imported \(importedCount) book\(importedCount == 1 ? "" : "s") from the CSV file. Cover images will load in the background.",
                    isSuccess: true
                )

                // Log activity
                ActivityLogger.logCatalogCSVImport(count: importedCount, modelContext: modelContext)

                showingImportResult = true

                // Fetch cover images in background
                Task {
                    await fetchCoverImagesForImportedBooks()
                }
            } catch {
                importResult = ImportResult(
                    title: "Import Failed",
                    message: error.localizedDescription,
                    isSuccess: false
                )
                showingImportResult = true
            }

            fileURL.stopAccessingSecurityScopedResource()

        case .failure(let error):
            importResult = ImportResult(
                title: "Import Failed",
                message: error.localizedDescription,
                isSuccess: false
            )
            showingImportResult = true
        }
    }

    private func handleImportWishlistResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let fileURL = urls.first else {
                importResult = ImportResult(
                    title: "Import Failed",
                    message: "No file selected",
                    isSuccess: false
                )
                showingImportResult = true
                return
            }

            // Start accessing security-scoped resource
            guard fileURL.startAccessingSecurityScopedResource() else {
                importResult = ImportResult(
                    title: "Import Failed",
                    message: "Unable to access the selected file",
                    isSuccess: false
                )
                showingImportResult = true
                return
            }

            do {
                let csvContent = try String(contentsOf: fileURL, encoding: .utf8)
                let importedCount = try CSVImporter.importWishlist(from: csvContent, modelContext: modelContext)

                importResult = ImportResult(
                    title: "Import Successful",
                    message: "Successfully imported \(importedCount) book\(importedCount == 1 ? "" : "s") to wishlist from the CSV file.",
                    isSuccess: true
                )

                // Log activity
                ActivityLogger.logWishlistCSVImport(count: importedCount, modelContext: modelContext)

                showingImportResult = true
            } catch {
                importResult = ImportResult(
                    title: "Import Failed",
                    message: error.localizedDescription,
                    isSuccess: false
                )
                showingImportResult = true
            }

            fileURL.stopAccessingSecurityScopedResource()

        case .failure(let error):
            importResult = ImportResult(
                title: "Import Failed",
                message: error.localizedDescription,
                isSuccess: false
            )
            showingImportResult = true
        }
    }
}

// MARK: - Supporting Types

struct ImportResult {
    let title: String
    let message: String
    let isSuccess: Bool
}

enum ImportType {
    case catalog
    case wishlist
}

#Preview {
    AddView()
        .modelContainer(for: [Book.self, Student.self, CheckoutRecord.self])
}
