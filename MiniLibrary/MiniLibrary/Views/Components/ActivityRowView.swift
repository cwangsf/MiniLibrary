//
//  ActivityRowView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI

struct ActivityRowView: View {
    let activity: Activity
    let iconSize: CGFloat = 24

    var body: some View {
        HStack(alignment: .top) {
            // Icon
            Image(systemName: activity.type.icon)
                .font(.title3)
                .foregroundStyle(colorForType(activity.type))
                .frame(width: iconSize, height: iconSize)
                .background(colorForType(activity.type).opacity(0.1))
                .clipShape(Circle())

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.type.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                // Timestamp
                HStack(alignment: .top, spacing: 2) {
                    Text(activity.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(activity.timestamp, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if let bookTitle = activity.bookTitle {
                    Text(bookTitle)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }

                HStack(spacing: 8) {
                    if let studentId = activity.studentLibraryId {
                        Label(studentId, systemImage: "person.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let info = activity.additionalInfo {
                        Text(info)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func colorForType(_ type: ActivityType) -> Color {
        switch type {
        case .checkout:
            return .blue
        case .return:
            return .green
        case .addBook:
            return .purple
        case .addWishlist:
            return .pink
        case .fulfillWishlist:
            return .green
        }
    }
}

#Preview {
    let sampleCheckoutActivity = Activity(
        type: .checkout,
        timestamp: Date(),
        bookTitle: "The Swift Programming Language",
        bookAuthor: "Apple Inc.",
        studentLibraryId: "John Doe",
        additionalInfo: "Due: Dec 24, 2025"
    )

    let sampleReturnActivity = Activity(
        type: .return,
        timestamp: Date().addingTimeInterval(-3600),
        bookTitle: "SwiftUI Essentials",
        bookAuthor: "Mark Moeykens",
        studentLibraryId: "Jane Smith",
        additionalInfo: nil,
    )

    let sampleAddBookActivity = Activity(
        type: .addBook,
        timestamp: Date().addingTimeInterval(-7200),
        bookTitle: "Combine: Asynchronous Programming with Swift",
        bookAuthor: "Shai Mishali",
        studentLibraryId: nil,
        additionalInfo: "1 copy added",
    )

    VStack(spacing: 12) {
        ActivityRowView(activity: sampleCheckoutActivity)
        ActivityRowView(activity: sampleReturnActivity)
        ActivityRowView(activity: sampleAddBookActivity)
    }
    .padding()
    .background(Color(.systemGray6))
}
