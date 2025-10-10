//
//  HomeView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var books: [Book]
    @Query private var activeCheckouts: [CheckoutRecord]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Statistics Cards
                    HStack(spacing: 15) {
                        StatCard(
                            title: "Total Books",
                            value: "\(books.count)",
                            icon: "books.vertical.fill",
                            color: .blue
                        )

                        NavigationLink(destination: CheckedOutBooksListView()) {
                            StatCard(
                                title: "Checked Out",
                                value: "\(activeCheckouts.filter { $0.isActive }.count)",
                                icon: "book.fill",
                                color: .orange
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)

                    // Recent Activity Section
                    if !activeCheckouts.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent Checkouts")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(activeCheckouts.filter { $0.isActive }.prefix(5)) { checkout in
                                CheckoutRowView(checkout: checkout)
                            }
                        }
                    } else {
                        ContentUnavailableView(
                            "No Active Checkouts",
                            systemImage: "book.closed",
                            description: Text("Start checking out books to see them here")
                        )
                    }

                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Home")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(color)

                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

struct CheckoutRowView: View {
    let checkout: CheckoutRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(checkout.book?.title ?? "Unknown Book")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("Student: \(checkout.student?.libraryId ?? "Unknown")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Due: \(checkout.dueDate, format: .dateTime.month().day())")
                    .font(.caption)
                    .foregroundStyle(checkout.isOverdue ? .red : .secondary)

                if checkout.isOverdue {
                    Text("OVERDUE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.red)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Book.self, CheckoutRecord.self, Student.self])
}
