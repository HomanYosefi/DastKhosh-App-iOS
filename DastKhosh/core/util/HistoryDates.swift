//
//  HistoryDates.swift
//  DastKhosh
//
//  Created by homan on 1405.07.04.
//

import Foundation

enum HistoryDates {
    private static let monthNames = [
        "فروردین", "اردیبهشت", "خرداد", "تیر",
        "مرداد", "شهریور", "مهر", "آبان",
        "آذر", "دی", "بهمن", "اسفند"
    ]

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .persian)
        calendar.locale = Locale(identifier: "fa_IR")
        calendar.timeZone = .current
        return calendar
    }

    static func date(_ timestamp: Int64) -> Date {
        Date(timeIntervalSince1970: TimeInterval(timestamp) / 1_000)
    }

    static func milliseconds(_ date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 * 1_000).rounded())
    }

    static func startOfDay(_ timestamp: Int64) -> Int64 {
        milliseconds(calendar.startOfDay(for: date(timestamp)))
    }

    static func add(
        _ component: Calendar.Component,
        value: Int,
        to timestamp: Int64
    ) -> Int64 {
        guard let result = calendar.date(
            byAdding: component,
            value: value,
            to: date(timestamp)
        ) else {
            return timestamp
        }

        return milliseconds(result)
    }

    static func addDays(_ timestamp: Int64, _ days: Int) -> Int64 {
        add(.day, value: days, to: timestamp)
    }

    static func monthTitle(_ timestamp: Int64) -> String {
        let parts = calendar.dateComponents(
            [.year, .month],
            from: date(timestamp)
        )

        guard
            let year = parts.year,
            let month = parts.month,
            (1...12).contains(month)
        else {
            return ""
        }

        return "\(monthNames[month - 1]) \(year)".toPersianDigits()
    }

    static func yearTitle(_ timestamp: Int64) -> String {
        let year = calendar.component(.year, from: date(timestamp))
        return "سال \(year)".toPersianDigits()
    }

    static func format(_ timestamp: Int64) -> String {
        let parts = calendar.dateComponents(
            [.year, .month, .day],
            from: date(timestamp)
        )

        let result = String(
            format: "%04d/%02d/%02d",
            locale: Locale(identifier: "en_US_POSIX"),
            parts.year ?? 0,
            parts.month ?? 0,
            parts.day ?? 0
        )

        return result.toPersianDigits()
    }

    static func parse(_ value: String) -> Int64? {
        let normalized = value
            .englishDigits()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "/")
            .replacingOccurrences(
                of: #"\s+"#,
                with: "",
                options: .regularExpression
            )

        let parts = normalized.split(separator: "/", omittingEmptySubsequences: false)

        guard
            parts.count == 3,
            parts[0].count == 4,
            (1...2).contains(parts[1].count),
            (1...2).contains(parts[2].count),
            let year = Int(parts[0]),
            let month = Int(parts[1]),
            let day = Int(parts[2]),
            (1200...1600).contains(year),
            (1...12).contains(month),
            (1...31).contains(day)
        else {
            return nil
        }

        let cal = calendar
        let components = DateComponents(
            calendar: cal,
            timeZone: cal.timeZone,
            year: year,
            month: month,
            day: day,
            hour: 0,
            minute: 0,
            second: 0
        )

        guard let result = cal.date(from: components) else {
            return nil
        }


        let verified = cal.dateComponents(
            [.year, .month, .day],
            from: result
        )

        guard
            verified.year == year,
            verified.month == month,
            verified.day == day
        else {
            return nil
        }

        return milliseconds(cal.startOfDay(for: result))
    }

    static func inclusiveDayCount(
        start: Int64,
        endInclusive: Int64
    ) -> Int {
        let normalizedStart = startOfDay(start)
        let normalizedEnd = startOfDay(endInclusive)

        guard normalizedStart <= normalizedEnd else {
            return 0
        }

        let days = calendar.dateComponents(
            [.day],
            from: date(normalizedStart),
            to: date(normalizedEnd)
        ).day ?? 0

        return days + 1
    }
}

extension String {
    func englishDigits() -> String {
        String(String.UnicodeScalarView(unicodeScalars.map { scalar in
            switch scalar.value {
            case 0x06F0...0x06F9:
                return UnicodeScalar(scalar.value - 0x06F0 + 0x30)!
            case 0x0660...0x0669:
                return UnicodeScalar(scalar.value - 0x0660 + 0x30)!
            default:
                return scalar
            }
        }))
    }

    func toPersianDigits() -> String {
        String(String.UnicodeScalarView(unicodeScalars.map { scalar in
            if (0x30...0x39).contains(scalar.value) {
                return UnicodeScalar(scalar.value - 0x30 + 0x06F0)!
            }
            return scalar
        }))
    }

    func digitsOnly() -> String {
        String(englishDigits().filter { ("0"..."9").contains($0) })
    }

    func toMoneyOrEmpty() -> String {
        let clean = String(digitsOnly().drop(while: { $0 == "0" }))
        return Int64(clean)?.toMoney() ?? ""
    }
}

extension Int64 {
    func toMoney() -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        formatter.secondaryGroupingSize = 3
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0

        let formatted = formatter.string(
            from: NSNumber(value: self)
        ) ?? String(self)

        return formatted.toPersianDigits()
    }

    func toShortToman() -> String {
        let text: String

        switch self {
        case 1_000_000_000...:
            text = "\(Self.decimalPart(self / 100_000_000)) میلیارد تومان"
        case 1_000_000...:
            text = "\(Self.decimalPart(self / 100_000)) میلیون تومان"
        case 1_000...:
            text = "\(self / 1_000) هزار تومان"
        default:
            text = "\(self) تومان"
        }

        return text.toPersianDigits()
    }

    func toPersianDateTime() -> String {
        let parts = HistoryDates.calendar.dateComponents(
            [.hour, .minute],
            from: HistoryDates.date(self)
        )

        let time = String(
            format: "%02d:%02d",
            locale: Locale(identifier: "en_US_POSIX"),
            parts.hour ?? 0,
            parts.minute ?? 0
        )

        return "\(HistoryDates.format(self)) - \(time.toPersianDigits())"
    }

    private static func decimalPart(_ number: Int64) -> String {
        let text = String(number)

        guard text.count > 1, let last = text.last else {
            return text
        }

        let head = String(text.dropLast())
        return last == "0" ? head : "\(head).\(last)"
    }
}

func historyPercentText(_ value: Double) -> String {
    let formatted = String(
        format: "%.1f",
        locale: Locale(identifier: "en_US_POSIX"),
        abs(value)
    )

    return formatted
        .replacingOccurrences(of: #"\.?0+$"#, with: "", options: .regularExpression)
        .toPersianDigits()
}
