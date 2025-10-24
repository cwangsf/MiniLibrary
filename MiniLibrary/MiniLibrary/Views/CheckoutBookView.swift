//
//  CheckoutBookView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData

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
        ActivityLogger.logCheckout(book, student: student, dueDate: dueDate, modelContext: modelContext)

        dismiss()
        onCheckoutComplete?()
    }
}

#Preview {
    CheckoutBookView()
        .modelContainer(for: [Book.self, Student.self, CheckoutRecord.self])
}
