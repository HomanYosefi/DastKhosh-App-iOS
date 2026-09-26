//
//  BuildHistoryPeriodsUseCase.swift
//  DastKhosh
//
//  Created by homan on 1405.07.04.
//

import Foundation

struct HistoryWindow {
    let start: Int64
    let endExclusive: Int64

    func contains(_ timestamp: Int64) -> Bool {
        timestamp >= start && timestamp < endExclusive
    }
}

struct HistoryPeriods {
    let current: HistoryWindow?
    let previous: HistoryWindow?
    let currentLabel: String
    let previousLabel: String?
    let comparisonNote: String?

    init(
        current: HistoryWindow?,
        previous: HistoryWindow?,
        currentLabel: String,
        previousLabel: String? = nil,
        comparisonNote: String? = nil
    ) {
        self.current = current
        self.previous = previous
        self.currentLabel = currentLabel
        self.previousLabel = previousLabel
        self.comparisonNote = comparisonNote
    }
}

struct BuildHistoryPeriodsUseCase {
    func execute(
        filter: TimeFilter,
        range: CustomDateRange?,
        now: Int64
    ) -> HistoryPeriods {
        let today = HistoryDates.startOfDay(now)
        let calendar = HistoryDates.calendar

        switch filter {
        case .all:
            return HistoryPeriods(
                current: nil,
                previous: nil,
                currentLabel: "همهٔ هزینه‌ها"
            )

        case .daily:
            return calendarPeriod(
                start: today,
                component: .day,
                step: 1,
                currentLabel: "امروز",
                previousLabel: "دیروز",
                now: now
            )

        case .weekly:
            let weekday = calendar.component(
                .weekday,
                from: HistoryDates.date(today)
            )

            // شنبه = ۷، یکشنبه = ۱
            let daysSinceSaturday = weekday % 7
            let start = HistoryDates.addDays(
                today,
                -daysSinceSaturday
            )

            return calendarPeriod(
                start: start,
                component: .day,
                step: 7,
                currentLabel: "این هفته",
                previousLabel: "هفتهٔ قبل",
                now: now
            )

        case .monthly:
            guard let interval = calendar.dateInterval(
                of: .month,
                for: HistoryDates.date(today)
            ) else {
                return emptyPeriod(label: "این ماه")
            }

            let start = HistoryDates.milliseconds(interval.start)
            let previousStart = HistoryDates.add(
                .month,
                value: -1,
                to: start
            )

            return calendarPeriod(
                start: start,
                component: .month,
                step: 1,
                currentLabel: HistoryDates.monthTitle(start),
                previousLabel: HistoryDates.monthTitle(previousStart),
                now: now
            )

        case .yearly:
            guard let interval = calendar.dateInterval(
                of: .year,
                for: HistoryDates.date(today)
            ) else {
                return emptyPeriod(label: "امسال")
            }

            let start = HistoryDates.milliseconds(interval.start)
            let previousStart = HistoryDates.add(
                .year,
                value: -1,
                to: start
            )

            return calendarPeriod(
                start: start,
                component: .year,
                step: 1,
                currentLabel: HistoryDates.yearTitle(start),
                previousLabel: HistoryDates.yearTitle(previousStart),
                now: now
            )

        case .custom:
            guard let range else {
                return emptyPeriod(label: "بازهٔ دلخواه")
            }

            return customPeriod(range: range, today: today)
        }
    }

    private func calendarPeriod(
        start: Int64,
        component: Calendar.Component,
        step: Int,
        currentLabel: String,
        previousLabel: String,
        now: Int64
    ) -> HistoryPeriods {
        let end = HistoryDates.add(
            component,
            value: step,
            to: start
        )

        let previousStart = HistoryDates.add(
            component,
            value: -step,
            to: start
        )

        return HistoryPeriods(
            current: HistoryWindow(
                start: start,
                endExclusive: end
            ),
            previous: HistoryWindow(
                start: previousStart,
                endExclusive: start
            ),
            currentLabel: currentLabel,
            previousLabel: previousLabel,
            comparisonNote: now < end
                ? "این دوره هنوز کامل نشده؛ مقایسه با کل دورهٔ قبل است."
                : nil
        )
    }

    private func customPeriod(
        range: CustomDateRange,
        today: Int64
    ) -> HistoryPeriods {
        let dayCount = HistoryDates.inclusiveDayCount(
            start: range.start,
            endInclusive: range.endInclusive
        )

        let previousStart = HistoryDates.addDays(
            range.start,
            -dayCount
        )
        let previousEnd = HistoryDates.addDays(range.start, -1)
        let endExclusive = HistoryDates.addDays(range.endInclusive, 1)

        let currentLabel =
            "\(HistoryDates.format(range.start)) تا " +
            HistoryDates.format(range.endInclusive)

        let previousLabel =
            "\(HistoryDates.format(previousStart)) تا " +
            HistoryDates.format(previousEnd)

        let incompleteNote = range.endInclusive == today
            ? " روز پایانی بازه هنوز کامل نشده است."
            : ""

        return HistoryPeriods(
            current: HistoryWindow(
                start: range.start,
                endExclusive: endExclusive
            ),
            previous: HistoryWindow(
                start: previousStart,
                endExclusive: range.start
            ),
            currentLabel: currentLabel,
            previousLabel: previousLabel,
            comparisonNote:
                "مقایسه با بازهٔ \(String(dayCount).toPersianDigits()) روزهٔ " +
                "بلافاصله قبل از بازهٔ انتخابی." +
                incompleteNote
        )
    }

    private func emptyPeriod(label: String) -> HistoryPeriods {
        HistoryPeriods(
            current: HistoryWindow(start: 0, endExclusive: 0),
            previous: nil,
            currentLabel: label
        )
    }
}
