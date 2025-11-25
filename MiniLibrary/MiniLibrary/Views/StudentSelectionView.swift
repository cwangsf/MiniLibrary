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
    @Query(sort: \Student.libraryId) private var allStudents: [Student]

    let onSelect: (Student) -> Void

    @State private var searchText = ""

    var filteredStudents: [Student] {
        if searchText.isEmpty {
            return allStudents
        } else {
            return allStudents.filter { student in
                let parts = student.libraryId.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: false)
                let firstName = parts.count > 0 ? String(parts[0]) : ""
                let lastName = parts.count > 1 ? String(parts[1]) : ""

                return student.libraryId.localizedCaseInsensitiveContains(searchText) ||
                       firstName.localizedCaseInsensitiveContains(searchText) ||
                       lastName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    // Group students by last name initial
    private var groupedStudents: [String: [Student]] {
        let grouped = Dictionary(grouping: filteredStudents) { student in
            let parts = student.libraryId.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: false)
            let lastName = parts.count > 1 ? String(parts[1]) : String(parts[0])
            let initial = lastName.isEmpty ? "#" : String(lastName.prefix(1)).uppercased()
            return initial
        }
        return grouped
    }

    private var sortedSectionTitles: [String] {
        groupedStudents.keys.sorted()
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ZStack(alignment: .trailing) {
                    List {
                        ForEach(sortedSectionTitles, id: \.self) { letter in
                            Section {
                                ForEach(groupedStudents[letter] ?? []) { student in
                                    Button(action: {
                                        onSelect(student)
                                        dismiss()
                                    }) {
                                        HStack {
                                            Text(student.libraryId)
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
                                Text(letter)
                            }
                            .id(letter)
                        }
                    }

                    // Section Index Titles (A-Z) on the right side
                    if !sortedSectionTitles.isEmpty && searchText.isEmpty {
                        SectionIndexTitles(titles: sortedSectionTitles) { letter in
                            withAnimation {
                                proxy.scrollTo(letter, anchor: .top)
                            }
                        }
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
        print("Selected: \(student.libraryId)")
    }
    .modelContainer(for: [Student.self])
}
