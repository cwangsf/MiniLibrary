//
//  WishlistItemView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/23/25.
//
import SwiftUI

struct WishlistItemView: View {
    let book: Book
    @Binding var shareItem: ShareItem?
    
    var body: some View {
        // Main content - tapping opens Amazon
        HStack {
            Button {
                if let url = generateAmazonURL(for: book) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 12) {
                    // Book Cover Image
                    BookCoverImage(book: book, width: 60, height: 90)
                    
                    // Book Info
                    VStack(alignment: .leading, spacing: 6) {
                        Text(book.title)
                            .font(.headline)
                            .lineLimit(2)
                            .foregroundStyle(.primary)
                        
                        Text(book.author)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        if let notes = book.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                }
            }
            
            // Share button
            Button {
                if let url = generateAmazonURL(for: book) {
                    shareItem = ShareItem(
                        title: book.title,
                        author: book.author,
                        url: url
                    )
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(.blue)
                    .font(.title2)
                    .padding(.leading, 8)
            }
            .buttonStyle(.plain)
        }
    }
    
    private func generateAmazonURL(for book: Book) -> URL? {
        if let isbn = book.isbn {
            return URL(string: "https://www.amazon.com/s?k=\(isbn)")
        } else {
            let query = "\(book.title) \(book.author)"
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return URL(string: "https://www.amazon.com/s?k=\(query)")
        }
    }
}
