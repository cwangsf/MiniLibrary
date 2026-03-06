//
//  AddBookConfirmationView.swift
//  MiniLibrary
//
//  Created by Claude Code
//

import SwiftUI

struct AddBookConfirmationView: View {
    let title: String
    let author: String
    let isbn: String
    let totalCopies: Int
    let notes: String
    let onConfirm: () -> Void

    var body: some View {
        BaseConfirmationView(
            title: "Confirm New Book",
            confirmButtonText: "Add Book",
            confirmButtonIcon: "checkmark.circle.fill",
            confirmButtonColor: .blue,
            onConfirm: onConfirm
        ) {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Title")
                            .labelStyle()
                        Spacer()
                        Text(title.isEmpty ? "No Title" : title)
                            .valueText()
                    }

                    HStack {
                        Text("Author")
                            .labelStyle()
                        Spacer()
                        Text(author.isEmpty ? "Unknown Author" : author)
                            .valueText()
                    }

                    if !isbn.isEmpty {
                        HStack {
                            Text("ISBN")
                                .labelStyle()
                            Spacer()
                            Text(isbn)
                                .valueText()
                        }
                    }

                    HStack {
                        Text("Copies")
                            .labelStyle()
                        Spacer()
                        Text(String(totalCopies))
                            .valueText()
                    }

                    if !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .labelStyle()
                            Text(notes)
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}
