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
                Section {
                    NavigationLink(destination: ScanBookView()) {
                        HStack {
                            Image(systemName: "barcode.viewfinder")
                                .foregroundStyle(.blue)
                            Text("Scan Book Barcode")
                                .foregroundStyle(.tint)
                        }
                    }

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

                Section {
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
                    if isExporting {
                        HStack {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(.purple)
                                Text("Export Catalog to CSV")
                                    .foregroundStyle(.tint)
                            }
                            Spacer()
                            ProgressView()
                        }
                    } else if let url = exportFileURL {
                        ShareLink(item: url) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(.purple)
                                Text("Export Catalog to CSV")
                                    .foregroundStyle(.tint)
                            }
                        }
                    } else {
                        Button {
                            Task {
                                await exportCatalog()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(.purple)
                                Text("Export Catalog to CSV")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }

                    // Export Wishlist
                    if isExportingWishlist {
                        HStack {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(.purple)
                                Text("Export Wishlist to CSV")
                                    .foregroundStyle(.tint)
                            }
                            Spacer()
                            ProgressView()
                        }
                    } else if let url = exportWishlistFileURL {
                        ShareLink(item: url) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(.purple)
                                Text("Export Wishlist to CSV")
                                    .foregroundStyle(.tint)
                            }
                        }
                    } else {
                        Button {
                            Task {
                                await exportWishlist()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(.purple)
                                Text("Export Wishlist to CSV")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }

                    // Import Catalog
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            importType = .catalog
                            showingImportPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                    .foregroundStyle(.blue)
                                Text("Import Catalog from CSV")
                                    .foregroundStyle(.tint)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("CSV format: ISBN, Title, Author, Total Copies, Available Copies, Language, Publisher, Published Date, Page Count, Notes")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Text("Required: Title, Author, Total Copies, Available Copies. All other fields are optional.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.leading, 28)
                    }

                    // Import Wishlist
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            importType = .wishlist
                            showingImportPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                    .foregroundStyle(.green)
                                Text("Import Wishlist from CSV")
                                    .foregroundStyle(.tint)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("CSV format: Title, Author, ISBN")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Text("Required: Title. Author and ISBN are optional but improve search accuracy.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.leading, 28)
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
                let activity = Activity(
                    type: .addBook,
                    bookTitle: "Import",
                    bookAuthor: "CSV Import",
                    additionalInfo: "\(importedCount) book\(importedCount == 1 ? "" : "s") imported"
                )
                modelContext.insert(activity)

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
                let activity = Activity(
                    type: .addWishlist,
                    bookTitle: "Import",
                    bookAuthor: "CSV Import",
                    additionalInfo: "\(importedCount) book\(importedCount == 1 ? "" : "s") imported"
                )
                modelContext.insert(activity)

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

struct ImportResult {
    let title: String
    let message: String
    let isSuccess: Bool
}

enum ImportType {
    case catalog
    case wishlist
}

// MARK: - Add Book View
struct AddBookView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var author = ""
    @State private var isbn = ""
    @State private var totalCopies = 1
    @State private var notes = ""

    var body: some View {
        Form {
            Section("Book Information") {
                TextField("Title", text: $title)
                TextField("Author", text: $author)
                TextField("ISBN (optional)", text: $isbn)
            }

            Section("Copies") {
                Stepper("Total Copies: \(totalCopies)", value: $totalCopies, in: 1...99)
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            }
        }
        .navigationTitle("Add New Book")
        .navigationBarTitleDisplayMode(.inline)
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
                .background((title.isEmpty || author.isEmpty) ? .gray : .blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(title.isEmpty || author.isEmpty)
            .padding()
            .background(.ultraThinMaterial)
        }
    }

    private func addBook() {
        let book = Book(
            isbn: isbn.isEmpty ? nil : isbn,
            title: title,
            author: author,
            totalCopies: totalCopies,
            availableCopies: totalCopies,
            notes: notes.isEmpty ? nil : notes
        )

        modelContext.insert(book)

        // Log activity
        let activity = Activity(
            type: .addBook,
            bookTitle: book.title,
            bookAuthor: book.author,
            additionalInfo: "\(totalCopies) \(totalCopies == 1 ? "copy" : "copies")"
        )
        modelContext.insert(activity)

        dismiss()
    }
}

// MARK: - Add Student View
struct AddStudentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var students: [Student]

    @State private var libraryId = ""
    @State private var gradeLevel: Int?

    var body: some View {
        Form {
            Section("Student Information") {
                TextField("Library ID (e.g., LIB-001)", text: $libraryId)

                Picker("Grade Level (optional)", selection: $gradeLevel) {
                    Text("Not specified").tag(nil as Int?)
                    ForEach(1...6, id: \.self) { grade in
                        Text("Grade \(grade)").tag(grade as Int?)
                    }
                }
            }

            if !students.isEmpty {
                Section("Existing Students") {
                    ForEach(students) { student in
                        HStack {
                            Text(student.libraryId)
                            Spacer()
                            if let grade = student.gradeLevel {
                                Text("Grade \(grade)")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                    .onDelete(perform: deleteStudents)
                }
            }
        }
        .navigationTitle("Add New Student")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                addStudent()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Student")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(libraryId.isEmpty ? .gray : .orange)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(libraryId.isEmpty)
            .padding()
            .background(.ultraThinMaterial)
        }
    }

    private func addStudent() {
        let student = Student(
            libraryId: libraryId,
            gradeLevel: gradeLevel
        )

        modelContext.insert(student)
        dismiss()
    }

    private func deleteStudents(at offsets: IndexSet) {
        for index in offsets {
            let student = students[index]
            modelContext.delete(student)
        }
    }
}

// MARK: - Checkout Book View
struct CheckoutBookView: View {
    let book: Book?
    var onCheckoutComplete: (() -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Book.title) private var books: [Book]
    @Query(sort: \Student.libraryId) private var students: [Student]

    @State private var selectedBook: Book?
    @State private var selectedStudent: Student?
    @State private var dueDate = Date().addingTimeInterval(14 * 24 * 60 * 60) // 2 weeks default
    @State private var showingConfirmation = false

    var availableBooks: [Book] {
        books.filter { $0.availableCopies > 0 }
    }

    var isBookPreselected: Bool {
        book != nil
    }

    init(book: Book? = nil, onCheckoutComplete: (() -> Void)? = nil) {
        self.book = book
        self.onCheckoutComplete = onCheckoutComplete
        if let book = book {
            _selectedBook = State(initialValue: book)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                if isBookPreselected {
                    Section("Book") {
                        Text(selectedBook?.title ?? "")
                            .font(.headline)
                    }
                } else {
                    Section("Select Book") {
                        Picker("Book", selection: $selectedBook) {
                            Text("Select a book").tag(nil as Book?)
                            ForEach(availableBooks) { book in
                                Text("\(book.title) - \(book.availableCopies) available").tag(book as Book?)
                            }
                        }
                    }
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
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    showingConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Check Out Book")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background((selectedBook == nil || selectedStudent == nil) ? .gray : .blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(selectedBook == nil || selectedStudent == nil)
                .padding()
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Check Out Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isBookPreselected {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingConfirmation) {
                if let book = selectedBook, let student = selectedStudent {
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
        guard let book = selectedBook, let student = selectedStudent else { return }

        let checkout = CheckoutRecord(
            student: student,
            book: book,
            dueDate: dueDate,
            checkedOutByStaffId: "ADMIN" // TODO: Get actual staff ID
        )

        book.availableCopies -= 1
        modelContext.insert(checkout)

        // Log activity
        let activity = Activity(
            type: .checkout,
            bookTitle: book.title,
            bookAuthor: book.author,
            studentLibraryId: student.libraryId,
            additionalInfo: "Due \(dueDate.formatted(date: .abbreviated, time: .omitted))"
        )
        modelContext.insert(activity)

        dismiss()
        onCheckoutComplete?()
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

// MARK: - Return Book View
struct ReturnBookView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var checkouts: [CheckoutRecord]

    @State private var showingReturnConfirmation = false
    @State private var checkoutToReturn: CheckoutRecord?

    var activeCheckouts: [CheckoutRecord] {
        checkouts.filter { $0.isActive }
    }

    var body: some View {
        List {
            if activeCheckouts.isEmpty {
                ContentUnavailableView(
                    "No Active Checkouts",
                    systemImage: "book.closed",
                    description: Text("There are no books currently checked out")
                )
            } else {
                ForEach(activeCheckouts) { checkout in
                    Button {
                        checkoutToReturn = checkout
                        showingReturnConfirmation = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(checkout.book?.title ?? "Unknown")
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text("Student: \(checkout.student?.libraryId ?? "Unknown")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "arrow.uturn.left.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
        }
        .navigationTitle("Return Book")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingReturnConfirmation) {
            if let checkout = checkoutToReturn, let book = checkout.book {
                ReturnConfirmationView(
                    book: book,
                    checkout: checkout,
                    onConfirm: {
                        returnBook(checkout)
                    }
                )
            }
        }
    }

    private func returnBook(_ checkout: CheckoutRecord) {
        checkout.returnDate = Date()
        if let book = checkout.book {
            book.availableCopies += 1

            // Log activity
            let activity = Activity(
                type: .return,
                bookTitle: book.title,
                bookAuthor: book.author,
                studentLibraryId: checkout.student?.libraryId,
                additionalInfo: nil
            )
            modelContext.insert(activity)
        }
        dismiss()
    }
}

// MARK: - Add Wishlist Item View
struct AddWishlistItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var author = ""
    @State private var publisher = ""
    @State private var isbn = ""
    @State private var searchResults: [GoogleBookItem] = []
    @State private var selectedItems: Set<Int> = [] // Track selected items by index
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var hasSearched = false
    @State private var showManualAddConfirmation = false

    var canSearch: Bool {
        !isbn.isEmpty || !title.isEmpty || !author.isEmpty || !publisher.isEmpty
    }

    var body: some View {
        Form {
            Section("Book Information") {
                TextField("ISBN (optional)", text: $isbn)
                    .keyboardType(.numberPad)
                TextField("Title (optional)", text: $title)
                TextField("Author (optional)", text: $author)
                TextField("Publisher (optional)", text: $publisher)
            }

            Section {
                Button {
                    Task {
                        await searchGoogle()
                    }
                } label: {
                    HStack {
                        if isSearching {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Image(systemName: "magnifyingglass")
                        Text(isSearching ? "Searching..." : "Search Google Books")
                    }
                }
                .disabled(!canSearch || isSearching)

                Button {
                    showManualAddConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add to Wishlist Manually")
                    }
                }
                .disabled(!canSearch)
            } footer: {
                Text("Search Google Books to get complete information, or add manually with the details you have.")
                    .font(.caption)
            }

            if let error = searchError {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            if !searchResults.isEmpty {
                Section {
                    ForEach(Array(searchResults.enumerated()), id: \.offset) { index, item in
                        Button {
                            toggleSelection(index)
                        } label: {
                            HStack {
                                BookSearchResultRow(item: item)

                                Spacer()

                                // Checkmark for selected items
                                if selectedItems.contains(index) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                        .font(.title3)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.gray)
                                        .font(.title3)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    HStack {
                        Text("Search Results - Select Books")
                        Spacer()
                        if !selectedItems.isEmpty {
                            Text("\(selectedItems.count) selected")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else if hasSearched && !isSearching {
                Section {
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "magnifyingglass",
                        description: Text("Try searching with different keywords or add manually")
                    )
                }
            }
        }
        .navigationTitle("Add to Wishlist")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Add to Wishlist?", isPresented: $showManualAddConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Add") {
                addManually()
            }
        } message: {
            let parts = [
                title.isEmpty ? nil : "Title: \(title)",
                author.isEmpty ? nil : "Author: \(author)",
                publisher.isEmpty ? nil : "Publisher: \(publisher)",
                isbn.isEmpty ? nil : "ISBN: \(isbn)"
            ].compactMap { $0 }

            let message = parts.isEmpty ? "Add this book to your wishlist?" : parts.joined(separator: "\n")
            return Text(message)
        }
        .safeAreaInset(edge: .bottom) {
            if !selectedItems.isEmpty {
                Button {
                    addSelectedBooks()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add \(selectedItems.count) Book\(selectedItems.count == 1 ? "" : "s") to Wishlist")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }

    private func toggleSelection(_ index: Int) {
        if selectedItems.contains(index) {
            selectedItems.remove(index)
        } else {
            selectedItems.insert(index)
        }
    }

    private func addSelectedBooks() {
        var addedCount = 0

        for index in selectedItems.sorted() {
            guard index < searchResults.count else { continue }
            let item = searchResults[index]
            let book = BookAPIService.shared.createBookFromSearchResult(item, isWishlistItem: true)
            modelContext.insert(book)
            addedCount += 1
        }

        // Log activity
        let activity = Activity(
            type: .addWishlist,
            bookTitle: "Bulk Add",
            bookAuthor: "Google Books Search",
            additionalInfo: "\(addedCount) book\(addedCount == 1 ? "" : "s") added"
        )
        modelContext.insert(activity)

        dismiss()
    }

    private func searchGoogle() async {
        isSearching = true
        searchError = nil
        hasSearched = false
        selectedItems.removeAll() // Clear previous selections

        do {
            var results: [GoogleBookItem] = []

            // If ISBN is provided, search by ISBN first
            if !isbn.isEmpty {
                do {
                    results = try await BookAPIService.shared.searchBooksByISBN(isbn)
                } catch {
                    // ISBN search failed, fall back to title/author search if title is provided
                    print("ISBN search failed, falling back to title/author search: \(error.localizedDescription)")
                    if !title.isEmpty || !author.isEmpty {
                        results = try await BookAPIService.shared.searchBooksByTitleAndAuthor(
                            title: title,
                            author: author
                        )
                    } else {
                        throw error
                    }
                }
            } else {
                // No ISBN, search by title and author
                results = try await BookAPIService.shared.searchBooksByTitleAndAuthor(
                    title: title,
                    author: author
                )
            }

            searchResults = results
            hasSearched = true
        } catch {
            searchError = error.localizedDescription
            searchResults = []
        }

        isSearching = false
    }

    private func addManually() {
        // Use provided info or defaults
        let bookTitle = title.isEmpty ? "Untitled Book" : title
        let bookAuthor = author.isEmpty ? "Unknown Author" : author
        let bookISBN = isbn.isEmpty ? nil : isbn
        let bookPublisher = publisher.isEmpty ? nil : publisher

        let book = Book(
            isbn: bookISBN,
            title: bookTitle,
            author: bookAuthor,
            totalCopies: 0,
            availableCopies: 0,
            publisher: bookPublisher,
            isWishlistItem: true
        )

        modelContext.insert(book)

        // Log activity
        let activity = Activity(
            type: .addWishlist,
            bookTitle: book.title,
            bookAuthor: book.author,
            additionalInfo: "Added manually"
        )
        modelContext.insert(activity)

        dismiss()
    }
}


#Preview {
    AddView()
        .modelContainer(for: [Book.self, Student.self, CheckoutRecord.self])
}
