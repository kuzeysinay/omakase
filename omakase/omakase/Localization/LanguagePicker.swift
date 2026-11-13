//
//  LanguagePicker.swift
//  omakase
//

import SwiftUI

/// Icon-only globe: language names live inside the menu (avoids cramped “Türkçe” labels in bars).
struct LanguagePicker: View {
    var isSubmenu: Bool = false

    @AppStorage("omakase.language") private var languageCode: String = AppLanguage.english.rawValue
    private var resolved: AppLanguage { AppLanguage(rawValue: languageCode) ?? .english }

    var body: some View {
        Menu {
            ForEach(AppLanguage.allCases) { lang in
                Button {
                    languageCode = lang.rawValue
                } label: {
                    HStack {
                        Text(lang.pickerLabel)
                        Spacer(minLength: 16)
                        if languageCode == lang.rawValue {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            if isSubmenu {
                Label(L10n(lang: resolved).languageMenuAccessibility, systemImage: "globe")
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "globe")
                    Text(L10n(lang: resolved).languageMenuAccessibility)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .menuActionDismissBehavior(.automatic)
        .accessibilityLabel(L10n(lang: resolved).languageMenuAccessibility)
    }
}
