//
//  BuildExpenseHistoryUseCase.swift
//  DastKhosh
//
//  Created by homan on 1405.07.04.
//

import Foundation

// MARK: - Report models

struct ExpenseChartSlice {
    let label: String
    let amount: Int64
    let percentage: Float
    let isOther: Bool
}

struct ExpenseHistoryReport {
    let filteredExpenses: [Expense]
    let chartSlices: [ExpenseChartSlice]
    let totalAmount: Int64
    let summary: FinancialSummary
    let insights: [String]
}

// MARK: - Chart slices

struct BuildExpenseChartUseCase {
    func execute(
        groups: [String: Int64],
        total: Int64,
        limit: Int = 5
    ) -> [ExpenseChartSlice] {
        guard total > 0, limit > 0 else {
            return []
        }

        let sortedGroups = groups.sorted {
            $0.value == $1.value
                ? $0.key < $1.key
                : $0.value > $1.value
        }

        var slices = sortedGroups.prefix(limit).map { entry in
            ExpenseChartSlice(
                label: entry.key,
                amount: entry.value,
                percentage: Float(
                    Double(entry.value) / Double(total)
                ),
                isOther: false
            )
        }

        let othersTotal = sortedGroups
            .dropFirst(limit)
            .reduce(Int64(0)) {
                $0 + $1.value
            }

        if othersTotal > 0 {
            slices.append(
                ExpenseChartSlice(
                    label: "سایر دسته‌ها",
                    amount: othersTotal,
                    percentage: Float(
                        Double(othersTotal) / Double(total)
                    ),
                    isOther: true
                )
            )
        }

        return slices
    }
}

// MARK: - Financial summary

struct BuildFinancialSummaryUseCase {
    private let calculateChange = CalculateExpenseChangePercentUseCase()

    func execute(
        periods: HistoryPeriods,
        currentTotal: Int64,
        previousTotal: Int64?,
        currentGroups: [String: Int64]
    ) -> FinancialSummary {
        let topCategory = currentGroups
            .sorted {
                $0.value == $1.value
                    ? $0.key < $1.key
                    : $0.value > $1.value
            }
            .first

        return FinancialSummary(
            currentLabel: periods.currentLabel,
            previousLabel: periods.previousLabel,
            currentAmount: currentTotal,
            previousAmount: previousTotal,
            changePercent: calculateChange.execute(
                current: currentTotal,
                previous: previousTotal
            ),
            topCategory: topCategory?.key,
            topCategoryAmount: topCategory?.value ?? 0,
            comparisonNote: periods.comparisonNote
        )
    }
}

// MARK: - Build full report

struct BuildExpenseHistoryUseCase {
    private let buildPeriods = BuildHistoryPeriodsUseCase()
    private let searchExpenses = SearchExpensesUseCase()
    private let filterByWindow = FilterExpensesByWindowUseCase()
    private let calculateTotal = CalculateExpensesTotalUseCase()
    private let groupExpenses = GroupExpensesByCategoryUseCase()
    private let buildChart = BuildExpenseChartUseCase()
    private let buildSummary = BuildFinancialSummaryUseCase()
    private let buildInsights = BuildFinancialInsightsUseCase()

    func execute(
        expenses: [Expense],
        filter: TimeFilter,
        range: CustomDateRange?,
        query: String,
        now: Int64
    ) -> ExpenseHistoryReport {
        let periods = buildPeriods.execute(
            filter: filter,
            range: range,
            now: now
        )

        let matchingExpenses = searchExpenses.execute(
            expenses: expenses,
            query: query,
            now: now
        )

        let current = filterByWindow.execute(
            expenses: matchingExpenses,
            window: periods.current,
            includeAllWhenMissing: true
        )
        .sorted {
            $0.createdAt > $1.createdAt
        }

        let previous = filterByWindow.execute(
            expenses: matchingExpenses,
            window: periods.previous,
            includeAllWhenMissing: false
        )

        let currentTotal = calculateTotal.execute(current)

        let previousTotal: Int64? = periods.previous == nil
            ? nil
            : calculateTotal.execute(previous)

        let currentGroups = groupExpenses.execute(current)
        let previousGroups = groupExpenses.execute(previous)

        let summary = buildSummary.execute(
            periods: periods,
            currentTotal: currentTotal,
            previousTotal: previousTotal,
            currentGroups: currentGroups
        )

        return ExpenseHistoryReport(
            filteredExpenses: current,
            chartSlices: buildChart.execute(
                groups: currentGroups,
                total: currentTotal
            ),
            totalAmount: currentTotal,
            summary: summary,
            insights: buildInsights.execute(
                currentGroups: currentGroups,
                previousGroups: previousGroups,
                summary: summary,
                matchingExpenses: matchingExpenses,
                filter: filter,
                now: now
            )
        )
    }
}
