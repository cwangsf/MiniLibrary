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

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: ScanBookView()) {
                        Label("Scan Book Barcode", systemImage: "barcode.viewfinder")
                            .foregroundStyle(.blue)
                    }

                    NavigationLink(destination: AddBookView()) {
                        Label("Add New Book Manually", systemImage: "book.fill")
                    }

                    NavigationLink(destination: AddStudentView()) {
                        Label("Add New Student", systemImage: "person.fill")
                    }
                }

                Section {
                    NavigationLink(destination: CheckoutBookView()) {
                        Label("Check Out Book", systemImage: "arrow.right.circle.fill")
                            .foregroundStyle(.blue)
                    }

                    NavigationLink(destination: ReturnBookView()) {
                        Label("Return Book", systemImage: "arrow.left.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                Section("Export") {
                    if isExporting {
                        HStack {
                            Label("Export Catalog to CSV", systemImage: "square.and.arrow.up")
                            Spacer()
                            ProgressView()
                        }
                    } else if let url = exportFileURL {
                        ShareLink(item: url) {
                            Label("Export Catalog to CSV", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        Button {
                            Task {
                                await exportCatalog()
                            }
                        } label: {
                            Label("Export Catalog to CSV", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
            .navigationTitle("Add")
            .task {
                // Pre-generate the export file in background
                await exportCatalog()
            }
        }
    }

    private func exportCatalog() async {
        isExporting = true

        // Capture books array to avoid cross-context issues
        let booksSnapshot = books

        // Run export in background
        let url = await Task.detached {
            let csvContent = CSVExporter.exportBooks(booksSnapshot)
            return CSVExporter.saveToTemporaryFile(csvContent)
        }.value

        await MainActor.run {
            exportFileURL = url
            isExporting = false
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
                        returnBook(checkout)
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
    }

    private func returnBook(_ checkout: CheckoutRecord) {
        checkout.returnDate = Date()
        if let book = checkout.book {
            book.availableCopies += 1
        }
        dismiss()
    }
}

#Preview {
    AddView()
        .modelContainer(for: [Book.self, Student.self, CheckoutRecord.self])
}
