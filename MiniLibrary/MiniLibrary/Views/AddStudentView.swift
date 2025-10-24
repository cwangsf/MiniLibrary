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

#Preview {
    NavigationStack {
        AddStudentView()
            .modelContainer(for: [Student.self])
    }
}
