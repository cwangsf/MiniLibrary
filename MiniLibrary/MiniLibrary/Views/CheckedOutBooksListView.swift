//
//  CheckedOutBooksListView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData

enum CheckoutTab {
    case all, overdue, recent
}

struct CheckedOutBooksListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<CheckoutRecord> { $0.returnDate == nil },
           sort: \CheckoutRecord.dueDate)
    private var activeCheckouts: [CheckoutRecord]

    @State private var searchText = ""
    @State private var selectedTab: CheckoutTab = .all
    @State private var selectedClass: String = "All"

    private var overdueCheckouts: [CheckoutRecord] {
        activeCheckouts.filter { $0.isOverdue }
    }

    private var availableClasses: [String] {
        let base = selectedTab == .overdue ? overdueCheckouts : activeCheckouts
        let codes = Set(base.compactMap { $0.student?.classCode }.filter { !$0.isEmpty })
        return ["All"] + codes.sorted()
    }

    // Filter checkouts based on selected tab, class filter, and search text
    private var filteredCheckouts: [CheckoutRecord] {
        let base = selectedTab == .overdue ? overdueCheckouts : activeCheckouts
        let classFiltered = selectedClass == "All" ? base : base.filter { $0.student?.classCode == selectedClass }
        if searchText.isEmpty { return classFiltered }
        return classFiltered.filter { checkout in
            let bookTitle = checkout.book?.title ?? ""
            let studentName = checkout.student?.fullName ?? ""
            return bookTitle.localizedCaseInsensitiveContains(searchText) ||
                   studentName.localizedCaseInsensitiveContains(searchText)
        }
    }

    // Group checkouts by student class
    private var groupedCheckouts: [String: [CheckoutRecord]] {
        var grouped: [String: [CheckoutRecord]] = [:]
        for checkout in filteredCheckouts {
            if let classCode = checkout.student?.classCode, !classCode.isEmpty {
                if grouped[classCode] == nil { grouped[classCode] = [] }
                grouped[classCode]?.append(checkout)
            } else {
                if grouped[""] == nil { grouped[""] = [] }
                grouped[""]?.append(checkout)
            }
        }
        return grouped
    }

    private var sortedSectionTitles: [String] {
        let titles = groupedCheckouts.keys.filter { !$0.isEmpty }.sorted()
        if groupedCheckouts[""] != nil && !(groupedCheckouts[""]?.isEmpty ?? true) {
            return titles + [""]
        }
        return titles
    }

    var body: some View {
        List {
            // Segmented control pinned at top
            Section {
                Picker("", selection: $selectedTab) {
                    Text("All (\(activeCheckouts.count))").tag(CheckoutTab.all)
                    Text("Overdue (\(overdueCheckouts.count))").tag(CheckoutTab.overdue)
                    Text("Recent").tag(CheckoutTab.recent)
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .onChange(of: selectedTab) { selectedClass = "All" }

                if selectedTab != .recent {
                    Menu {
                        ForEach(availableClasses, id: \.self) { classCode in
                            Button(classCode) { selectedClass = classCode }
                        }
                    } label: {
                        HStack {
                            Label(selectedClass == "All" ? "All Classes" : selectedClass,
                                  systemImage: "line.3.horizontal.decrease.circle")
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            }

            if activeCheckouts.isEmpty {
                ContentUnavailableView(
                    "No Checked Out Books",
                    systemImage: "book.closed",
                    description: Text("All books are currently available")
                )
            } else if selectedTab == .overdue && overdueCheckouts.isEmpty {
                ContentUnavailableView(
                    "No Overdue Books",
                    systemImage: "checkmark.seal.fill",
                    description: Text("All checked out books are on time")
                )
            } else if selectedTab == .recent {
                RecentCheckoutsSection()
            } else if filteredCheckouts.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("No checkouts match '\(searchText)'")
                )
            } else {
                ForEach(sortedSectionTitles, id: \.self) { classCode in
                    Section {
                        ForEach(groupedCheckouts[classCode] ?? []) { checkout in
                            if selectedTab == .overdue {
                                OverdueItemRow(checkout: checkout)
                            } else {
                                CheckoutDetailRow(checkout: checkout)
                            }
                        }
                    } header: {
                        Text(classCode.isEmpty ? "No Class" : classCode)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .navigationTitle("Checked Out Books")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search by book or student name")
    }
}

struct CheckoutDetailRow: View {
    let checkout: CheckoutRecord
    @Environment(\.modelContext) private var modelContext
    @State private var checkoutToReturn: CheckoutRecord?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Book Title
            Text(checkout.book?.title ?? "Unknown Book")
                .font(.headline)

            // Student Info
            HStack {
                Image(systemName: "person.fill")
                    .smallIcon(color: .secondary)
                Text(checkout.student?.fullName ?? "Unknown")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Dates Info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Checked Out")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(checkout.checkoutDate, format: .dateTime.month().day().year())
                        .font(.caption)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Due Date")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(checkout.dueDate, format: .dateTime.month().day().year())
                        .font(.caption)
                        .foregroundStyle(checkout.isOverdue ? .red : .primary)
                }
            }

            // Overdue Badge
            if checkout.isOverdue {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("OVERDUE")
                }
                .badge()
            }

            // Return Button
            Button {
                checkoutToReturn = checkout
            } label: {
                HStack {
                    Image(systemName: "arrow.uturn.left.circle.fill")
                    Text("Return Book")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding(.vertical, 8)
        .sheet(item: $checkoutToReturn) { checkout in
            if let book = checkout.book {
                ReturnConfirmationView(
                    book: book,
                    checkout: checkout,
                    onConfirm: {
                        returnBook(checkout)
                        checkoutToReturn = nil
                    }
                )
            }
        }
    }

    private func returnBook(_ checkout: CheckoutRecord) {
        BookManagementService.returnBook(checkout, modelContext: modelContext)
    }
}

struct RecentCheckoutsSection: View {
    @Query(filter: #Predicate<CheckoutRecord> { $0.returnDate == nil },
           sort: \CheckoutRecord.checkoutDate,
           order: .reverse)
    private var recentCheckouts: [CheckoutRecord]

    var body: some View {
        Section {
            ForEach(recentCheckouts) { checkout in
                CheckoutDetailRow(checkout: checkout)
            }
        }
    }
}

struct OverdueItemRow: View {
    let checkout: CheckoutRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(checkout.student?.fullName ?? "Unknown")
                .font(.headline)

            HStack {
                Image(systemName: "book.fill")
                    .smallIcon(color: .secondary)
                Text(checkout.book?.title ?? "Unknown Book")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Checked Out")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(checkout.checkoutDate, format: .dateTime.month().day().year())
                        .font(.caption)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Due Date")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(checkout.dueDate, format: .dateTime.month().day().year())
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        CheckedOutBooksListView()
            .modelContainer(for: [Book.self, Student.self, CheckoutRecord.self])
    }
}
