//
//  FinancialSummary.swift
//  DastKhosh
//
//  Created by homan on 1405.07.04.
//

struct FinancialSummary {
    var currentLabel = ""
    var previousLabel: String?
    var currentAmount: Int64 = 0
    var previousAmount: Int64?
    var changePercent: Double?
    var topCategory: String?
    var topCategoryAmount: Int64 = 0
    var comparisonNote: String?
}
