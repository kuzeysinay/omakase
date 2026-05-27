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
                Image(systemName: "globe")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.primary.opacity(0.85))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
        }
        .menuActionDismissBehavior(.automatic)
        .accessibilityLabel(L10n(lang: resolved).languageMenuAccessibility)
    }
}
