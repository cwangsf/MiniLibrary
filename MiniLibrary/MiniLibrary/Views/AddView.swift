//
//  AddView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData
import os
internal import UniformTypeIdentifiers

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MiniLibrary", category: "AddView")

struct AddView: View {
    @Environment(\.modelContext) private var modelContext
    // Removed @Query properties - data now fetched on-demand for exports only
    @State private var exportFileURL: URL?
    @State private var isExporting = false
    @State private var exportWishlistFileURL: URL?
    @State private var isExportingWishlist = false
    @State private var exportStudentsFileURL: URL?
    @State private var isExportingStudents = false
    @State private var exportCheckoutsFileURL: URL?
    @State private var isExportingCheckouts = false
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
                    NavigationLink(destination: ScanBookView(scanPurpose: .addBook)) {
                        HStack(spacing: 16) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 32))
                                .foregroundStyle(.blue)
                                .frame(width: 50)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Scan Book Barcode")
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text("Add to Catalog/Wishlist instantly")
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

                // Export Section
                Section("Export Data") {
                    // Export Catalog
                    HStack {
                        ExportCatalogRow(
                            isExporting: isExporting,
                            exportFileURL: exportFileURL,
                            onExport: {
                                Task {
                                    await exportCatalog()
                                }
                            }
                        )
                        if isExporting {
                            Spacer()
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    // Export Wishlist
                    HStack {
                        ExportWishlistRow(
                            isExporting: isExportingWishlist,
                            exportFileURL: exportWishlistFileURL,
                            onExport: {
                                Task {
                                    await exportWishlist()
                                }
                            }
                        )
                        if isExportingWishlist {
                            Spacer()
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    // Export Students
                    HStack {
                        ExportStudentsRow(
                            isExporting: isExportingStudents,
                            exportFileURL: exportStudentsFileURL,
                            onExport: {
                                Task {
                                    await exportStudents()
                                }
                            }
                        )
                        if isExportingStudents {
                            Spacer()
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    // Export Checkouts
                    HStack {
                        ExportCheckoutsRow(
                            isExporting: isExportingCheckouts,
                            exportFileURL: exportCheckoutsFileURL,
                            onExport: {
                                Task {
                                    await exportCheckouts()
                                }
                            }
                        )
                        if isExportingCheckouts {
                            Spacer()
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                
                // Import Section
                Section("Import Data") {
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
                    
                    // Import Students
                    ImportStudentsRow {
                        importType = .students
                        showingImportPicker = true
                    }
                    
                    // Import Checkout Records
                    ImportCheckoutRecordsRow {
                        importType = .checkouts
                        showingImportPicker = true
                    }
                }
                
                // Delete Section
                Section("Danger Zone") {
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

                // App Info Section
                Section("About") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("App Version")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(getAppVersion() + " (" + getAppBuild() + ")")
                                
                        }
                    }
                    .padding(.vertical, 4)
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
                } else if importType == .students {
                    handleImportStudentsResult(result)
                } else if importType == .checkouts {
                    handleImportCheckoutsResult(result)
                }
            }
            .alert(importResult?.title ?? "Import Result", isPresented: $showingImportResult) {
                Button("OK", role: .cancel) { }
            } message: {
                if let result = importResult {
                    Text(result.message)
                }
            }
        }
    }

    private func exportCatalog() async {
        isExporting = true

        // Fetch catalog books on-demand (lazy loading)
        let descriptor = FetchDescriptor<Book>(
            predicate: #Predicate { !$0.isWishlistItem }
        )
        
        guard let catalogBooks = try? modelContext.fetch(descriptor) else {
            logger.error("Failed to fetch catalog books for export")
            isExporting = false
            return
        }

        // Export CSV
        let csvContent = CSVExporter.exportBooks(catalogBooks)
        let filename = "book_catalog\(dateSuffix()).csv"
        let url = CSVExporter.saveToTemporaryFile(csvContent, filename: filename)

        exportFileURL = url
        isExporting = false
    }

    private func exportWishlist() async {
        isExportingWishlist = true

        // Fetch wishlist books on-demand (lazy loading)
        let descriptor = FetchDescriptor<Book>(
            predicate: #Predicate { $0.isWishlistItem }
        )
        
        guard let wishlistBooks = try? modelContext.fetch(descriptor) else {
            logger.error("Failed to fetch wishlist books for export")
            isExportingWishlist = false
            return
        }

        // Export CSV
        let csvContent = CSVExporter.exportBooks(wishlistBooks)
        let url = CSVExporter.saveToTemporaryFile(csvContent, filename: "wishlist\(dateSuffix()).csv")

        exportWishlistFileURL = url
        isExportingWishlist = false
    }

    private func exportStudents() async {
        isExportingStudents = true

        // Fetch students on-demand (lazy loading)
        let descriptor = FetchDescriptor<Student>()
        
        guard let studentList = try? modelContext.fetch(descriptor) else {
            logger.error("Failed to fetch students for export")
            isExportingStudents = false
            return
        }

        // Export CSV
        let csvContent = CSVExporter.exportStudents(studentList)
        let url = CSVExporter.saveToTemporaryFile(csvContent, filename: "students\(dateSuffix()).csv")

        exportStudentsFileURL = url
        isExportingStudents = false
    }

    private func exportCheckouts() async {
        isExportingCheckouts = true

        // Fetch checkouts on-demand (lazy loading)
        let descriptor = FetchDescriptor<CheckoutRecord>()
        
        guard let checkoutList = try? modelContext.fetch(descriptor) else {
            logger.error("Failed to fetch checkouts for export")
            isExportingCheckouts = false
            return
        }

        // Export CSV
        let csvContent = CSVExporter.exportCheckoutRecords(checkoutList)
        let url = CSVExporter.saveToTemporaryFile(csvContent, filename: "checkouts\(dateSuffix()).csv")

        exportCheckoutsFileURL = url
        isExportingCheckouts = false
    }

    private func deleteAllData() {
        // Fetch and delete all checkout records
        let checkoutDescriptor = FetchDescriptor<CheckoutRecord>()
        if let checkouts = try? modelContext.fetch(checkoutDescriptor) {
            for checkout in checkouts {
                modelContext.delete(checkout)
            }
        }

        // Fetch and delete all books (catalog and wishlist)
        let bookDescriptor = FetchDescriptor<Book>()
        if let books = try? modelContext.fetch(bookDescriptor) {
            for book in books {
                modelContext.delete(book)
            }
        }

        // Fetch and delete all students
        let studentDescriptor = FetchDescriptor<Student>()
        if let students = try? modelContext.fetch(studentDescriptor) {
            for student in students {
                modelContext.delete(student)
            }
        }

        // Reset export URLs
        exportFileURL = nil
        exportWishlistFileURL = nil
        exportStudentsFileURL = nil
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
                let csvContent = try readFileWithEncodingFallback(from: fileURL)
                let importedCount = try CSVImporter.importBooks(from: csvContent, modelContext: modelContext)

                importResult = ImportResult(
                    title: "Import Successful",
                    message: "Successfully imported \(importedCount) book\(importedCount == 1 ? "" : "s") from the CSV file. Cover images will load in the background.",
                    isSuccess: true
                )

                // Start downloading cover images in the background
                Task.detached(priority: .utility) {
                    await self.downloadCoversForImportedBooks()
                }

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
                let csvContent = try readFileWithEncodingFallback(from: fileURL)
                let importedCount = try CSVImporter.importWishlist(from: csvContent, modelContext: modelContext)

                importResult = ImportResult(
                    title: "Import Successful",
                    message: "Successfully imported \(importedCount) book\(importedCount == 1 ? "" : "s") to wishlist from the CSV file.",
                    isSuccess: true
                )

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

    private func handleImportStudentsResult(_ result: Result<[URL], Error>) {
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
                let csvContent = try readFileWithEncodingFallback(from: fileURL)
                let importedCount = try CSVImporter.importStudents(from: csvContent, modelContext: modelContext)

                importResult = ImportResult(
                    title: "Import Successful",
                    message: "Successfully imported \(importedCount) student\(importedCount == 1 ? "" : "s") from the CSV file.",
                    isSuccess: true
                )

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

    private func handleImportCheckoutsResult(_ result: Result<[URL], Error>) {
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
                let csvContent = try readFileWithEncodingFallback(from: fileURL)
                let importedCount = try CSVImporter.importCheckoutRecords(from: csvContent, modelContext: modelContext)

                importResult = ImportResult(
                    title: "Import Successful",
                    message: "Successfully imported \(importedCount) checkout record\(importedCount == 1 ? "" : "s") from the CSV file.",
                    isSuccess: true
                )

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

    // MARK: - Date Suffix for Export Filenames

    private func dateSuffix() -> String {
        let now = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: now)
        let month = calendar.shortMonthSymbols[calendar.component(.month, from: now) - 1]
        let day = calendar.component(.day, from: now)
        return "_\(year)_\(month)_\(day)"
    }

    // MARK: - App Version Info

    private func getAppVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "Unknown"
    }

    private func getAppBuild() -> String {
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return build
        }
        return "Unknown"
    }
    
    /// Download cover images for recently imported books in the background
    private func downloadCoversForImportedBooks() async {
        // Check if device supports background downloads
        guard DeviceCapability.shared.supportsBackgroundDownloads else {
            logger.info("⏭️ Skipping background cover downloads - device does not support rich media")
            return
        }
        
        // Fetch books without cached covers from the current context
        let descriptor = FetchDescriptor<Book>(
            predicate: #Predicate<Book> { book in
                book.cachedCoverImage == nil && !book.isWishlistItem
            }
        )
        
        // Properly handle fetch errors
        guard let booksWithoutCovers = try? modelContext.fetch(descriptor) else {
            logger.error("Failed to fetch books for background cover download")
            return
        }
        
        logger.info("Starting background cover download for \(booksWithoutCovers.count) books")
        
        // Download covers with controlled concurrency
        for book in booksWithoutCovers {
            // Verify book is still valid before processing
            guard !book.isDeleted else {
                logger.warning("Skipping deleted book during cover download")
                continue
            }
            
            await BookAPIService.shared.updateBookCover(book)
            
            // Save periodically to persist downloaded covers with proper error handling
            do {
                try modelContext.save()
            } catch {
                logger.error("Failed to save cover for book '\(book.title)': \(error.localizedDescription)")
            }
        }
        
        logger.info("Finished background cover downloads")
    }
    
    /// Try to read file with multiple text encodings
    /// Attempts UTF-8, then falls back to common encodings
    private func readFileWithEncodingFallback(from url: URL) throws -> String {
        // Try UTF-8 first (most common)
        if let content = try? String(contentsOf: url, encoding: .utf8) {
            return content
        }
        
        // Try Windows-1252 (common for Excel exports)
        if let content = try? String(contentsOf: url, encoding: .windowsCP1252) {
            logger.info("Successfully read file using Windows-1252 encoding")
            return content
        }
        
        // Try ISO Latin 1
        if let content = try? String(contentsOf: url, encoding: .isoLatin1) {
            logger.info("Successfully read file using ISO Latin 1 encoding")
            return content
        }
        
        // Try ASCII
        if let content = try? String(contentsOf: url, encoding: .ascii) {
            logger.info("Successfully read file using ASCII encoding")
            return content
        }
        
        // Try Mac Roman (older Mac files)
        if let content = try? String(contentsOf: url, encoding: .macOSRoman) {
            logger.info("Successfully read file using Mac Roman encoding")
            return content
        }
        
        // If all fail, throw an error
        throw CSVImportError.fileReadError
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
    case students
    case checkouts
}

#Preview {
    AddView()
        .modelContainer(for: [Book.self, Student.self, CheckoutRecord.self])
}
