//
//  ProfileTabView.swift
//  omakase
//
//  Dedicated Profile tab hosted in the bottom TabBar.
//

import SwiftUI

struct ProfileTabView: View {

    let authService: AuthService

    var body: some View {
        MyProfileSheet(authService: authService, isTab: true)
    }
}
