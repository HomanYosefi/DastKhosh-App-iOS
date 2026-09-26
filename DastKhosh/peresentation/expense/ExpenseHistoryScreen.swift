//
//  ExpenseHistoryScreen.swift
//  DastKhosh
//
//  Created by homan on 1405.07.02.
//



import SwiftUI
import UIKit

private typealias HistoryColors = AppTheme

struct ExpenseHistoryScreen: View {
    @ObservedObject var viewModel: ExpenseViewModel

    let onNavigateToSettings: () -> Void

    @State private var expenseToDelete: Expense?
    @State private var showDeleteAlert = false
    @State private var showCustomRange = false

    private var state: HistoryState {
        viewModel.historyState
    }

    var body: some View {
        VStack(spacing: 0) {
            HistoryHeader(
                count: state.filteredExpenses.count,
                total: state.totalAmount,
                onSettingsClick: onNavigateToSettings
            )

            List {
                HistorySearchField(
                    text: Binding(
                        get: { viewModel.historyState.searchQuery },
                        set: { viewModel.onSearchQueryChange($0) }
                    )
                )
                .historyListRow()

                HistoryFilterRow(
                    currentFilter: state.filter,
                    onSelect: { filter in
                        if filter == .custom {
                            showCustomRange = true
                        } else {
                            viewModel.setTimeFilter(filter)
                        }
                    }
                )
                .historyListRow()

                if state.filter == .custom,
                   let range = state.customRange {
                    customRangeButton(range)
                        .historyListRow()
                }

                HistorySummaryCard(summary: state.summary)
                    .historyListRow()

                if !state.insights.isEmpty {
                    HistoryInsightsCard(insights: state.insights)
                        .historyListRow()
                }

                if !state.filteredExpenses.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Label(
                            "دسته‌بندی هزینه‌ها",
                            systemImage: "chart.pie.fill"
                        )
                        .font(.headline)
                        .foregroundStyle(HistoryColors.onSurface)

                        SmartExpenseChart(
                            timeFilter: state.filter,
                            chartData: state.chartData,
                            totalAmount: state.totalAmount
                        )
                    }
                    .historyCard()
                    .historyListRow()

                    HStack {
                        Text("ریز هزینه‌ها")
                            .font(.headline)
                            .foregroundStyle(HistoryColors.onSurface)

                        Spacer()

                        Text(
                            "\(state.filteredExpenses.count) مورد"
                                .toPersianDigits()
                        )
                        .font(.caption)
                        .foregroundStyle(
                            HistoryColors.onSurfaceVariant
                        )
                    }
                    .padding(.top, 8)
                    .historyListRow()

                    ForEach(state.filteredExpenses, id: \.id) { expense in
                        HistoryExpenseCard(
                            expense: expense,
                            onDelete: {
                                requestDelete(expense)
                            }
                        )
                        .historyListRow()
                        .swipeActions(
                            edge: .trailing,
                            allowsFullSwipe: false
                        ) {
                            swipeDeleteButton(expense)
                        }
                        .swipeActions(
                            edge: .leading,
                            allowsFullSwipe: false
                        ) {
                            swipeDeleteButton(expense)
                        }
                    }
                } else {
                    HistoryEmptyState(
                        isSearching: !state.searchQuery
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty
                    )
                    .historyListRow()
                }

                Color.clear
                    .frame(height: 100)
                    .historyListRow()
                    .accessibilityHidden(true)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .environment(\.defaultMinListRowHeight, 0)
        }
        .background(
            HistoryColors.background
                .ignoresSafeArea()
        )
        .tint(HistoryColors.primary)
        .environment(\.layoutDirection, .rightToLeft)
        .alert(
            "حذف هزینه",
            isPresented: $showDeleteAlert,
            presenting: expenseToDelete
        ) { expense in
            Button("حذف کن", role: .destructive) {
                viewModel.deleteExpense(expense)
                expenseToDelete = nil
            }

            Button("انصراف", role: .cancel) {
                expenseToDelete = nil
            }
        } message: { expense in
            Text(
                "هزینهٔ «\(expense.description)» به مبلغ " +
                "\(expense.amount.toMoney()) تومان حذف شود؟"
            )
        }
        .sheet(isPresented: $showCustomRange) {
            HistoryCustomRangeSheet(
                existingRange: state.customRange,
                onApply: { start, end in
                    viewModel.setCustomRange(
                        start: start,
                        endInclusive: end
                    )
                }
            )
        }
    }

    private func requestDelete(_ expense: Expense) {
        expenseToDelete = expense
        showDeleteAlert = true
    }

    private func swipeDeleteButton(
        _ expense: Expense
    ) -> some View {
        Button {
            requestDelete(expense)
        } label: {
            Label("حذف", systemImage: "trash")
        }
        .tint(.red)
    }

    private func customRangeButton(
        _ range: CustomDateRange
    ) -> some View {
        Button {
            showCustomRange = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "calendar")

                Text(
                    "\(historyDateLabel(range.start)) تا " +
                    historyDateLabel(range.endInclusive)
                )
                .font(.subheadline)
                .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                Image(systemName: "pencil")
            }
            .foregroundStyle(HistoryColors.primary)
            .padding(14)
            .background(
                HistoryColors.primaryContainer,
                in: RoundedRectangle(cornerRadius: 16)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Header

private struct HistoryHeader: View {
    let count: Int
    let total: Int64
    let onSettingsClick: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("گزارش مالی")
                        .font(.system(size: 24, weight: .bold))
                }

                Spacer(minLength: 0)

                Button(action: onSettingsClick) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 19))
                        .frame(width: 44, height: 44)
                        .background(
                            .white.opacity(0.13),
                            in: Circle()
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("تنظیمات")
            }

            HStack(spacing: 12) {
                HistoryStatPill(
                    title: "تعداد هزینه",
                    value: "\(count) مورد".toPersianDigits(),
                    icon: "receipt"
                )

                HistoryStatPill(
                    title: "مجموع بازه",
                    value: "\(total.toMoney()) تومان",
                    icon: "creditcard.fill"
                )
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .background {
            HistoryColors.brandGradient
                .clipShape(HistoryBottomCorners(radius: 30))
                .ignoresSafeArea(edges: .top)
        }
    }
}

private struct HistoryStatPill: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            .white.opacity(0.10),
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        }
    }
}

// MARK: - Search

private struct HistorySearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(HistoryColors.primary)

            TextField("جستجو هزینه‌ها...", text: $text)
                .font(.subheadline)
                .foregroundStyle(HistoryColors.onSurface)
                .submitLabel(.search)
                .autocorrectionDisabled()

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(
                            HistoryColors.onSurfaceVariant
                        )
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("پاک کردن جستجو")
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 52)
        .background(
            HistoryColors.surface,
            in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(HistoryColors.outline, lineWidth: 1)
        }
        .padding(.top, 10)
    }
}

// MARK: - Filters

private struct HistoryFilterRow: View {
    let currentFilter: TimeFilter
    let onSelect: (TimeFilter) -> Void

    private let filters: [TimeFilter] = [
        .daily,
        .weekly,
        .monthly,
        .yearly,
        .all,
        .custom
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.self) { filter in
                    filterButton(filter)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func filterButton(
        _ filter: TimeFilter
    ) -> some View {
        let selected = currentFilter == filter

        return Button {
            onSelect(filter)
        } label: {
            HStack(spacing: 6) {
                if filter == .custom {
                    Image(systemName: "calendar")
                }

                Text(filter.title)
            }
            .font(.system(size: 14, weight: .semibold))
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .foregroundStyle(
                selected
                    ? HistoryColors.onPrimary
                    : HistoryColors.onSurfaceVariant
            )
            .background(
                selected
                    ? HistoryColors.primary
                    : HistoryColors.surface,
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(
                        selected
                            ? Color.clear
                            : HistoryColors.outline,
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

// MARK: - Summary

private struct HistorySummaryCard: View {
    let summary: FinancialSummary

    private var changeColor: Color {
        guard let percent = summary.changePercent else {
            return HistoryColors.onSurfaceVariant
        }

        if percent > 0 {
            return HistoryColors.error
        }

        if percent < 0 {
            return HistoryColors.primary
        }

        return HistoryColors.onSurfaceVariant
    }

    private var changeIcon: String {
        guard let percent = summary.changePercent else {
            return "info.circle"
        }

        if percent > 0 { return "arrow.up.right" }
        if percent < 0 { return "arrow.down.right" }
        return "equal"
    }

    private var changeText: String {
        guard let previous = summary.previousAmount else {
            return "برای نمایش مقایسه، یک بازهٔ زمانی انتخاب کن."
        }

        guard let percent = summary.changePercent else {
            return previous == 0
                ? "دورهٔ قبل هزینه‌ای ثبت نشده؛ درصد تغییر قابل محاسبه نیست."
                : "درصد تغییر در دسترس نیست."
        }

        if percent == 0 {
            return "بدون تغییر نسبت به دورهٔ قبل"
        }

        let direction = percent > 0 ? "افزایش" : "کاهش"

        return "\(historyChangeLabel(percent))٪ \(direction) نسبت به دورهٔ قبل"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("خلاصهٔ مالی", systemImage: "chart.bar.xaxis")
                .font(.headline)
                .foregroundStyle(HistoryColors.onSurface)

            VStack(alignment: .leading, spacing: 8) {
                Text(summary.currentLabel)
                    .font(.subheadline)
                    .foregroundStyle(
                        HistoryColors.onSurfaceVariant
                    )

                (
                    Text(summary.currentAmount.toMoney())
                        .font(.system(size: 30, weight: .bold))
                    +
                    Text(" تومان")
                        .font(.subheadline)
                )
                .foregroundStyle(HistoryColors.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            }

            Label(changeText, systemImage: changeIcon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(changeColor)
                .fixedSize(horizontal: false, vertical: true)

            if let previous = summary.previousAmount {
                Divider()

                HistoryComparisonBar(
                    title: summary.currentLabel,
                    amount: summary.currentAmount,
                    maximum: max(summary.currentAmount, previous),
                    color: HistoryColors.primary
                )

                HistoryComparisonBar(
                    title: summary.previousLabel ?? "دورهٔ قبل",
                    amount: previous,
                    maximum: max(summary.currentAmount, previous),
                    color: HistoryColors.secondary
                )
            }

            if let category = summary.topCategory {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "chart.pie.fill")
                        .foregroundStyle(HistoryColors.primary)
                        .padding(10)
                        .background(
                            HistoryColors.primaryContainer,
                            in: RoundedRectangle(cornerRadius: 12)
                        )

                    VStack(alignment: .leading, spacing: 6) {
                        Text("پرهزینه‌ترین دسته")
                            .font(.caption)
                            .foregroundStyle(
                                HistoryColors.onSurfaceVariant
                            )

                        Text(category)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(HistoryColors.onSurface)

                        Text(
                            "\(summary.topCategoryAmount.toMoney()) تومان"
                        )
                        .font(.subheadline)
                        .foregroundStyle(HistoryColors.primary)
                    }

                    Spacer(minLength: 0)
                }
            }

            if let note = summary.comparisonNote,
               !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(
                        HistoryColors.onSurfaceVariant
                    )
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .historyCard()
    }
}

private struct HistoryComparisonBar: View {
    let title: String
    let amount: Int64
    let maximum: Int64
    let color: Color

    private var ratio: CGFloat {
        guard maximum > 0 else { return 0 }

        return CGFloat(
            min(1, max(0, Double(amount) / Double(maximum)))
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Text(title)
                    .foregroundStyle(
                        HistoryColors.onSurfaceVariant
                    )

                Spacer(minLength: 0)

                Text("\(amount.toMoney()) تومان")
                    .foregroundStyle(HistoryColors.onSurface)
                    .multilineTextAlignment(.trailing)
            }
            .font(.caption)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(HistoryColors.surfaceVariant)

                    Capsule()
                        .fill(color)
                        .frame(width: geometry.size.width * ratio)
                }
            }
            .frame(height: 9)
            .animation(.easeInOut(duration: 0.3), value: ratio)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Insights

private struct HistoryInsightsCard: View {
    let insights: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("نکته‌های مالی", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(HistoryColors.primary)

            ForEach(insights.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(HistoryColors.primary)

                    Text(insights[index])
                        .font(.subheadline)
                        .foregroundStyle(HistoryColors.onSurface)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }
            }
        }
        .historyCard()
    }
}

// MARK: - Expense card

private struct HistoryExpenseCard: View {
    let expense: Expense
    let onDelete: () -> Void

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(
                    reduceMotion
                        ? nil
                        : .spring(
                            response: 0.35,
                            dampingFraction: 0.85
                        )
                ) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(HistoryColors.primary)
                        .frame(width: 46, height: 46)
                        .background(
                            HistoryColors.primaryContainer,
                            in: RoundedRectangle(cornerRadius: 15)
                        )

                    VStack(alignment: .leading, spacing: 7) {
                        Text(
                            expense.description.isEmpty
                                ? "بدون توضیح"
                                : expense.description
                        )
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(HistoryColors.onSurface)
                        .lineLimit(isExpanded ? nil : 1)
                        .multilineTextAlignment(.leading)

                        Label(
                            expense.createdAt
                                .toPersianDateTime()
                                .toPersianDigits(),
                            systemImage: "clock"
                        )
                        .font(.system(size: 11))
                        .foregroundStyle(
                            HistoryColors.onSurfaceVariant
                        )
                        .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 0)

                    VStack(alignment: .trailing, spacing: 5) {
                        Text(expense.amount.toMoney())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(HistoryColors.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)

                        Text("تومان")
                            .font(.caption2)
                            .foregroundStyle(
                                HistoryColors.onSurfaceVariant
                            )

                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(
                                HistoryColors.onSurfaceVariant
                            )
                            .rotationEffect(
                                .degrees(isExpanded ? 180 : 0)
                            )
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(
                isExpanded
                    ? "بستن جزئیات"
                    : "نمایش گزینهٔ حذف"
            )

            if isExpanded {
                VStack(spacing: 12) {
                    Divider()
                        .padding(.top, 14)

                    HStack {
                        Spacer()

                        Button(action: onDelete) {
                            Label(
                                "حذف هزینه",
                                systemImage: "trash"
                            )
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(HistoryColors.error)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 44)
                            .background(
                                HistoryColors.errorContainer,
                                in: Capsule()
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .transition(.opacity)
            }
        }
        .historyCard()
        .accessibilityAction(named: Text("حذف هزینه")) {
            onDelete()
        }
    }
}

// MARK: - Empty state

private struct HistoryEmptyState: View {
    let isSearching: Bool

    var body: some View {
        VStack(spacing: 18) {
            Image(
                systemName: isSearching
                    ? "magnifyingglass"
                    : "tray"
            )
            .font(.system(size: 42, weight: .medium))
            .foregroundStyle(HistoryColors.primary)
            .frame(width: 104, height: 104)
            .background(
                HistoryColors.primaryContainer,
                in: RoundedRectangle(cornerRadius: 30)
            )

            Text(
                isSearching
                    ? "هزینه‌ای پیدا نشد"
                    : "در این بازه هزینه‌ای ثبت نشده"
            )
            .font(.headline)
            .foregroundStyle(HistoryColors.onSurface)

            Text(
                isSearching
                    ? "عبارت جستجو یا بازهٔ زمانی را تغییر بده."
                    : "بازهٔ دیگری انتخاب کن یا هزینهٔ جدید ثبت کن."
            )
            .font(.subheadline)
            .foregroundStyle(HistoryColors.onSurfaceVariant)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }
}

// MARK: - Custom date range

private struct HistoryCustomRangeSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var startDate: Date
    @State private var endDate: Date

    let onApply: (Int64, Int64) -> Void

    init(
        existingRange: CustomDateRange?,
        onApply: @escaping (Int64, Int64) -> Void
    ) {
        self.onApply = onApply

        let today = HistoryDates.calendar.startOfDay(for: Date())

        let defaultStart = HistoryDates.calendar.date(
            byAdding: .day,
            value: -6,
            to: today
        ) ?? today

        _startDate = State(
            initialValue: existingRange.map {
                Date(
                    timeIntervalSince1970: Double($0.start) / 1_000
                )
            } ?? defaultStart
        )

        _endDate = State(
            initialValue: existingRange.map {
                Date(
                    timeIntervalSince1970:
                        Double($0.endInclusive) / 1_000
                )
            } ?? today
        )
    }

    private var isValid: Bool {
        let calendar = HistoryDates.calendar
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        let today = calendar.startOfDay(for: Date())

        return start <= end && end <= today
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Label(
                        "انتخاب بازهٔ شمسی",
                        systemImage: "calendar"
                    )
                    .font(.title3.bold())
                    .foregroundStyle(HistoryColors.onSurface)

                    Text("روز شروع و پایان، هر دو در گزارش محاسبه می‌شوند.")
                        .font(.subheadline)
                        .foregroundStyle(
                            HistoryColors.onSurfaceVariant
                        )

                    VStack(alignment: .leading, spacing: 12) {
                        Text("از تاریخ")
                            .font(.headline)

                        DatePicker(
                            "از تاریخ",
                            selection: $startDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                    }
                    .historyCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("تا تاریخ")
                            .font(.headline)

                        DatePicker(
                            "تا تاریخ",
                            selection: $endDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                    }
                    .historyCard()

                    if !isValid {
                        Label(
                            "تاریخ پایان باید برابر یا بعد از تاریخ شروع باشد.",
                            systemImage: "exclamationmark.circle"
                        )
                        .font(.subheadline)
                        .foregroundStyle(HistoryColors.error)
                    }
                }
                .padding(20)
            }
            .background(
                HistoryColors.background.ignoresSafeArea()
            )
            .navigationTitle("بازهٔ دلخواه")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("انصراف") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    applyRange()
                } label: {
                    Text("اعمال بازه")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .foregroundStyle(HistoryColors.onPrimary)
                        .background(
                            HistoryColors.primary,
                            in: RoundedRectangle(cornerRadius: 18)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!isValid)
                .opacity(isValid ? 1 : 0.45)
                .padding(16)
                .background(HistoryColors.background)
            }
        }
        .tint(HistoryColors.primary)
        .environment(\.layoutDirection, .rightToLeft)
        .environment(\.locale, Locale(identifier: "fa_IR"))
        .environment(\.calendar, HistoryDates.calendar)
        .environment(\.timeZone, HistoryDates.calendar.timeZone)
    }

    private func applyRange() {
        guard isValid else { return }

        let calendar = HistoryDates.calendar
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        onApply(
            Int64(start.timeIntervalSince1970 * 1_000),
            Int64(end.timeIntervalSince1970 * 1_000)
        )

        dismiss()
    }
}

// MARK: - Shared styling

private extension View {
    func historyCard() -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                HistoryColors.surface,
                in: RoundedRectangle(
                    cornerRadius: 22,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 22,
                    style: .continuous
                )
                .stroke(
                    HistoryColors.outline.opacity(0.55),
                    lineWidth: 1
                )
            }
    }

    func historyListRow() -> some View {
        self
            .listRowInsets(
                EdgeInsets(
                    top: 6,
                    leading: 20,
                    bottom: 6,
                    trailing: 20
                )
            )
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}

private struct HistoryBottomCorners: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(
            UIBezierPath(
                roundedRect: rect,
                byRoundingCorners: [.bottomLeft, .bottomRight],
                cornerRadii: CGSize(
                    width: radius,
                    height: radius
                )
            ).cgPath
        )
    }
}

// MARK: - Formatting

private func historyDateLabel(_ milliseconds: Int64) -> String {
    let formatter = DateFormatter()
    formatter.calendar = HistoryDates.calendar
    formatter.timeZone = HistoryDates.calendar.timeZone
    formatter.locale = Locale(identifier: "fa_IR")
    formatter.dateFormat = "d MMMM yyyy"

    return formatter.string(
        from: Date(
            timeIntervalSince1970: Double(milliseconds) / 1_000
        )
    )
    .toPersianDigits()
}

private func historyChangeLabel(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "fa_IR")
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 1

    return formatter.string(
        from: NSNumber(value: abs(value))
    ) ?? "۰"
}
