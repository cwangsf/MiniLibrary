//
//  BookSearchResultRow.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/23/25.
//

import SwiftUI

// MARK: - Book Search Result Row
struct BookSearchResultRow: View {
    let item: GoogleBookItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Book Cover
            if let thumbnailURL = item.volumeInfo.imageLinks?.thumbnail,
               let url = URL(string: thumbnailURL.replacingOccurrences(of: "http://", with: "https://")) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(.gray.opacity(0.2))
                }
                .frame(width: 40, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Rectangle()
                    .fill(.gray.opacity(0.2))
                    .frame(width: 40, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(
                        Image(systemName: "book.fill")
                            .foregroundStyle(.gray)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.volumeInfo.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let authors = item.volumeInfo.authors {
                    Text(authors.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let publishedDate = item.volumeInfo.publishedDate {
                    Text(publishedDate)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }
}
