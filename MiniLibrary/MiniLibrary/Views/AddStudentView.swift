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

    @State private var libraryId = ""
    @State private var classCode = ""
    @State private var editingStudent: Student?
    @State private var editingName = ""
    @State private var editingCode = ""
    @State private var showingEditSheet = false

    var body: some View {
        Form {
            Section("Student Information") {
                TextField("Student Name (e.g., John Smith)", text: $libraryId)

                TextField("Class Code (optional)", text: $classCode)
            }

            if !students.isEmpty {
                Section("Existing Students") {
                    ForEach(students) { student in
                        Button(action: {
                            editingStudent = student
                            editingName = student.libraryId
                            editingCode = student.classCode ?? ""
                            showingEditSheet = true
                        }) {
                            HStack {
                                Text(student.libraryId)
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
                .background(libraryId.isEmpty ? .gray : .orange)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(libraryId.isEmpty)
            .padding()
            .background(.ultraThinMaterial)
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
                    TextField("Student Name", text: $editingName)
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
                    .disabled(editingName.isEmpty)
                }
            }
        }
    }

    private func addStudent() {
        let student = Student(
            libraryId: libraryId,
            classCode: classCode.isEmpty ? nil : classCode
        )

        modelContext.insert(student)
        dismiss()
    }

    private func saveEditedStudent() {
        guard let student = editingStudent else { return }

        student.libraryId = editingName
        student.classCode = editingCode.isEmpty ? nil : editingCode
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
