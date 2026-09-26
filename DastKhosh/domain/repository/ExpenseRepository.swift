//
//  ExpenseRepository.swift
//  DastKhosh
//
//  Created by homan on 1405.07.02.
//

import Foundation
import Combine

protocol ExpenseRepository {
    func getAllExpenses() -> AnyPublisher<[Expense], Never>
    func insertExpense(_ expense: Expense) async throws
    func deleteExpense(_ expense: Expense) async throws
    func getAllExpensesSync() async throws -> [Expense]
    func insertExpenses(_ expenses: [Expense]) async throws
}
