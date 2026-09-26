//
//  ExpenseInputUseCases.swift
//  DastKhosh
//
//  Created by homan on 1405.07.04.
//

import Foundation

// MARK: - Normalize amount

struct NormalizeExpenseAmountUseCase {
    func execute(_ raw: String) -> String {
        let digits = raw.digitsOnly()

        return String(
            digits
                .drop(while: { $0 == "0" })
                .prefix(12)
        )
    }
}

// MARK: - Add quick amount

struct AddQuickExpenseAmountUseCase {
    private let limit: Int64 = 999_999_999_999

    func execute(current: Int64, adding value: Int64) -> String {
        let current = min(max(current, 0), limit)
        let next: Int64

        if value >= 0 {
            let increment = min(value, limit)

            next = current > limit - increment
                ? limit
                : current + increment
        } else {
            next = current + max(value, -current)
        }

        return next == 0 ? "" : String(next)
    }
}

// MARK: - Normalize description

struct NormalizeExpenseDescriptionUseCase {
    func execute(_ value: String) -> String {
        String(value.prefix(120))
    }
}

// MARK: - Normalize search input

struct NormalizeExpenseSearchQueryUseCase {
    func execute(_ value: String) -> String {
        String(value.prefix(120))
    }
}

// MARK: - Validate form

struct ExpenseFormValidation {
    let amount: Int64
    let description: String
    let amountError: String?
    let descriptionError: String?

    var isValid: Bool {
        amountError == nil && descriptionError == nil
    }
}

struct ValidateExpenseFormUseCase {
    func execute(
        amount: Int64,
        description: String
    ) -> ExpenseFormValidation {
        let trimmedDescription = description
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let amountError: String?

        if amount <= 0 {
            amountError = "مبلغ را وارد کنید"
        } else if amount > 999_999_999_999 {
            amountError = "مبلغ بیش از حد مجاز است"
        } else {
            amountError = nil
        }

        let descriptionError: String?

        if trimmedDescription.isEmpty {
            descriptionError = "توضیحات را وارد کنید"
        } else if trimmedDescription.count > 120 {
            descriptionError = "توضیحات باید حداکثر ۱۲۰ کاراکتر باشد"
        } else {
            descriptionError = nil
        }

        return ExpenseFormValidation(
            amount: amount,
            description: trimmedDescription,
            amountError: amountError,
            descriptionError: descriptionError
        )
    }
}

// MARK: - Validate custom range

struct ValidateCustomExpenseRangeUseCase {
    func execute(
        start: Int64,
        endInclusive: Int64,
        now: Int64
    ) -> CustomDateRange? {
        let normalizedStart = HistoryDates.startOfDay(start)
        let normalizedEnd = HistoryDates.startOfDay(endInclusive)
        let today = HistoryDates.startOfDay(now)

        guard
            normalizedStart <= normalizedEnd,
            normalizedEnd <= today
        else {
            return nil
        }

        return CustomDateRange(
            start: normalizedStart,
            endInclusive: normalizedEnd
        )
    }
}

// MARK: - Select time filter

struct SelectExpenseTimeFilterUseCase {
    func execute(
        requested: TimeFilter,
        customRange: CustomDateRange?
    ) -> TimeFilter? {
        guard requested != .custom || customRange != nil else {
            return nil
        }

        return requested
    }
}
