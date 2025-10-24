//
//  ExportImportRows.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/24/25.
//

import SwiftUI

// MARK: - Export Catalog Row
struct ExportCatalogRow: View {
    let isExporting: Bool
    let exportFileURL: URL?
    let onExport: () -> Void

    var body: some View {
        if isExporting {
            HStack {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.purple)
                    Text("Export Catalog to CSV")
                        .foregroundStyle(.tint)
                }
                Spacer()
                ProgressView()
            }
        } else if let url = exportFileURL {
            ShareLink(item: url) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.purple)
                    Text("Export Catalog to CSV")
                        .foregroundStyle(.tint)
                }
            }
        } else {
            Button(action: onExport) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.purple)
                    Text("Export Catalog to CSV")
                        .foregroundStyle(.tint)
                }
            }
        }
    }
}

// MARK: - Export Wishlist Row
struct ExportWishlistRow: View {
    let isExporting: Bool
    let exportFileURL: URL?
    let onExport: () -> Void

    var body: some View {
        if isExporting {
            HStack {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.purple)
                    Text("Export Wishlist to CSV")
                        .foregroundStyle(.tint)
                }
                Spacer()
                ProgressView()
            }
        } else if let url = exportFileURL {
            ShareLink(item: url) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.purple)
                    Text("Export Wishlist to CSV")
                        .foregroundStyle(.tint)
                }
            }
        } else {
            Button(action: onExport) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.purple)
                    Text("Export Wishlist to CSV")
                        .foregroundStyle(.tint)
                }
            }
        }
    }
}

// MARK: - Import Catalog Row
struct ImportCatalogRow: View {
    let onImport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onImport) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundStyle(.blue)
                    Text("Import Catalog from CSV")
                        .foregroundStyle(.tint)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("CSV format: ISBN, Title, Author, Total Copies, Available Copies, Language, Publisher, Published Date, Page Count, Notes")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text("Required: Title, Author, Total Copies, Available Copies. All other fields are optional.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 28)
        }
    }
}

// MARK: - Import Wishlist Row
struct ImportWishlistRow: View {
    let onImport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onImport) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundStyle(.green)
                    Text("Import Wishlist from CSV")
                        .foregroundStyle(.tint)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("CSV format: Title, Author, ISBN")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text("Required: Title. Author and ISBN are optional but improve search accuracy.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 28)
        }
    }
}
