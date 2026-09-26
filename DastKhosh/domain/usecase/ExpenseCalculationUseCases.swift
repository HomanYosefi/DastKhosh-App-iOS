//
//  ExpenseCalculationUseCases.swift
//  DastKhosh
//
//  Created by homan on 1405.07.04.
//

import Foundation

// MARK: - Total

struct CalculateExpensesTotalUseCase {
    func execute(_ expenses: [Expense]) -> Int64 {
        expenses.reduce(Int64(0)) {
            $0 + $1.amount
        }
    }
}

// MARK: - Frequent descriptions

struct GetTopExpenseDescriptionsUseCase {
    func execute(
        _ expenses: [Expense],
        limit: Int = 5
    ) -> [String] {
        guard limit > 0 else { return [] }

        let descriptions = expenses
            .map {
                $0.description
                    .replacingOccurrences(
                        of: #"\s+"#,
                        with: " ",
                        options: .regularExpression
                    )
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }

        let counts = descriptions.reduce(
            into: [String: Int]()
        ) { result, description in
            result[description, default: 0] += 1
        }

        return counts
            .sorted {
                $0.value == $1.value
                    ? $0.key < $1.key
                    : $0.value > $1.value
            }
            .prefix(limit)
            .map(\.key)
    }
}

// MARK: - Normalize searchable text

struct NormalizeExpenseTextUseCase {
    func execute(_ value: String) -> String {
        value
            .englishDigits()
            .replacingOccurrences(of: "ي", with: "ی")
            .replacingOccurrences(of: "ى", with: "ی")
            .replacingOccurrences(of: "ك", with: "ک")
            .replacingOccurrences(of: "\u{200C}", with: " ")
            .replacingOccurrences(
                of: #"\s+"#,
                with: " ",
                options: .regularExpression
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(with: Locale(identifier: "en_US_POSIX"))
    }
}

// MARK: - Detect category

struct DetectExpenseCategoryUseCase {
    private let normalizeText = NormalizeExpenseTextUseCase()

    // اولین قانون منطبق انتخاب می‌شود.
    private let rules: [(name: String, words: Set<String>)] = [
        ("🚕 حمل‌ونقل", [
            "بنزین", "گازوئیل", "اسنپ", "تپسی", "تاکسی",
            "اتوبوس", "مترو", "کرایه", "پارکینگ"
        ]),
        ("🍔 غذا", [
            "غذا", "رستوران", "ناهار", "نهار", "شام",
            "صبحانه", "پیتزا", "برگر", "ساندویچ",
            "کافه", "قهوه", "نوشابه"
        ]),
        ("🛒 خرید روزمره", [
            "سوپرمارکت", "سوپر", "خواربار", "میوه",
            "سبزی", "گوشت", "مرغ", "نان", "لبنیات"
        ]),
        ("💊 سلامت", [
            "دارو", "داروخانه", "پزشک", "دکتر",
            "درمان", "بیمارستان", "آزمایش", "دندانپزشکی"
        ]),
        ("🏠 خانه و قبوض", [
            "اجاره", "قبض", "شارژ", "برق", "گاز", "اینترنت"
        ]),
        ("👕 پوشاک", [
            "لباس", "کفش", "مانتو", "شلوار", "پیراهن"
        ])
    ]

    func execute(_ description: String) -> String {
        let normalized = normalizeText.execute(description)

        let words = Set(
            normalized
                .replacingOccurrences(
                    of: #"[^\p{L}\p{N}]+"#,
                    with: " ",
                    options: .regularExpression
                )
                .split(whereSeparator: \.isWhitespace)
                .map(String.init)
        )

        for rule in rules {
            if !words.isDisjoint(with: rule.words) {
                return rule.name
            }
        }

        return normalized.isEmpty
            ? "بدون توضیح"
            : normalized
    }
}

// MARK: - Group by category

struct GroupExpensesByCategoryUseCase {
    private let detectCategory = DetectExpenseCategoryUseCase()

    func execute(_ expenses: [Expense]) -> [String: Int64] {
        expenses.reduce(into: [String: Int64]()) { groups, expense in
            let category = detectCategory.execute(expense.description)
            groups[category, default: 0] += expense.amount
        }
    }
}

// MARK: - Search

struct SearchExpensesUseCase {
    private let normalizeText = NormalizeExpenseTextUseCase()

    func execute(
        expenses: [Expense],
        query: String,
        now: Int64
    ) -> [Expense] {
        let normalizedQuery = normalizeText.execute(query)

        return expenses.filter { expense in
            guard expense.createdAt <= now else {
                return false
            }

            return normalizedQuery.isEmpty ||
                normalizeText.execute(expense.description)
                    .contains(normalizedQuery)
        }
    }
}

// MARK: - Filter by window

struct FilterExpensesByWindowUseCase {
    func execute(
        expenses: [Expense],
        window: HistoryWindow?,
        includeAllWhenMissing: Bool
    ) -> [Expense] {
        expenses.filter {
            window?.contains($0.createdAt) ?? includeAllWhenMissing
        }
    }
}

// MARK: - Percentage change

struct CalculateExpenseChangePercentUseCase {
    func execute(
        current: Int64,
        previous: Int64?
    ) -> Double? {
        guard let previous else {
            return nil
        }

        if previous > 0 {
            return (
                (Double(current) - Double(previous)) /
                Double(previous)
            ) * 100
        }

        // رشد از صفر، درصد قابل محاسبه‌ای ندارد.
        return current == 0 ? 0 : nil
    }
}
