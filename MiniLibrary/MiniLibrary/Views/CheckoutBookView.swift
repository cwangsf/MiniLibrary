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
    @Query(sort: \Student.lastName) private var students: [Student]

    @AppStorage("maxBooksPerStudent") private var maxBooksAllowed: Int = 3

    @State private var selectedBook: Book?
    @State private var selectedStudent: Student?
    @State private var dueDate = Date().addingTimeInterval(14 * 24 * 60 * 60) // 2 weeks default
    @State private var showingConfirmation = false
    @State private var showingMaxBooksAlert = false
    @State private var showingAddStudent = false
    @State private var showingStudentSelection = false
    @State private var newStudentFirstName = ""
    @State private var newStudentLastName = ""
    @State private var newStudentClass = ""

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
                    if let student = selectedStudent {
                        HStack {
                            Text(student.fullName)
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                selectedStudent = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.gray)
                            }
                        }
                    } else {
                        Button(action: {
                            showingStudentSelection = true
                        }) {
                            HStack {
                                Image(systemName: "person.text.rectangle")
                                    .foregroundStyle(.blue)
                                Text("Select a Student")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }

                    Button(action: {
                        showingAddStudent = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.orange)
                            Text("Add New Student")
                                .foregroundStyle(.tint)
                        }
                    }
                }

                Section("Due Date") {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    let activeCheckoutCount = selectedStudent?.checkouts?.filter { $0.isActive }.count ?? 0
                    if activeCheckoutCount >= maxBooksAllowed {
                        showingMaxBooksAlert = true
                    } else {
                        showingConfirmation = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Check Out Book")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .disabled(selectedBook == nil || selectedStudent == nil)
                .background((selectedBook == nil || selectedStudent == nil) ? .gray : .blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
                .background(Color(.systemBackground).opacity(0.95))
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
                        },
                        onCancel: {
                            showingConfirmation = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showingStudentSelection) {
                StudentSelectionView { student in
                    selectedStudent = student
                }
            }
            .sheet(isPresented: $showingAddStudent) {
                addStudentSheet
            }
            .alert("Borrowing Limit Reached", isPresented: $showingMaxBooksAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                let studentName = selectedStudent?.fullName ?? "This student"
                Text("\(studentName) already has \(maxBooksAllowed) book\(maxBooksAllowed == 1 ? "" : "s") checked out, which is the maximum allowed. Please ask them to return a book before borrowing another.")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var addStudentSheet: some View {
        NavigationStack {
            Form {
                Section("Student Information") {
                    TextField("First Name", text: $newStudentFirstName)
                    TextField("Last Name", text: $newStudentLastName)
                    TextField("Class Code (optional)", text: $newStudentClass)
                }
            }
            .navigationTitle("Add New Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingAddStudent = false
                        newStudentFirstName = ""
                        newStudentLastName = ""
                        newStudentClass = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addStudent()
                        showingAddStudent = false
                    }
                    .disabled(newStudentFirstName.isEmpty || newStudentLastName.isEmpty)
                }
            }
        }
    }

    private func addStudent() {
        let student = Student.fromFormInput(
            firstName: newStudentFirstName,
            lastName: newStudentLastName,
            classCode: newStudentClass
        )

        modelContext.insert(student)
        selectedStudent = student
        newStudentFirstName = ""
        newStudentLastName = ""
        newStudentClass = ""
    }

    private func checkoutBook() {
        guard let book = selectedBook, let student = selectedStudent else { return }

        let checkout = CheckoutRecord(
            student: student,
            book: book,
            dueDate: dueDate
        )

        book.availableCopies -= 1
        modelContext.insert(checkout)

        dismiss()
        onCheckoutComplete?()
    }
}

#Preview {
    CheckoutBookView()
        .modelContainer(for: [Book.self, Student.self, CheckoutRecord.self])
}
