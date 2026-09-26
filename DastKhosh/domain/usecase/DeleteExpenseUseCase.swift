//
//  DeleteExpenseUseCase.swift
//  DastKhosh
//
//  Created by homan on 1405.07.02.
//

import Foundation
import Combine

final class DeleteExpenseUseCase {
    private let repository: ExpenseRepository

    init(repository: ExpenseRepository) {
        self.repository = repository
    }

    func execute(expense: Expense) async throws {
        try await repository.deleteExpense(expense)
    }
}
