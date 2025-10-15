//
//  BookInfoHeaderView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/14/25.
//

import SwiftUI

struct BookInfoHeaderView: View {
    let book: Book

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(book.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(book.author)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let isbn = book.isbn {
                Text("ISBN: \(isbn)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let publisher = book.publisher {
                Text(publisher)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let publishedDate = book.publishedDate {
                Text("Published: \(publishedDate)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    BookInfoHeaderView(book: Book(
        isbn: "9780439708180",
        title: "Harry Potter and the Sorcerer's Stone",
        author: "J.K. Rowling",
        totalCopies: 3,
        publisher: "Scholastic",
        publishedDate: "1998-09-01"
    ))
}
