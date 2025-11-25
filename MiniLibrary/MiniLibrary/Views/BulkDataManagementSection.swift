//
//  BulkDataManagementSection.swift
//  MiniLibrary
//
//  Created by Claude Code
//

import SwiftUI

struct BulkDataManagementSection: View {
    @Binding var isExporting: Bool
    @Binding var exportFileURL: URL?
    @Binding var isExportingWishlist: Bool
    @Binding var exportWishlistFileURL: URL?
    @Binding var isExportingStudents: Bool
    @Binding var exportStudentsFileURL: URL?
    @Binding var showingDeleteConfirmation: Bool
    @Binding var showingImportPicker: Bool
    @Binding var importType: ImportType?

    var onExportCatalog: () -> Void
    var onExportWishlist: () -> Void
    var onExportStudents: () -> Void

    var body: some View {
        Section("Bulk Data Management") {
            // Export Catalog
            HStack {
                ExportCatalogRow(
                    isExporting: isExporting,
                    exportFileURL: exportFileURL,
                    onExport: onExportCatalog
                )
                if isExporting {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            // Export Wishlist
            HStack {
                ExportWishlistRow(
                    isExporting: isExportingWishlist,
                    exportFileURL: exportWishlistFileURL,
                    onExport: onExportWishlist
                )
                if isExportingWishlist {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            // Export Students
            HStack {
                ExportStudentsRow(
                    isExporting: isExportingStudents,
                    exportFileURL: exportStudentsFileURL,
                    onExport: onExportStudents
                )
                if isExportingStudents {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            // Import Catalog
            ImportCatalogRow {
                importType = .catalog
                showingImportPicker = true
            }

            // Import Wishlist
            ImportWishlistRow {
                importType = .wishlist
                showingImportPicker = true
            }

            // Import Students
            ImportStudentsRow {
                importType = .students
                showingImportPicker = true
            }

            // Delete All Data
            Button {
                showingDeleteConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundStyle(.red)
                    Text("Delete All Data")
                        .foregroundStyle(.tint)
                }
            }
        }
    }
}
