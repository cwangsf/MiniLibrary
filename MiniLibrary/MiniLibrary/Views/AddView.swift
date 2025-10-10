//
//  AddView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData

struct AddView: View {
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
            }
            .navigationTitle("Add")
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

            Section {
                Button("Add Book") {
                    addBook()
                }
                .disabled(title.isEmpty || author.isEmpty)
            }
        }
        .navigationTitle("Add New Book")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addBook() {
        let book = Book(
            isbn: isbn.isEmpty ? nil : isbn,
            title: title,
            author: author,
            totalCopies: totalCopies,
            availableCopies: totalCopies
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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Book.title) private var books: [Book]
    @Query(sort: \Student.libraryId) private var students: [Student]

    @State private var selectedBook: Book?
    @State private var selectedStudent: Student?
    @State private var dueDate = Date().addingTimeInterval(14 * 24 * 60 * 60) // 2 weeks default
    @State private var staffId = "ADMIN" // Placeholder

    var availableBooks: [Book] {
        books.filter { $0.availableCopies > 0 }
    }

    var body: some View {
        Form {
            Section("Select Student") {
                Picker("Student", selection: $selectedStudent) {
                    Text("Select a student").tag(nil as Student?)
                    ForEach(students) { student in
                        Text(student.libraryId).tag(student as Student?)
                    }
                }
            }

            Section("Select Book") {
                Picker("Book", selection: $selectedBook) {
                    Text("Select a book").tag(nil as Book?)
                    ForEach(availableBooks) { book in
                        Text("\(book.title) - \(book.availableCopies) available").tag(book as Book?)
                    }
                }
            }

            Section("Due Date") {
                DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
            }

            Section {
                Button("Check Out") {
                    checkoutBook()
                }
                .disabled(selectedBook == nil || selectedStudent == nil)
            }
        }
        .navigationTitle("Check Out Book")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func checkoutBook() {
        guard let book = selectedBook, let student = selectedStudent else { return }

        let checkout = CheckoutRecord(
            student: student,
            book: book,
            dueDate: dueDate,
            checkedOutByStaffId: staffId
        )

        book.availableCopies -= 1
        modelContext.insert(checkout)
        dismiss()
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
