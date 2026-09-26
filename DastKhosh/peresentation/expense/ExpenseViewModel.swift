import Foundation
import Combine

@MainActor
final class ExpenseViewModel: ObservableObject {
    // MARK: - Persistence use cases

    private let insertExpenseUseCase: InsertExpenseUseCase
    private let getAllExpensesUseCase: GetAllExpensesUseCase
    private let deleteExpenseUseCase: DeleteExpenseUseCase
    private let undoDeleteExpenseUseCase: UndoDeleteExpenseUseCase

    // MARK: - Calculation use cases

    private let calculateTotalUseCase: CalculateExpensesTotalUseCase
    private let topDescriptionsUseCase: GetTopExpenseDescriptionsUseCase
    private let buildHistoryUseCase: BuildExpenseHistoryUseCase

    // MARK: - Input use cases

    private let normalizeAmountUseCase: NormalizeExpenseAmountUseCase
    private let addQuickAmountUseCase: AddQuickExpenseAmountUseCase
    private let normalizeDescriptionUseCase:
        NormalizeExpenseDescriptionUseCase
    private let normalizeSearchUseCase:
        NormalizeExpenseSearchQueryUseCase
    private let validateFormUseCase: ValidateExpenseFormUseCase
    private let validateRangeUseCase: ValidateCustomExpenseRangeUseCase
    private let selectTimeFilterUseCase: SelectExpenseTimeFilterUseCase

    // MARK: - Presentation dependencies

    private let historyMapper: ExpenseHistoryStateMapper
    private let nowProvider: () -> Int64

    // MARK: - Internal state

    private var cancellables = Set<AnyCancellable>()
    private var lastDeleted: Expense?
    private var customRange: CustomDateRange?

    // MARK: - Published state

    @Published private(set) var expenses: [Expense] = []
    @Published private(set) var total: Int64 = 0
    @Published private(set) var topDescriptions: [String] = []
    @Published private(set) var timeFilter: TimeFilter = .monthly
    @Published private(set) var searchQuery = ""
    @Published private(set) var historyState = HistoryState()

    @Published var formState = ExpenseFormState()

    let events = PassthroughSubject<ExpenseEvent, Never>()

    // MARK: - Init

    init(
        insertExpenseUseCase: InsertExpenseUseCase,
        getAllExpensesUseCase: GetAllExpensesUseCase,
        deleteExpenseUseCase: DeleteExpenseUseCase,
        undoDeleteExpenseUseCase: UndoDeleteExpenseUseCase? = nil,
        calculateTotalUseCase: CalculateExpensesTotalUseCase = .init(),
        topDescriptionsUseCase: GetTopExpenseDescriptionsUseCase = .init(),
        buildHistoryUseCase: BuildExpenseHistoryUseCase = .init(),
        normalizeAmountUseCase: NormalizeExpenseAmountUseCase = .init(),
        addQuickAmountUseCase: AddQuickExpenseAmountUseCase = .init(),
        normalizeDescriptionUseCase:
            NormalizeExpenseDescriptionUseCase = .init(),
        normalizeSearchUseCase:
            NormalizeExpenseSearchQueryUseCase = .init(),
        validateFormUseCase: ValidateExpenseFormUseCase = .init(),
        validateRangeUseCase: ValidateCustomExpenseRangeUseCase = .init(),
        selectTimeFilterUseCase: SelectExpenseTimeFilterUseCase = .init(),
        historyMapper: ExpenseHistoryStateMapper = .init(),
        nowProvider: @escaping () -> Int64 = {
            HistoryDates.milliseconds(Date())
        },
        observesClock: Bool = true
    ) {
        self.insertExpenseUseCase = insertExpenseUseCase
        self.getAllExpensesUseCase = getAllExpensesUseCase
        self.deleteExpenseUseCase = deleteExpenseUseCase

        self.undoDeleteExpenseUseCase =
            undoDeleteExpenseUseCase ??
            UndoDeleteExpenseUseCase(
                insertExpenseUseCase: insertExpenseUseCase
            )

        self.calculateTotalUseCase = calculateTotalUseCase
        self.topDescriptionsUseCase = topDescriptionsUseCase
        self.buildHistoryUseCase = buildHistoryUseCase

        self.normalizeAmountUseCase = normalizeAmountUseCase
        self.addQuickAmountUseCase = addQuickAmountUseCase
        self.normalizeDescriptionUseCase = normalizeDescriptionUseCase
        self.normalizeSearchUseCase = normalizeSearchUseCase
        self.validateFormUseCase = validateFormUseCase
        self.validateRangeUseCase = validateRangeUseCase
        self.selectTimeFilterUseCase = selectTimeFilterUseCase

        self.historyMapper = historyMapper
        self.nowProvider = nowProvider

        bindExpenses()

        if observesClock {
            bindHistoryClock()
        }

        refreshHistory()
    }

    // MARK: - Observation

    private func bindExpenses() {
        getAllExpensesUseCase.execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self else { return }

                self.expenses = items

                self.total = self.calculateTotalUseCase.execute(items)

                self.topDescriptions =
                    self.topDescriptionsUseCase.execute(items)

                self.refreshHistory()
            }
            .store(in: &cancellables)
    }

    private func bindHistoryClock() {
        Timer.publish(
            every: 60,
            on: .main,
            in: .common
        )
        .autoconnect()
        .sink { [weak self] _ in
            self?.refreshHistory()
        }
        .store(in: &cancellables)
    }

    // MARK: - Search and filters

    func setTimeFilter(_ filter: TimeFilter) {
        guard let selected = selectTimeFilterUseCase.execute(
            requested: filter,
            customRange: customRange
        ) else {
            return
        }

        timeFilter = selected
        refreshHistory()
    }

    func onSearchQueryChange(_ value: String) {
        searchQuery = normalizeSearchUseCase.execute(value)
        refreshHistory()
    }

    func setCustomRange(
        start: Int64,
        endInclusive: Int64
    ) {
        guard let range = validateRangeUseCase.execute(
            start: start,
            endInclusive: endInclusive,
            now: nowProvider()
        ) else {
            return
        }

        customRange = range
        timeFilter = .custom
        refreshHistory()
    }

    // MARK: - History

    private func refreshHistory() {
        let report = buildHistoryUseCase.execute(
            expenses: expenses,
            filter: timeFilter,
            range: customRange,
            query: searchQuery,
            now: nowProvider()
        )

        historyState = historyMapper.map(
            report: report,
            filter: timeFilter,
            query: searchQuery,
            range: customRange
        )
    }

    // MARK: - Form input

    func onAmountChange(_ raw: String) {
        formState.amount = normalizeAmountUseCase.execute(raw)
        formState.amountError = nil
    }

    func addQuickAmount(_ value: Int64) {
        formState.amount = addQuickAmountUseCase.execute(
            current: formState.amountValue,
            adding: value
        )

        formState.amountError = nil
    }

    func clearAmount() {
        formState.amount = ""
        formState.amountError = nil
    }

    func onDescriptionChange(_ value: String) {
        formState.description =
            normalizeDescriptionUseCase.execute(value)

        formState.descriptionError = nil
    }

    // MARK: - Save

    func save() {
        guard !formState.isSaving else { return }

        let validation = validateFormUseCase.execute(
            amount: formState.amountValue,
            description: formState.description
        )

        formState.amountError = validation.amountError
        formState.descriptionError = validation.descriptionError

        guard validation.isValid else {
            formState.errorTick += 1
            events.send(.message("اطلاعات کامل نیست 🙏"))
            return
        }

        // قبل از Task برای جلوگیری از ثبت تکراری.
        formState.isSaving = true

        Task {
            do {
                try await insertExpenseUseCase.execute(
                    amount: validation.amount,
                    description: validation.description
                )

                let nextTick = formState.savedTick + 1
                formState = ExpenseFormState(savedTick: nextTick)

                events.send(
                    .message("هزینه با موفقیت ثبت شد ✅")
                )
            } catch is CancellationError {
                formState.isSaving = false
            } catch {
                formState.errorTick += 1
                formState.isSaving = false

                events.send(
                    .message("ثبت هزینه انجام نشد؛ دوباره تلاش کنید.")
                )
            }
        }
    }

    // MARK: - Delete

    func deleteExpense(_ expense: Expense) {
        Task {
            do {
                try await deleteExpenseUseCase.execute(
                    expense: expense
                )

                lastDeleted = expense

                events.send(
                    .deleted("«\(expense.description)» حذف شد")
                )
            } catch is CancellationError {
                return
            } catch {
                events.send(
                    .message("حذف هزینه انجام نشد؛ دوباره تلاش کنید.")
                )
            }
        }
    }

    // MARK: - Undo

    func undoDelete() {
        guard let item = lastDeleted else { return }

        lastDeleted = nil

        Task {
            do {
                try await undoDeleteExpenseUseCase.execute(
                    expense: item
                )
            } catch is CancellationError {
                if lastDeleted == nil {
                    lastDeleted = item
                }
            } catch {
                if lastDeleted == nil {
                    lastDeleted = item
                }

                events.send(
                    .message("بازگردانی هزینه انجام نشد؛ دوباره تلاش کنید.")
                )
            }
        }
    }

    // MARK: - UI acknowledgements

    func consumeSavedTick() {
        formState.savedTick = 0
    }

    func consumeErrorTick() {
        formState.errorTick = 0
    }
}
