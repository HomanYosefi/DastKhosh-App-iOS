//
//  GetAllExpensesUseCase.swift
//  DastKhosh
//
//  Created by homan on 1405.07.02.
//

import Foundation
import Combine

final class GetAllExpensesUseCase {
    private let repository: ExpenseRepository

    init(repository: ExpenseRepository) {
        self.repository = repository
    }

    func execute() -> AnyPublisher<[Expense], Never> {
        repository.getAllExpenses()
    }
}



