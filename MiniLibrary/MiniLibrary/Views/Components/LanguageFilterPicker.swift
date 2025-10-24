//
//  LanguageFilterPicker.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/24/25.
//

import SwiftUI

enum LanguageFilter: String, CaseIterable {
    case all = "All"
    case english = "English"
    case german = "German"
}

struct LanguageFilterPicker: View {
    @Binding var selectedLanguage: LanguageFilter

    var body: some View {
        Picker("Language", selection: $selectedLanguage) {
            ForEach(LanguageFilter.allCases, id: \.self) { language in
                Text(language.rawValue).tag(language)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 0)
        .padding(.vertical, 8)
        .listRowInsets(EdgeInsets())
    }
}

#Preview {
    @Previewable @State var selectedLanguage: LanguageFilter = .all

    List {
        Section {
            EmptyView()
        } header: {
            LanguageFilterPicker(selectedLanguage: $selectedLanguage)
        }
        .listSectionSeparator(.hidden)

        Section {
            Text("Book 1")
            Text("Book 2")
            Text("Book 3")
        }
    }
}
