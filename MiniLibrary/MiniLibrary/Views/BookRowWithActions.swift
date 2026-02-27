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
    
    @State private var showingDetail = false

    var body: some View {
        Button {
            showingDetail = true
        } label: {
            BookRowView(book: book)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete(book)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingDetail) {
            BookDetailView(book: book)
        }
    }
}
