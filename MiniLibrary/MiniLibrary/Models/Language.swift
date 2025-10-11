//
//  Language.swift
//  MiniLibrary
//
//  Created by Cynthia Wang on 10/10/25.
//

import Foundation

/// ISO 639-1 language codes
enum Language: String, Codable, CaseIterable {
    case english = "en"
    case chinese = "zh"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case japanese = "ja"
    case korean = "ko"
    case portuguese = "pt"
    case russian = "ru"
    case arabic = "ar"
    case hindi = "hi"
    case dutch = "nl"
    case swedish = "sv"
    case polish = "pl"
    case turkish = "tr"
    case vietnamese = "vi"
    case thai = "th"
    case danish = "da"
    case norwegian = "no"
    case finnish = "fi"
    case greek = "el"
    case czech = "cs"
    case hebrew = "he"
    case indonesian = "id"
    case malay = "ms"
    case romanian = "ro"
    case hungarian = "hu"
    case ukrainian = "uk"

    /// Display name for the language
    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "Chinese"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .german: return "German"
        case .italian: return "Italian"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .portuguese: return "Portuguese"
        case .russian: return "Russian"
        case .arabic: return "Arabic"
        case .hindi: return "Hindi"
        case .dutch: return "Dutch"
        case .swedish: return "Swedish"
        case .polish: return "Polish"
        case .turkish: return "Turkish"
        case .vietnamese: return "Vietnamese"
        case .thai: return "Thai"
        case .danish: return "Danish"
        case .norwegian: return "Norwegian"
        case .finnish: return "Finnish"
        case .greek: return "Greek"
        case .czech: return "Czech"
        case .hebrew: return "Hebrew"
        case .indonesian: return "Indonesian"
        case .malay: return "Malay"
        case .romanian: return "Romanian"
        case .hungarian: return "Hungarian"
        case .ukrainian: return "Ukrainian"
        }
    }

    /// Native name of the language
    var nativeName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .italian: return "Italiano"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .portuguese: return "Português"
        case .russian: return "Русский"
        case .arabic: return "العربية"
        case .hindi: return "हिन्दी"
        case .dutch: return "Nederlands"
        case .swedish: return "Svenska"
        case .polish: return "Polski"
        case .turkish: return "Türkçe"
        case .vietnamese: return "Tiếng Việt"
        case .thai: return "ไทย"
        case .danish: return "Dansk"
        case .norwegian: return "Norsk"
        case .finnish: return "Suomi"
        case .greek: return "Ελληνικά"
        case .czech: return "Čeština"
        case .hebrew: return "עברית"
        case .indonesian: return "Bahasa Indonesia"
        case .malay: return "Bahasa Melayu"
        case .romanian: return "Română"
        case .hungarian: return "Magyar"
        case .ukrainian: return "Українська"
        }
    }

    /// Initialize from language code string (handles variants like "zh-CN")
    init?(code: String) {
        // Handle language codes with region (e.g., "zh-CN", "en-US")
        let baseCode = code.split(separator: "-").first.map(String.init) ?? code
        self.init(rawValue: baseCode.lowercased())
    }
}
