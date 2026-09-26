//
//  HistoryState.swift
//  DastKhosh
//
//  Created by homan on 1405.07.04.
//


struct HistoryState {
    var filter: TimeFilter = .monthly
    var filteredExpenses: [Expense] = []
    var chartData: [ChartData] = []
    var totalAmount: Int64 = 0
    var searchQuery = ""
    var customRange: CustomDateRange?
    var summary = FinancialSummary()
    var insights: [String] = []
}
