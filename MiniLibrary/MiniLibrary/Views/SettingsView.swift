//
//  SettingsView.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 11/4/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("maxBooksPerStudent") private var maxBooksAllowed: Int = 3
    @AppStorage("defaultLoanPeriodDays") private var defaultLoanPeriodDays: Int = 14

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

                Section {
                    Stepper(
                        "Default loan period: \(defaultLoanPeriodDays) day\(defaultLoanPeriodDays == 1 ? "" : "s")",
                        value: $defaultLoanPeriodDays,
                        in: 1...365
                    )
                } header: {
                    Text("Loan Period")
                } footer: {
                    Text("The due date will default to \(defaultLoanPeriodDays) day\(defaultLoanPeriodDays == 1 ? "" : "s") from today when checking out a book.")
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
