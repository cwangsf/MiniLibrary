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
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Confirm New Book")
                        .sectionTitle()
                        .padding(.top, 20)

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
                    .padding(.horizontal)

                    // Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            onConfirm()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Add Book")
                            }
                            .prominentButton(color: .blue)
                        }

                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                                .secondaryButton()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}
