//
//  ExpenseRepositoryImpl.swift
//  DastKhosh
//
//  Created by homan on 1405.07.02.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class ExpenseRepositoryImpl: ExpenseRepository {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    private let expensesSubject = CurrentValueSubject<[Expense], Never>([])

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = modelContainer.mainContext
        fetchInitialData()
    }

    private func fetchInitialData() {
        Task {
            if let items = try? await getAllExpensesSync() {
                expensesSubject.send(items)
            }
        }
    }

    func getAllExpenses() -> AnyPublisher<[Expense], Never> {
        expensesSubject.eraseToAnyPublisher()
    }

    func insertExpense(_ expense: Expense) async throws {
        let entity = expense.toEntity()
        modelContext.insert(entity)
        try modelContext.save()
        expensesSubject.send(try await getAllExpensesSync())
    }

    func deleteExpense(_ expense: Expense) async throws {
        let targetId = expense.id
        let descriptor = FetchDescriptor<ExpenseEntity>(
            predicate: #Predicate { $0.id == targetId }
        )
        if let entities = try? modelContext.fetch(descriptor), let entity = entities.first {
            modelContext.delete(entity)
            try modelContext.save()
            expensesSubject.send(try await getAllExpensesSync())
        }
    }

    func getAllExpensesSync() async throws -> [Expense] {
        var descriptor = FetchDescriptor<ExpenseEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toDomain() }
    }

    func insertExpenses(_ expenses: [Expense]) async throws {
        for expense in expenses {
            modelContext.insert(expense.toEntity())
        }
        try modelContext.save()
        expensesSubject.send(try await getAllExpensesSync())
    }
}
