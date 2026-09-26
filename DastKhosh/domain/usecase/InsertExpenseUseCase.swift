//
//  InsertExpenseUseCase.swift
//  DastKhosh
//
//  Created by homan on 1405.07.02.
//

import Foundation
import Combine


final class InsertExpenseUseCase {
    private let repository: ExpenseRepository

    init(repository: ExpenseRepository) {
        self.repository = repository
    }

    func execute(amount: Int64, description: String) async throws {
        let expense = Expense(amount: amount, description: description)
        try await repository.insertExpense(expense)
    }
}
