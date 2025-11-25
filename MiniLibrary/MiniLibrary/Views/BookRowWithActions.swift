//
//  BookRowWithActions.swift
//  MiniLibrary
//
//  Created by Claude Code
//

import SwiftUI

struct BookRowWithActions: View {
    let book: Book
    let onDelete: (Book) -> Void

    var body: some View {
        NavigationLink(destination: BookDetailView(book: book)) {
            BookRowView(book: book)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete(book)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
