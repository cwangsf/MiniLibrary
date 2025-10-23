//
//  BookRowView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import SwiftUI

struct BookRowView: View {
    let book: Book

    var body: some View {
        HStack(spacing: 12) {
            // Book Cover
            BookCoverImage(book: book, width: 60, height: 90)

            // Book Info
            VStack(alignment: .leading, spacing: 6) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    if let isbn = book.isbn {
                        Text("ISBN: \(isbn)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "book.fill")
                            .font(.caption)

                        Text("\(book.availableCopies)/\(book.totalCopies)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(book.availableCopies > 0 ? .green : .red)
                }
                .padding(.trailing)
            }
        }
        .padding(.vertical, 4)
    }
}
