//
//  AddView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData

struct AddView: View {
    @Query(sort: \Book.title) private var books: [Book]
    @State private var exportFileURL: URL?
    @State private var isExporting = false
    @State private var exportWishlistFileURL: URL?
    @State private var isExportingWishlist = false

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
                }
            }
            .navigationTitle("Add")
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
                    .textInputAutocapitalization(.characters)

                Picker("Grade Level (optional)", selection: $gradeLevel) {
                    Text("Not specified").tag(nil as Int?)
                    ForEach(1...6, id: \.self) { grade in
                        Text("Grade \(grade)").tag(grade as Int?)
                    }
                }
            }

            Section {
                Button("Add Student") {
                    addStudent()
                }
                .disabled(libraryId.isEmpty)
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
                }
            }
        }
        .navigationTitle("Add New Student")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addStudent() {
        let student = Student(
            libraryId: libraryId,
            gradeLevel: gradeLevel
        )

        modelContext.insert(student)
        dismiss()
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
    @State private var isbn = ""
    @State private var searchResults: [GoogleBookItem] = []
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var hasSearched = false

    var body: some View {
        Form {
            Section("Book Information") {
                TextField("ISBN (optional)", text: $isbn)
                    .keyboardType(.numberPad)
                TextField("Title", text: $title)
                TextField("Author (optional)", text: $author)
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
                .disabled(title.isEmpty || isSearching)
            }

            if let error = searchError {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            if !searchResults.isEmpty {
                Section("Search Results") {
                    ForEach(Array(searchResults.enumerated()), id: \.offset) { index, item in
                        Button {
                            addBookFromResult(item)
                        } label: {
                            BookSearchResultRow(item: item)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else if hasSearched && !isSearching {
                Section {
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "magnifyingglass",
                        description: Text("Try searching with different keywords")
                    )
                }
            }
        }
        .navigationTitle("Add to Wishlist")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func searchGoogle() async {
        isSearching = true
        searchError = nil
        hasSearched = false

        do {
            var results: [GoogleBookItem] = []

            // If ISBN is provided, search by ISBN first
            if !isbn.isEmpty {
                do {
                    results = try await searchByISBN(isbn)
                } catch {
                    // ISBN search failed, fall back to title/author search if title is provided
                    print("ISBN search failed, falling back to title/author search: \(error.localizedDescription)")
                    if !title.isEmpty {
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

    private func searchByISBN(_ isbn: String) async throws -> [GoogleBookItem] {
        // Use the existing ISBN search and wrap result in array
        let urlString = "https://www.googleapis.com/books/v1/volumes?q=isbn:\(isbn)"

        guard let url = URL(string: urlString) else {
            throw BookAPIError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let googleResponse = try decoder.decode(GoogleBooksResponse.self, from: data)

        guard let items = googleResponse.items, !items.isEmpty else {
            throw BookAPIError.bookNotFound
        }

        return items
    }

    private func addBookFromResult(_ item: GoogleBookItem) {
        let book = BookAPIService.shared.createBookFromSearchResult(item, isWishlistItem: true)

        modelContext.insert(book)

        // Log activity
        let activity = Activity(
            type: .addWishlist,
            bookTitle: book.title,
            bookAuthor: book.author,
            additionalInfo: nil
        )
        modelContext.insert(activity)

        dismiss()
    }
}

// MARK: - Book Search Result Row
struct BookSearchResultRow: View {
    let item: GoogleBookItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Book Cover
            if let thumbnailURL = item.volumeInfo.imageLinks?.thumbnail,
               let url = URL(string: thumbnailURL.replacingOccurrences(of: "http://", with: "https://")) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(.gray.opacity(0.2))
                }
                .frame(width: 40, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Rectangle()
                    .fill(.gray.opacity(0.2))
                    .frame(width: 40, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(
                        Image(systemName: "book.fill")
                            .foregroundStyle(.gray)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.volumeInfo.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let authors = item.volumeInfo.authors {
                    Text(authors.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let publishedDate = item.volumeInfo.publishedDate {
                    Text(publishedDate)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "plus.circle.fill")
                .foregroundStyle(.pink)
        }
    }
}

#Preview {
    AddView()
        .modelContainer(for: [Book.self, Student.self, CheckoutRecord.self])
}
