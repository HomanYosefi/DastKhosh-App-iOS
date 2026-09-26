//
//  Screen.swift
//  DastKhosh
//
//  Created by homan on 1405.07.02.
//

import SwiftUI

enum Screen: String, CaseIterable, Identifiable {
    case addExpense = "add_expense"
    case history = "history"
    case settings = "settings"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .addExpense: return "ثبت هزینه"
        case .history:    return "تاریخچه"
        case .settings:   return "تنظیمات"
        }
    }

    var iconName: String {
        switch self {
        case .addExpense: return "plus.circle.fill"
        case .history:    return "clock.arrow.circlepath"
        case .settings:   return "gearshape.fill"
        }
    }

    static var items: [Screen] {
        [.addExpense, .history]
    }
}
