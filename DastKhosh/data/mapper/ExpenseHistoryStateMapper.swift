//
//  ExpenseHistoryStateMapper.swift
//  DastKhosh
//
//  Created by homan on 1405.07.04.
//

import SwiftUI

struct ExpenseHistoryStateMapper {
    private let chartColors: [Color] = [
        Color(red: 16.0 / 255, green: 185.0 / 255, blue: 129.0 / 255),
        Color(red: 14.0 / 255, green: 165.0 / 255, blue: 233.0 / 255),
        Color(red: 245.0 / 255, green: 158.0 / 255, blue: 11.0 / 255),
        Color(red: 244.0 / 255, green: 63.0 / 255, blue: 94.0 / 255),
        Color(red: 20.0 / 255, green: 184.0 / 255, blue: 166.0 / 255)
    ]

    private let otherColor = Color(
        red: 144.0 / 255,
        green: 164.0 / 255,
        blue: 174.0 / 255
    )

    func map(
        report: ExpenseHistoryReport,
        filter: TimeFilter,
        query: String,
        range: CustomDateRange?
    ) -> HistoryState {
        let chartData = report.chartSlices
            .enumerated()
            .map { index, slice in
                ChartData(
                    label: slice.label,
                    amount: slice.amount,
                    percentage: slice.percentage,
                    color: slice.isOther
                        ? otherColor
                        : chartColors[index % chartColors.count]
                )
            }

        return HistoryState(
            filter: filter,
            filteredExpenses: report.filteredExpenses,
            chartData: chartData,
            totalAmount: report.totalAmount,
            searchQuery: query,
            customRange: range,
            summary: report.summary,
            insights: report.insights
        )
    }
}
