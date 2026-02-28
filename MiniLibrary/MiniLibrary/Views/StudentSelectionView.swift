//
//  StudentSelectionView.swift
//  MiniLibrary
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct StudentSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Student.lastName) private var allStudents: [Student]

    let onSelect: (Student) -> Void

    @State private var searchText = ""

    var filteredStudents: [Student] {
        if searchText.isEmpty {
            return allStudents
        } else {
            return allStudents.filter { student in
                return student.fullName.localizedCaseInsensitiveContains(searchText) ||
                       student.firstName.localizedCaseInsensitiveContains(searchText) ||
                       student.lastName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    // Group students by class code (with students without class at the end)
    private var groupedStudents: [String: [Student]] {
        var grouped: [String: [Student]] = [:]

        for student in filteredStudents {
            if let classCode = student.classCode, !classCode.isEmpty {
                if grouped[classCode] == nil {
                    grouped[classCode] = []
                }
                grouped[classCode]?.append(student)
            } else {
                // Group students without class code under "No Class"
                if grouped[""] == nil {
                    grouped[""] = []
                }
                grouped[""]?.append(student)
            }
        }

        return grouped
    }

    private var sortedSectionTitles: [String] {
        let titles = groupedStudents.keys.filter { !$0.isEmpty }.sorted()
        // Add "No Class" at the end if there are students without a class
        if groupedStudents[""] != nil && !(groupedStudents[""]?.isEmpty ?? true) {
            return titles + [""]
        }
        return titles
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedSectionTitles, id: \.self) { letter in
                    Section {
                        ForEach(groupedStudents[letter] ?? []) { student in
                            Button(action: {
                                onSelect(student)
                                dismiss()
                            }) {
                                HStack {
                                    Text(student.fullName)
                                        .foregroundStyle(.primary)
                                    if let classCode = student.classCode {
                                        Spacer()
                                        Text(classCode)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text(letter.isEmpty ? "No Class" : letter)
                    }
                }
            }
            .navigationTitle("Select Student")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search by name")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    StudentSelectionView { student in
        print("Selected: \(student.fullName)")
    }
    .modelContainer(for: [Student.self])
}
