//
//  UndoDeleteExpenseUseCase.swift
//  DastKhosh
//
//  Created by homan on 1405.07.04.
//

import Foundation

struct UndoDeleteExpenseUseCase {
    private let insertExpenseUseCase: InsertExpenseUseCase

    init(insertExpenseUseCase: InsertExpenseUseCase) {
        self.insertExpenseUseCase = insertExpenseUseCase
    }

    func execute(expense: Expense) async throws {
        try await insertExpenseUseCase.execute(
            amount: expense.amount,
            description: expense.description
        )
    }
}
