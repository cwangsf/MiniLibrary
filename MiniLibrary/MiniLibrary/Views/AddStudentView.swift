//
//  AddStudentView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData

struct AddStudentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var students: [Student]

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var classCode = ""
    @State private var editingStudent: Student?
    @State private var editingFirstName = ""
    @State private var editingLastName = ""
    @State private var editingCode = ""
    @State private var showingEditSheet = false
    @State private var showingDeleteAllConfirmation = false

    var body: some View {
        Form {
            Section("Student Information") {
                TextField("First Name(and Middle name, if any)", text: $firstName)
                TextField("Last Name", text: $lastName)
                TextField("Class Code (optional)", text: $classCode)
            }

            if !students.isEmpty {
                Section("Existing Students") {
                    ForEach(students) { student in
                        Button(action: {
                            editingStudent = student
                            editingFirstName = student.firstName
                            editingLastName = student.lastName
                            editingCode = student.classCode ?? ""
                            showingEditSheet = true
                        }) {
                            HStack {
                                Text(student.fullName)
                                Spacer()
                                if let code = student.classCode {
                                    Text(code)
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                            }
                            .foregroundStyle(.primary)
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
                .background((firstName.isEmpty || lastName.isEmpty) ? .gray : .orange)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(firstName.isEmpty || lastName.isEmpty)
            .padding()
            .background(Color(.systemBackground).opacity(0.95))
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    showingDeleteAllConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .disabled(students.isEmpty)
            }
        }
        .alert("Remove All Students?", isPresented: $showingDeleteAllConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Remove All", role: .destructive) {
                deleteAllStudents()
            }
        } message: {
            Text("This will permanently delete all \(students.count) student\(students.count == 1 ? "" : "s"). This action cannot be undone.")
        }
        .sheet(isPresented: $showingEditSheet) {
            editStudentSheet
        }
    }

    @ViewBuilder
    private var editStudentSheet: some View {
        NavigationStack {
            Form {
                Section("Edit Student") {
                    TextField("First Name", text: $editingFirstName)
                    TextField("Last Name", text: $editingLastName)
                    TextField("Class Code (optional)", text: $editingCode)
                }
            }
            .navigationTitle("Edit Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingEditSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEditedStudent()
                        showingEditSheet = false
                    }
                    .disabled(editingFirstName.isEmpty || editingLastName.isEmpty)
                }
            }
        }
    }

    private func addStudent() {
        let student = Student(
            firstName: firstName,
            lastName: lastName,
            classCode: classCode.isEmpty ? nil : classCode
        )

        modelContext.insert(student)
        dismiss()
    }

    private func saveEditedStudent() {
        guard let student = editingStudent else { return }

        student.firstName = editingFirstName
        student.lastName = editingLastName
        student.classCode = editingCode.isEmpty ? nil : editingCode
    }

    private func deleteAllStudents() {
        for student in students {
            modelContext.delete(student)
        }
    }

    private func deleteStudents(at offsets: IndexSet) {
        for index in offsets {
            let student = students[index]
            modelContext.delete(student)
        }
    }
}

#Preview {
    NavigationStack {
        AddStudentView()
            .modelContainer(for: [Student.self])
    }
}
