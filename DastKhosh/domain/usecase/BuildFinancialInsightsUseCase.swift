//
//  BuildFinancialInsightsUseCase.swift
//  DastKhosh
//
//  Created by homan on 1405.07.04.
//

import Foundation

struct BuildFinancialInsightsUseCase {
    private let calculateTotal = CalculateExpensesTotalUseCase()

    func execute(
        currentGroups: [String: Int64],
        previousGroups: [String: Int64],
        summary: FinancialSummary,
        matchingExpenses: [Expense],
        filter: TimeFilter,
        now: Int64
    ) -> [String] {
        var insights: [String] = []

        if let category = summary.topCategory,
           summary.currentAmount > 0 {
            let share =
                Double(summary.topCategoryAmount) /
                Double(summary.currentAmount) * 100

            insights.append(
                "بیشترین هزینهٔ ثبت‌شده در این بازه مربوط به «\(category)» بوده؛ " +
                "\(historyPercentText(share))٪ از مجموع هزینه‌ها."
            )
        }

        if summary.previousAmount != nil {
            // در اختلاف مساوی، نام دسته ترتیب را قطعی می‌کند.
            let increasedCategory = currentGroups
                .filter { entry in
                    let oldAmount = previousGroups[entry.key] ?? 0
                    return oldAmount > 0 && entry.value > oldAmount
                }
                .sorted { first, second in
                    let firstDifference =
                        first.value - (previousGroups[first.key] ?? 0)

                    let secondDifference =
                        second.value - (previousGroups[second.key] ?? 0)

                    return firstDifference == secondDifference
                        ? first.key < second.key
                        : firstDifference > secondDifference
                }
                .first

            if let increasedCategory,
               let oldAmount = previousGroups[increasedCategory.key] {
                let percent =
                    (Double(increasedCategory.value) - Double(oldAmount)) /
                    Double(oldAmount) * 100

                insights.append(
                    "هزینهٔ «\(increasedCategory.key)» نسبت به دورهٔ قبل " +
                    "\(historyPercentText(percent))٪ افزایش داشته."
                )
            } else if let percent = summary.changePercent, percent < 0 {
                insights.append(
                    "مجموع هزینه‌های ثبت‌شدهٔ این بازه نسبت به دورهٔ قبل " +
                    "\(historyPercentText(percent))٪ کمتر است."
                )
            }
        }

        if filter == .all,
           let insight = recentAverageInsight(
                expenses: matchingExpenses,
                now: now
           ) {
            insights.append(insight)
        }

        return Array(insights.prefix(3))
    }

    private func recentAverageInsight(
        expenses: [Expense],
        now: Int64
    ) -> String? {
        let today = HistoryDates.startOfDay(now)
        let recentStart = HistoryDates.addDays(today, -7)
        let baselineStart = HistoryDates.addDays(recentStart, -28)

        guard let oldest = expenses.map(\.createdAt).min(),
              oldest <= baselineStart else {
            return nil
        }

        let recentTotal = calculateTotal.execute(
            expenses.filter {
                $0.createdAt >= recentStart &&
                $0.createdAt < today
            }
        )

        let baselineTotal = calculateTotal.execute(
            expenses.filter {
                $0.createdAt >= baselineStart &&
                $0.createdAt < recentStart
            }
        )

        guard baselineTotal > 0 else {
            return nil
        }

        let recentAverage = Double(recentTotal) / 7
        let baselineAverage = Double(baselineTotal) / 28

        let change =
            (recentAverage - baselineAverage) /
            baselineAverage * 100

        guard abs(change) >= 1 else {
            return nil
        }

        let direction = change < 0 ? "کمتر" : "بیشتر"

        return
            "میانگین روزانهٔ هزینه‌های ثبت‌شده در ۷ روز کامل " +
            "گذشته، \(historyPercentText(change))٪ \(direction) " +
            "از میانگین ۲۸ روز قبل از آن بوده."
    }
}
