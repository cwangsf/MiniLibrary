//
//  SettingsView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 11/4/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("maxBooksPerStudent") private var maxBooksAllowed: Int = 3

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(
                        "Maximum books per student: \(maxBooksAllowed)",
                        value: $maxBooksAllowed,
                        in: 1...20
                    )
                } header: {
                    Text("Borrowing Limits")
                } footer: {
                    Text("Students will not be allowed to check out more than \(maxBooksAllowed) book\(maxBooksAllowed == 1 ? "" : "s") at a time.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SettingsView()
}
