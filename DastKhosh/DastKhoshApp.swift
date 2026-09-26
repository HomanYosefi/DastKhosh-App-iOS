//
//  DastKhoshApp.swift
//  DastKhosh
//
//  Created by homan on 1405.07.02.
//

import SwiftUI
import SwiftData

@main
struct DastkhoshApp: App {
    init() {
        DependencyContainer.shared.setupDependencies()
    }

    var body: some Scene {
        WindowGroup {
            DastkhoshAppView()
                .environment(\.layoutDirection, .rightToLeft) 
                .environment(\.locale, Locale(identifier: "fa_IR"))
                .environment(\.font, .custom("Vazirmatn-Medium", size: 16))

        }
    }
}
