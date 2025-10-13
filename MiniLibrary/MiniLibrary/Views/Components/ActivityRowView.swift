//
//  ActivityRowView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI

struct ActivityRowView: View {
    let activity: Activity

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: activity.type.icon)
                .font(.title3)
                .foregroundStyle(colorForType(activity.type))
                .frame(width: 32, height: 32)
                .background(colorForType(activity.type).opacity(0.1))
                .clipShape(Circle())

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.type.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                if let bookTitle = activity.bookTitle {
                    Text(bookTitle)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }

                if let bookAuthor = activity.bookAuthor {
                    Text("by \(bookAuthor)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

            Spacer()

            // Timestamp
            VStack(alignment: .trailing, spacing: 2) {
                Text(activity.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(activity.timestamp, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
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
