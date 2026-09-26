//
//  TimeFilter.swift
//  DastKhosh
//
//  Created by homan on 1405.07.04.
//

enum TimeFilter: String, CaseIterable {
    case daily = "امروز"
    case weekly = "این هفته"
    case monthly = "این ماه"
    case all = "همه"
    case custom = "سفارشی"
    case yearly = "امسال"

    var title: String { rawValue }
}
